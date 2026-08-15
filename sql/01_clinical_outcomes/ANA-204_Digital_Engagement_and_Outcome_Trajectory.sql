-- =============================================================================
-- [MODULE 1.4 / ANA-204 - STEP 1]: Data Quality (DQ) Audit Query
-- OBJECTIVE: Audit NULL rates, negative app usage hours, bit-flag anomalies, and outcome categorical values prior to execution.
-- =============================================================================

-- SQL ID: SQL-ANA-204-DQ
-- Investigation ID: ANA-204
-- Grain Level: Table Level Audit Summary
-- Target Schema: dbo.Longitudinal_Sessions, dbo.Outcomes

SELECT 
    'Longitudinal_Sessions' AS Source_Table,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN Treatment_ID IS NULL THEN 1 ELSE 0 END) AS Null_Treatment_IDs,
    SUM(CASE WHEN App_Usage_Hours IS NULL THEN 1 ELSE 0 END) AS Null_App_Usage_Hours,
    SUM(CASE WHEN App_Usage_Hours < 0.0 THEN 1 ELSE 0 END) AS Negative_App_Usage_Hours,
    SUM(CASE WHEN Homework_Completed IS NULL THEN 1 ELSE 0 END) AS Null_Homework_Completed,
    SUM(CASE WHEN Telehealth_Flag IS NULL THEN 1 ELSE 0 END) AS Null_Telehealth_Flags
FROM dbo.Longitudinal_Sessions

UNION ALL

SELECT 
    'Outcomes' AS Source_Table,
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN Treatment_ID IS NULL THEN 1 ELSE 0 END) AS Null_Treatment_IDs,
    0 AS Null_App_Usage_Hours,
    0 AS Negative_App_Usage_Hours,
    SUM(CASE WHEN Trajectory_Outcome IS NULL OR LTRIM(RTRIM(Trajectory_Outcome)) = '' THEN 1 ELSE 0 END) AS Null_Homework_Completed,
    0 AS Null_Telehealth_Flags
FROM dbo.Outcomes;


-- =============================================================================
-- [MODULE 1.4 / ANA-204 - STEP 2]: Digital Engagement & Homework Adherence vs. Outcome Trajectory Analysis
-- OBJECTIVE: Quantify how digital app engagement and homework adherence tiers impact final recovery outcomes with built-in DQ guardrails.
-- =============================================================================

-- SQL ID: SQL-ANA-204-01
-- Investigation ID: ANA-204
-- Grain Level: Engagement Adherence Tier and Trajectory Outcome Classification
-- Target Schema: dbo.Patients, dbo.Treatments, dbo.Longitudinal_Sessions, dbo.Outcomes
-- Join Keys & Duplicate Prevention Logic: Longitudinal_Sessions is pre-aggregated at Treatment_ID level in Session_Engagement_CTE to eliminate 1:N fan-out before joining with Treatments and Outcomes (joined via Treatment_ID PK-FK).
-- Data Quality (DQ) Guardrails: Handles NULLs using COALESCE, cleans bit flags, filters negative App_Usage_Hours (< 0), and standardizes Trajectory_Outcome strings.

WITH DQ_Filtered_Sessions AS (
    -- DQ Check 1: Standardize bit flags, treat negative app usage hours as zero, and coalesce missing metrics
    SELECT 
        ls.Session_ID,
        ls.Treatment_ID,
        CASE WHEN ls.Telehealth_Flag IN (0, 1) THEN CAST(ls.Telehealth_Flag AS INT) ELSE 0 END AS Clean_Telehealth_Flag,
        CASE WHEN ls.Homework_Completed IN (0, 1) THEN CAST(ls.Homework_Completed AS INT) ELSE 0 END AS Clean_Homework_Completed,
        CASE WHEN ls.App_Usage_Hours < 0 THEN 0.0 ELSE COALESCE(ls.App_Usage_Hours, 0.0) END AS Clean_App_Usage_Hours
    FROM dbo.Longitudinal_Sessions ls
    WHERE ls.Treatment_ID IS NOT NULL
      AND ls.Session_ID IS NOT NULL
),
Session_Engagement_CTE AS (
    -- Pre-Aggregation: Summarize session metrics per Treatment_ID
    SELECT 
        fs.Treatment_ID,
        COUNT(DISTINCT fs.Session_ID) AS Total_Sessions,
        (SUM(fs.Clean_Homework_Completed) * 100.0) / NULLIF(COUNT(DISTINCT fs.Session_ID), 0) AS Homework_Completion_Rate_Pct,
        AVG(fs.Clean_App_Usage_Hours) AS Avg_App_Usage_Hours,
        (SUM(fs.Clean_Telehealth_Flag) * 100.0) / NULLIF(COUNT(DISTINCT fs.Session_ID), 0) AS Telehealth_Session_Ratio_Pct
    FROM DQ_Filtered_Sessions fs
    GROUP BY fs.Treatment_ID
),
Engagement_Tiers_CTE AS (
    -- Cohort Classification: Stratify treatments into adherence tiers
    SELECT 
        se.Treatment_ID,
        se.Total_Sessions,
        se.Homework_Completion_Rate_Pct,
        se.Avg_App_Usage_Hours,
        se.Telehealth_Session_Ratio_Pct,
        CASE 
            WHEN se.Homework_Completion_Rate_Pct >= 80.0 AND se.Avg_App_Usage_Hours >= 2.0 
                THEN '1. High Digital & Behavioral Adherence'
            WHEN (se.Homework_Completion_Rate_Pct BETWEEN 50.0 AND 79.99) OR (se.Avg_App_Usage_Hours BETWEEN 1.0 AND 1.99) 
                THEN '2. Moderate Adherence'
            ELSE '3. Low Adherence / Non-Compliant'
        END AS Engagement_Adherence_Tier
    FROM Session_Engagement_CTE se
),
DQ_Filtered_Outcomes AS (
    -- DQ Check 2: Standardize outcome categories and trim whitespace
    SELECT 
        o.Treatment_ID,
        COALESCE(NULLIF(LTRIM(RTRIM(o.Trajectory_Outcome)), ''), 'Unrecorded Outcome') AS Clean_Trajectory_Outcome
    FROM dbo.Outcomes o
    WHERE o.Treatment_ID IS NOT NULL
)
SELECT 
    et.Engagement_Adherence_Tier,
    fo.Clean_Trajectory_Outcome AS Trajectory_Outcome,
    COUNT(DISTINCT t.Treatment_ID) AS Total_Treatments_Count,
    CAST(AVG(et.Homework_Completion_Rate_Pct) AS DECIMAL(5,2)) AS Avg_Tier_Homework_Completion_Pct,
    CAST(AVG(et.Avg_App_Usage_Hours) AS DECIMAL(10,2)) AS Avg_Tier_App_Usage_Hours,
    CAST(AVG(et.Telehealth_Session_Ratio_Pct) AS DECIMAL(5,2)) AS Avg_Tier_Telehealth_Ratio_Pct
FROM dbo.Treatments t
INNER JOIN Engagement_Tiers_CTE et 
    ON t.Treatment_ID = et.Treatment_ID
INNER JOIN DQ_Filtered_Outcomes fo 
    ON t.Treatment_ID = fo.Treatment_ID
GROUP BY 
    et.Engagement_Adherence_Tier,
    fo.Clean_Trajectory_Outcome
ORDER BY 
    et.Engagement_Adherence_Tier ASC,
    fo.Clean_Trajectory_Outcome ASC;