-- =============================================================================
-- [MODULE 1.3 / ANA-203 - STEP 1]: Data Quality (DQ) Audit Query
-- OBJECTIVE: Audit NULL rates, out-of-bounds metrics, and data type alignment risks prior to production execution.
-- =============================================================================

-- SQL ID: SQL-ANA-203-DQ
-- Investigation ID: ANA-203
-- Grain Level: Patient Level Audit Summary
-- Target Schema: dbo.Clinical_Notes, dbo.Clinical_Assessments

SELECT 
    'Clinical_Notes' AS Source_Table,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN Patient_ID IS NULL THEN 1 ELSE 0 END) AS Null_Patient_IDs,
    SUM(CASE WHEN Sentiment_Score IS NULL THEN 1 ELSE 0 END) AS Null_Sentiment_Scores,
    SUM(CASE WHEN Sentiment_Score < -1.0 OR Sentiment_Score > 1.0 THEN 1 ELSE 0 END) AS Out_Of_Bounds_Sentiment_Scores,
    SUM(CASE WHEN Self_Harm_Mentions IS NULL THEN 1 ELSE 0 END) AS Null_Self_Harm_Mentions,
    SUM(CASE WHEN Hallucination_Mentions IS NULL THEN 1 ELSE 0 END) AS Null_Hallucination_Mentions
FROM dbo.Clinical_Notes

UNION ALL

SELECT 
    'Clinical_Assessments' AS Source_Table,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN Patient_ID IS NULL THEN 1 ELSE 0 END) AS Null_Patient_IDs,
    SUM(CASE WHEN Assessment_Date IS NULL THEN 1 ELSE 0 END) AS Null_Assessment_Dates,
    SUM(CASE WHEN Suicide_Risk_Score IS NULL THEN 1 ELSE 0 END) AS Out_Of_Bounds_Sentiment_Scores, -- Auditing NULL Suicide Risk Scores
    0 AS Null_Self_Harm_Mentions,
    0 AS Null_Hallucination_Mentions
FROM dbo.Clinical_Assessments;


-- =============================================================================
-- [MODULE 1.3 / ANA-203 - STEP 2]: Clinical Risk Discordance & Sentiment vs. Structured Risk Analysis
-- OBJECTIVE: Detect discordance between qualitative behavioral indicators in notes and structured suicide risk scores with built-in DQ guardrails.
-- =============================================================================

-- SQL ID: SQL-ANA-203-01
-- Investigation ID: ANA-203
-- Grain Level: Sentiment Tier, Self-Harm Mention Status, and Structured Suicide Risk Score Tier
-- Target Schema: dbo.Patients, dbo.Clinical_Notes, dbo.Clinical_Assessments
-- Join Keys & Duplicate Prevention Logic: Both Clinical_Notes and Clinical_Assessments are pre-aggregated in separate CTEs at the Patient_ID level to isolate 1:N fan-out before joining. Patient_ID in Clinical_Notes is explicitly cast to NVARCHAR(50) to prevent implicit conversion errors.
-- Data Quality (DQ) Guardrails: Enforces Sentiment_Score range [-1.0 to 1.0], excludes NULLs, handles bit-flag conversions, and isolates the latest structured assessment using window functions.

WITH DQ_Filtered_Notes AS (
    -- DQ Check 1: Enforce valid physical bounds for Sentiment_Score [-1.00 to 1.00], handle NULLs, and explicitly cast Patient_ID (int) to NVARCHAR(50)
    SELECT 
        cn.Note_ID,
        CAST(cn.Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        cn.Sentiment_Score,
        CASE WHEN cn.Self_Harm_Mentions IN (0, 1) THEN CAST(cn.Self_Harm_Mentions AS INT) ELSE 0 END AS Clean_Self_Harm_Mentions,
        CASE WHEN cn.Hallucination_Mentions IN (0, 1) THEN CAST(cn.Hallucination_Mentions AS INT) ELSE 0 END AS Clean_Hallucination_Mentions
    FROM dbo.Clinical_Notes cn
    WHERE cn.Patient_ID IS NOT NULL
      AND cn.Sentiment_Score IS NOT NULL
      AND cn.Sentiment_Score >= -1.00 
      AND cn.Sentiment_Score <= 1.00
),
Notes_Aggregated_CTE AS (
    -- Pre-Aggregation: Reduces notes to 1:0..1 Patient level and assigns Sentiment Tiers
    SELECT 
        fn.Patient_ID_Clean AS Patient_ID,
        COUNT(DISTINCT fn.Note_ID) AS Total_Notes_Count,
        AVG(fn.Sentiment_Score) AS Avg_Sentiment_Score,
        SUM(fn.Clean_Self_Harm_Mentions) AS Total_Self_Harm_Mentions,
        SUM(fn.Clean_Hallucination_Mentions) AS Total_Hallucination_Mentions,
        CASE 
            WHEN SUM(fn.Clean_Self_Harm_Mentions) > 0 THEN 1 
            ELSE 0 
        END AS Has_Self_Harm_Mentions_Flag,
        CASE 
            WHEN AVG(fn.Sentiment_Score) < -0.20 THEN '1. Negative Sentiment'
            WHEN AVG(fn.Sentiment_Score) BETWEEN -0.20 AND 0.20 THEN '2. Neutral Sentiment'
            ELSE '3. Positive Sentiment'
        END AS Sentiment_Tier
    FROM DQ_Filtered_Notes fn
    GROUP BY fn.Patient_ID_Clean
),
Ranked_Assessments AS (
    -- DQ Check 2: Filter invalid assessment dates and rank to extract the most recent assessment per patient
    SELECT 
        ca.Assessment_ID,
        CAST(ca.Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        ca.Assessment_Date,
        ca.Score,
        COALESCE(LTRIM(RTRIM(ca.Suicide_Risk_Score)), 'Unassessed') AS Suicide_Risk_Score_Clean,
        ROW_NUMBER() OVER (
            PARTITION BY ca.Patient_ID 
            ORDER BY ca.Assessment_Date DESC, ca.Assessment_ID DESC
        ) AS Row_Seq
    FROM dbo.Clinical_Assessments ca
    WHERE ca.Patient_ID IS NOT NULL
      AND ca.Assessment_Date IS NOT NULL
),
Assessments_Aggregated_CTE AS (
    -- Pre-Aggregation: Reduces assessments to 1:0..1 Patient level obtaining the latest risk score
    SELECT 
        ra.Patient_ID_Clean AS Patient_ID,
        COUNT(DISTINCT ra.Assessment_ID) AS Total_Assessments_Count,
        AVG(ra.Score) AS Avg_Assessment_Score,
        MAX(CASE WHEN ra.Row_Seq = 1 THEN ra.Suicide_Risk_Score_Clean END) AS Latest_Suicide_Risk_Score
    FROM Ranked_Assessments ra
    GROUP BY ra.Patient_ID_Clean
)
SELECT 
    na.Sentiment_Tier,
    na.Has_Self_Harm_Mentions_Flag AS Self_Harm_Mentioned,
    COALESCE(aa.Latest_Suicide_Risk_Score, 'No Assessment Recorded') AS Latest_Suicide_Risk_Score,
    COUNT(DISTINCT p.Patient_ID) AS Total_Patients_Count,
    CAST(AVG(na.Avg_Sentiment_Score) AS DECIMAL(5,2)) AS Avg_Tier_Sentiment_Score,
    SUM(na.Total_Self_Harm_Mentions) AS Total_Self_Harm_Mentions_Count,
    SUM(na.Total_Hallucination_Mentions) AS Total_Hallucination_Mentions_Count,
    CAST(AVG(ISNULL(aa.Avg_Assessment_Score, 0)) AS DECIMAL(10,2)) AS Avg_Structured_Assessment_Score
FROM dbo.Patients p
INNER JOIN Notes_Aggregated_CTE na 
    ON p.Patient_ID = na.Patient_ID
LEFT JOIN Assessments_Aggregated_CTE aa 
    ON p.Patient_ID = aa.Patient_ID
GROUP BY 
    na.Sentiment_Tier,
    na.Has_Self_Harm_Mentions_Flag,
    COALESCE(aa.Latest_Suicide_Risk_Score, 'No Assessment Recorded')
ORDER BY 
    na.Sentiment_Tier ASC,
    na.Has_Self_Harm_Mentions_Flag DESC,
    Latest_Suicide_Risk_Score ASC;