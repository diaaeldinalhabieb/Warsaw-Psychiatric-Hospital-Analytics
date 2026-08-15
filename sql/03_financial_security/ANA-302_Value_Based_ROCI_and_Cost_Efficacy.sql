-- =============================================================================
-- [MODULE 3.2 / ANA-302]: Value-Based ROCI & Cost-Efficacy of Treatment Regimens
-- OBJECTIVE: Quantify the financial cost-efficacy and Return on Clinical Investment (ROCI) by evaluating billed revenue against treatment modalities, side effect severity, recovery trajectories, and digital/behavioral adherence tiers.
-- =============================================================================

-- SQL ID: SQL-ANA-302-01
-- Investigation ID: ANA-302
-- Grain Level: Clinical Regimen, Recovery Trajectory & Digital Engagement Segment
-- Target Schema: dbo.Financials, dbo.Treatments, dbo.Outcomes, dbo.Longitudinal_Sessions, dbo.Medication_History
-- Join Keys & Duplicate Prevention Logic: Longitudinal_Sessions and Medication_History are pre-aggregated at the atomic Treatment_ID level before joining to Treatments and Financials. This Grain Lock ensures 1:1 relational mappings, completely preventing Cartesian fan-out and artificial inflation of Total_Billed_PLN.
-- Data Quality (DQ) Guardrails: Enforces explicit COALESCE for missing numericals, sanitizes categorical fields and boolean flags, classifies missing behavioral data into 'Low / Passive Engagement', and implements NULLIF() to protect against all divide-by-zero errors in ROCI KPI calculations.

WITH Treatment_Session_Summary AS (
    -- DQ Step 1: Pre-aggregate behavioral and session metrics at Treatment_ID grain to prevent Cartesian fan-out
    SELECT 
        Treatment_ID,
        COUNT(DISTINCT Session_ID) AS Total_Sessions_Count,
        AVG(CAST(COALESCE(App_Usage_Hours, 0.0) AS FLOAT)) AS Avg_App_Usage_Hours,
        CAST(
            (COUNT(DISTINCT CASE WHEN Homework_Completed IN (1, '1') THEN Session_ID END) * 100.0) 
            / NULLIF(COUNT(DISTINCT Session_ID), 0) 
            AS DECIMAL(5,2)
        ) AS Homework_Completion_Rate_Pct,
        CAST(
            (COUNT(DISTINCT CASE WHEN Telehealth_Flag IN (1, '1') THEN Session_ID END) * 100.0) 
            / NULLIF(COUNT(DISTINCT Session_ID), 0) 
            AS DECIMAL(5,2)
        ) AS Telehealth_Session_Ratio_Pct,
        MIN(Interim_Clinical_Score) AS Baseline_Clinical_Score,
        MAX(Interim_Clinical_Score) AS Final_Clinical_Score
    FROM dbo.Longitudinal_Sessions
    WHERE Treatment_ID IS NOT NULL
    GROUP BY Treatment_ID
),
Treatment_Med_Summary AS (
    -- DQ Step 2: Pre-aggregate medication adherence history at Treatment_ID grain
    SELECT 
        Treatment_ID,
        AVG(CAST(COALESCE(Adherence_Rate, 0.0) AS FLOAT)) AS Avg_Med_Adherence_Rate
    FROM dbo.Medication_History
    WHERE Treatment_ID IS NOT NULL
    GROUP BY Treatment_ID
),
Enriched_ROCI_Cohort AS (
    -- DQ Step 3: Join Treatment baseline with financial data, outcomes, and pre-aggregated behavioral/medical CTEs
    SELECT 
        t.Treatment_ID,
        t.Patient_ID,
        COALESCE(NULLIF(LTRIM(RTRIM(t.Therapy_Type)), ''), 'Unrecorded Therapy') AS Clean_Therapy_Type,
        COALESCE(NULLIF(LTRIM(RTRIM(t.Medication)), ''), 'Unrecorded Medication') AS Clean_Medication,
        COALESCE(NULLIF(LTRIM(RTRIM(t.Side_Effect_Severity)), ''), 'Unrecorded Severity') AS Clean_Side_Effects,
        COALESCE(NULLIF(LTRIM(RTRIM(o.Trajectory_Outcome)), ''), 'Unrecorded Outcome') AS Clean_Trajectory,
        COALESCE(f.Total_Billed_PLN, 0.0) AS Clean_Billed_PLN,
        tss.Avg_App_Usage_Hours,
        tss.Homework_Completion_Rate_Pct,
        tms.Avg_Med_Adherence_Rate,
        CASE 
            WHEN tss.Homework_Completion_Rate_Pct >= 80.0 AND tss.Avg_App_Usage_Hours >= 6.0 THEN '1. High Digital & Behavioral Engagement'
            WHEN tss.Homework_Completion_Rate_Pct >= 50.0 OR tss.Avg_App_Usage_Hours >= 3.0 THEN '2. Moderate Engagement'
            ELSE '3. Low / Passive Engagement'
        END AS Engagement_Tier
    FROM dbo.Treatments t
    INNER JOIN dbo.Financials f 
        ON t.Treatment_ID = f.Treatment_ID
    LEFT JOIN dbo.Outcomes o 
        ON t.Treatment_ID = o.Treatment_ID
    LEFT JOIN Treatment_Session_Summary tss 
        ON t.Treatment_ID = tss.Treatment_ID
    LEFT JOIN Treatment_Med_Summary tms 
        ON t.Treatment_ID = tms.Treatment_ID
)
-- Step 4: Multi-Dimensional Aggregation & Financial ROCI KPI Computation
SELECT 
    erc.Clean_Therapy_Type,
    erc.Clean_Medication,
    erc.Clean_Trajectory,
    erc.Engagement_Tier,
    
    COUNT(DISTINCT erc.Treatment_ID) AS Total_Treatments_Count,
    COUNT(DISTINCT erc.Patient_ID) AS Total_Unique_Patients,
    
    CAST(SUM(erc.Clean_Billed_PLN) AS DECIMAL(14,2)) AS Total_Billed_PLN_Sum,
    CAST(AVG(erc.Clean_Billed_PLN) AS DECIMAL(10,2)) AS Avg_Cost_Per_Treatment_PLN,
    
    COUNT(DISTINCT CASE WHEN erc.Clean_Trajectory = 'Full Remission' THEN erc.Treatment_ID END) AS Remission_Count,
    CAST(
        (COUNT(DISTINCT CASE WHEN erc.Clean_Trajectory = 'Full Remission' THEN erc.Treatment_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT erc.Treatment_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Full_Remission_Rate_Pct,
    
    COUNT(DISTINCT CASE WHEN erc.Clean_Trajectory IN ('Full Remission', 'Gradual Improvement') THEN erc.Treatment_ID END) AS Positive_Trajectory_Count,
    CAST(
        (COUNT(DISTINCT CASE WHEN erc.Clean_Trajectory IN ('Full Remission', 'Gradual Improvement') THEN erc.Treatment_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT erc.Treatment_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Positive_Response_Rate_Pct,
    
    CAST(
        SUM(erc.Clean_Billed_PLN) 
        / NULLIF(COUNT(DISTINCT CASE WHEN erc.Clean_Trajectory = 'Full Remission' THEN erc.Treatment_ID END), 0) 
        AS DECIMAL(12,2)
    ) AS Cost_Per_Full_Remission_PLN,
    
    CAST(AVG(erc.Avg_App_Usage_Hours) AS DECIMAL(5,2)) AS Avg_App_Usage_Hours,
    CAST(AVG(erc.Homework_Completion_Rate_Pct) AS DECIMAL(5,2)) AS Avg_Homework_Completion_Pct,
    CAST(AVG(erc.Avg_Med_Adherence_Rate * 100.0) AS DECIMAL(5,2)) AS Avg_Med_Adherence_Pct

FROM Enriched_ROCI_Cohort erc
GROUP BY 
    erc.Clean_Therapy_Type,
    erc.Clean_Medication,
    erc.Clean_Trajectory,
    erc.Engagement_Tier
ORDER BY 
    Total_Billed_PLN_Sum DESC,
    Full_Remission_Rate_Pct DESC;