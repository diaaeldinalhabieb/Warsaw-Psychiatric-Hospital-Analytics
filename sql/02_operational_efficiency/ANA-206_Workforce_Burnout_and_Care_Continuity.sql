-- =============================================================================
-- [MODULE 2.2 / ANA-206]: Workforce Burnout, Sick Leave & Care Continuity Analysis
-- OBJECTIVE: Quantify the observed association between clinician workload pressure, burnout metrics, sick leave days, and provider reassignment rates.
-- =============================================================================

-- SQL ID: SQL-ANA-206-01
-- Investigation ID: ANA-206
-- Grain Level: Clinician Cohort Segment (Specialty, Caseload Tier, Burnout Tier, Experience Tier)
-- Target Schema: dbo.Providers, dbo.Provider_Assignment_History
-- Join Keys & Duplicate Prevention Logic: Provider_Assignment_History is pre-aggregated at Provider_ID level in Provider_Continuity_Metrics prior to joining to enforce a strict 1:0..1 grain relationship. dbo.Providers is LEFT JOINed to prevent workforce dropouts for clinicians with no recorded reassignment history.
-- Data Quality (DQ) Guardrails: Enforces non-negative bounds across all numeric metrics using TRY_CAST to prevent runtime data type failures (e.g., NVARCHAR schema mismatches on AVG operators). Standardizes text fields and isolates unrecorded attributes in explicit buckets.

WITH DQ_Filtered_Providers AS (
    -- DQ Step 1: Filter null clinician IDs, sanitize numeric bounds using TRY_CAST, and build categorical tiers
    SELECT 
        p.Provider_ID,
        COALESCE(NULLIF(LTRIM(RTRIM(p.Specialty)), ''), 'Unrecorded Specialty') AS Specialty,
        TRY_CAST(p.Years_of_Experience AS INT) AS Experience_Clean,
        TRY_CAST(p.Weekly_Caseload AS FLOAT) AS Caseload_Clean,
        TRY_CAST(p.Sick_Leave_Days AS FLOAT) AS Sick_Leave_Clean,
        TRY_CAST(p.Burnout_Index AS FLOAT) AS Burnout_Clean,
        CASE 
            WHEN TRY_CAST(p.Weekly_Caseload AS FLOAT) < 20 THEN '1. Low (< 20 cases/wk)'
            WHEN TRY_CAST(p.Weekly_Caseload AS FLOAT) BETWEEN 20 AND 39 THEN '2. Moderate (20 - 39 cases/wk)'
            WHEN TRY_CAST(p.Weekly_Caseload AS FLOAT) >= 40 THEN '3. High (>= 40 cases/wk)'
            ELSE '4. Unrecorded Caseload'
        END AS Caseload_Tier,
        CASE 
            WHEN TRY_CAST(p.Burnout_Index AS FLOAT) < 4.0 THEN '1. Low (< 4.0)'
            WHEN TRY_CAST(p.Burnout_Index AS FLOAT) BETWEEN 4.0 AND 6.9 THEN '2. Moderate (4.0 - 6.9)'
            WHEN TRY_CAST(p.Burnout_Index AS FLOAT) >= 7.0 THEN '3. High (>= 7.0)'
            ELSE '4. Unrecorded Burnout'
        END AS Burnout_Tier,
        CASE 
            WHEN TRY_CAST(p.Years_of_Experience AS INT) < 5 THEN '1. Junior (< 5 yrs)'
            WHEN TRY_CAST(p.Years_of_Experience AS INT) BETWEEN 5 AND 12 THEN '2. Mid-Career (5 - 12 yrs)'
            WHEN TRY_CAST(p.Years_of_Experience AS INT) > 12 THEN '3. Senior (> 12 yrs)'
            ELSE '4. Unrecorded Experience'
        END AS Experience_Tier
    FROM dbo.Providers p
    WHERE p.Provider_ID IS NOT NULL
      AND (TRY_CAST(p.Burnout_Index AS FLOAT) IS NULL OR TRY_CAST(p.Burnout_Index AS FLOAT) >= 0)
      AND (TRY_CAST(p.Weekly_Caseload AS FLOAT) IS NULL OR TRY_CAST(p.Weekly_Caseload AS FLOAT) >= 0)
      AND (TRY_CAST(p.Sick_Leave_Days AS FLOAT) IS NULL OR TRY_CAST(p.Sick_Leave_Days AS FLOAT) >= 0)
      AND (TRY_CAST(p.Years_of_Experience AS INT) IS NULL OR TRY_CAST(p.Years_of_Experience AS INT) >= 0)
),
Provider_Continuity_Metrics AS (
    -- DQ Step 2: Pre-aggregate assignment history per Provider_ID to prevent 1:N fan-out
    SELECT 
        pah.Provider_ID,
        COUNT(DISTINCT pah.Assignment_ID) AS Total_Assignments,
        COUNT(DISTINCT CASE WHEN TRY_CAST(pah.Changed_Provider_Flag AS INT) = 1 THEN pah.Assignment_ID END) AS Total_Reassigned,
        CAST(
            (COUNT(DISTINCT CASE WHEN TRY_CAST(pah.Changed_Provider_Flag AS INT) = 1 THEN pah.Assignment_ID END) * 100.0) 
            / NULLIF(COUNT(DISTINCT pah.Assignment_ID), 0) 
            AS DECIMAL(5,2)
        ) AS Reassignment_Rate_Pct
    FROM dbo.Provider_Assignment_History pah
    WHERE pah.Provider_ID IS NOT NULL
      AND pah.Assignment_ID IS NOT NULL
    GROUP BY pah.Provider_ID
)
-- Step 3: Relational Join & Final Aggregation by Clinician Cohort Segment
SELECT 
    p.Specialty,
    p.Caseload_Tier,
    p.Burnout_Tier,
    p.Experience_Tier,
    COUNT(DISTINCT p.Provider_ID) AS Total_Clinicians_Count,
    CAST(AVG(p.Burnout_Clean) AS DECIMAL(10,2)) AS Avg_Burnout_Index,
    CAST(AVG(p.Caseload_Clean) AS DECIMAL(10,2)) AS Avg_Weekly_Caseload,
    CAST(AVG(p.Sick_Leave_Clean) AS DECIMAL(10,2)) AS Avg_Sick_Leave_Days,
    CAST(AVG(ISNULL(pcm.Reassignment_Rate_Pct, 0.0)) AS DECIMAL(5,2)) AS Avg_Reassignment_Rate_Pct
FROM DQ_Filtered_Providers p
LEFT JOIN Provider_Continuity_Metrics pcm 
    ON p.Provider_ID = pcm.Provider_ID
GROUP BY 
    p.Specialty,
    p.Caseload_Tier,
    p.Burnout_Tier,
    p.Experience_Tier
ORDER BY 
    Avg_Burnout_Index DESC,
    Avg_Sick_Leave_Days DESC;