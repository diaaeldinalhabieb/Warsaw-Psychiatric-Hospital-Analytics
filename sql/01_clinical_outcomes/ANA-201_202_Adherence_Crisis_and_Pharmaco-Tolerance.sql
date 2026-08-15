-- =============================================================================
-- [MODULE 1.1 / ANA-201 - CORRECTED]: Unique Patient-Level Psychopharmacological Adherence vs. Acute Crisis Events
-- OBJECTIVE: Eliminate row-inflation artifacts by anchoring adherence strictly at the unique patient level (AVG Adherence_Rate per Patient_ID) to measure true crisis recurrence.
-- =============================================================================

-- SQL ID: SQL-ANA-201-02
-- Investigation ID: ANA-201
-- Grain Level: Unique Patient-Level Adherence Tier
-- Target Schema: dbo.Patients, dbo.Treatments, dbo.Medication_History, dbo.Crisis_Events
-- Join Keys & Duplicate Prevention Logic: Medication_History is joined with Treatments and aggregated at the Patient_ID level using AVG(Adherence_Rate) to enforce a strict 1:1 patient-to-tier grain lock. Crisis_Events is independently pre-aggregated at the Patient_ID level in Crisis_CTE before left joining, completely preventing 1:N fan-out and Cartesian explosion.

WITH DQ_Filtered_Medication_History AS (
    -- DQ Step 1: Filter valid physical bounds for Adherence_Rate and exclude NULL foreign keys
    SELECT 
        mh.Medication_Record_ID,
        mh.Treatment_ID,
        mh.Adherence_Rate
    FROM dbo.Medication_History mh
    WHERE mh.Adherence_Rate IS NOT NULL
      AND mh.Adherence_Rate >= 0.00 
      AND mh.Adherence_Rate <= 1.00
      AND mh.Treatment_ID IS NOT NULL
),
Patient_Adherence_Agg_CTE AS (
    -- DQ Step 2: Join Treatments and DQ_Filtered_Medication_History, grouping strictly by Patient_ID to compute composite adherence
    SELECT 
        t.Patient_ID,
        AVG(mh.Adherence_Rate) AS Avg_Patient_Adherence
    FROM dbo.Treatments t
    INNER JOIN DQ_Filtered_Medication_History mh 
        ON t.Treatment_ID = mh.Treatment_ID
    WHERE t.Patient_ID IS NOT NULL
    GROUP BY t.Patient_ID
),
Patient_Tier_Classification_CTE AS (
    -- DQ Step 3: Mutually Exclusive Patient Tier Classification (1:1 Patient to Tier mapping)
    SELECT 
        pa.Patient_ID,
        pa.Avg_Patient_Adherence,
        CASE 
            WHEN pa.Avg_Patient_Adherence < 0.50 THEN '1. Low Adherence (< 50%)'
            WHEN pa.Avg_Patient_Adherence BETWEEN 0.50 AND 0.7999 THEN '2. Moderate Adherence (50% - 79%)'
            WHEN pa.Avg_Patient_Adherence >= 0.80 THEN '3. High Adherence (>= 80%)'
        END AS Adherence_Tier
    FROM Patient_Adherence_Agg_CTE pa
),
Crisis_CTE AS (
    -- DQ Step 4: Pre-aggregate Crisis_Events per Patient_ID to isolate 1:N fan-out
    SELECT 
        ce.Patient_ID,
        COUNT(DISTINCT ce.Event_ID) AS Total_Crisis_Events,
        SUM(CASE WHEN ce.ER_Visit_Flag IN (0, 1) THEN CAST(ce.ER_Visit_Flag AS INT) ELSE 0 END) AS Total_ER_Visits,
        SUM(CASE WHEN ce.Hospitalization_Flag IN (0, 1) THEN CAST(ce.Hospitalization_Flag AS INT) ELSE 0 END) AS Total_Hospitalizations
    FROM dbo.Crisis_Events ce
    WHERE ce.Patient_ID IS NOT NULL
    GROUP BY ce.Patient_ID
)
-- DQ Step 5: Final Join & Aggregation at Adherence Tier level
SELECT 
    pt.Adherence_Tier,
    COUNT(DISTINCT pt.Patient_ID) AS Total_Patients_In_Tier,
    COUNT(DISTINCT CASE WHEN ISNULL(c.Total_Crisis_Events, 0) > 0 THEN pt.Patient_ID END) AS Patients_With_Crisis,
    CAST((COUNT(DISTINCT CASE WHEN ISNULL(c.Total_Crisis_Events, 0) > 0 THEN pt.Patient_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT pt.Patient_ID), 0) AS DECIMAL(5,2)) AS [Tier_Crisis_Rate_%],
    SUM(ISNULL(c.Total_ER_Visits, 0)) AS Total_ER_Visits_Sum,
    SUM(ISNULL(c.Total_Hospitalizations, 0)) AS Total_Hospitalizations_Sum,
    CAST(SUM(ISNULL(c.Total_Crisis_Events, 0)) * 1.0 
        / NULLIF(COUNT(DISTINCT pt.Patient_ID), 0) AS DECIMAL(10,2)) AS Avg_Crisis_Per_Patient
FROM Patient_Tier_Classification_CTE pt
LEFT JOIN Crisis_CTE c 
    ON pt.Patient_ID = c.Patient_ID
GROUP BY pt.Adherence_Tier
ORDER BY pt.Adherence_Tier ASC;


-- =============================================================================
-- [MODULE 1.2 / ANA-202 - ISOLATED]: Impact of Side Effect Severity & Regimen Changes on Session Progress
-- OBJECTIVE: Evaluate how severe side effects and medication changes impact interim clinical score trajectories across treatments.
-- =============================================================================

-- SQL ID: SQL-ANA-202-02
-- Investigation ID: ANA-202
-- Grain Level: Side Effect Severity & Medication Change Flag Level
-- Target Schema: dbo.Treatments, dbo.Longitudinal_Sessions, dbo.Outcomes
-- Join Keys & Duplicate Prevention Logic: Longitudinal_Sessions is pre-aggregated at Treatment_ID level using window functions (FIRST_VALUE, LAST_VALUE) inside Session_Metrics_CTE before joining to Treatments, eliminating 1:N fan-out. Joined with Outcomes on Treatment_ID PK-FK.

WITH DQ_Filtered_Sessions AS (
    -- DQ Step 1a: Sanitize session scores and filter invalid dates/IDs
    SELECT 
        ls.Session_ID,
        ls.Treatment_ID,
        ls.Session_Date,
        ls.Interim_Clinical_Score
    FROM dbo.Longitudinal_Sessions ls
    WHERE ls.Treatment_ID IS NOT NULL
      AND ls.Session_ID IS NOT NULL
      AND ls.Session_Date IS NOT NULL
      AND ls.Interim_Clinical_Score IS NOT NULL
      AND ls.Interim_Clinical_Score >= 0.0
),
DQ_Filtered_Treatments AS (
    -- DQ Step 1b: Standardize string casing/trimming and sanitize Medication_Change_Flag bit values
    SELECT 
        t.Treatment_ID,
        t.Patient_ID,
        LTRIM(RTRIM(t.Side_Effect_Severity)) AS Side_Effect_Severity,
        CASE WHEN t.Medication_Change_Flag IN (0, 1) THEN CAST(t.Medication_Change_Flag AS INT) ELSE 0 END AS Clean_Medication_Change_Flag
    FROM dbo.Treatments t
    WHERE t.Treatment_ID IS NOT NULL
      AND t.Side_Effect_Severity IS NOT NULL
      AND LTRIM(RTRIM(t.Side_Effect_Severity)) <> ''
),
Ranked_Sessions AS (
    -- DQ Step 2: Utilize window functions (FIRST_VALUE, LAST_VALUE) partitioned by Treatment_ID
    SELECT 
        fs.Treatment_ID,
        fs.Session_ID,
        fs.Interim_Clinical_Score,
        FIRST_VALUE(fs.Interim_Clinical_Score) OVER (
            PARTITION BY fs.Treatment_ID 
            ORDER BY fs.Session_Date ASC
        ) AS Initial_Clinical_Score,
        LAST_VALUE(fs.Interim_Clinical_Score) OVER (
            PARTITION BY fs.Treatment_ID 
            ORDER BY fs.Session_Date ASC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS Latest_Clinical_Score
    FROM DQ_Filtered_Sessions fs
),
Session_Metrics_CTE AS (
    -- DQ Step 3: Aggregate session metrics strictly at Treatment_ID level
    SELECT 
        rs.Treatment_ID,
        COUNT(DISTINCT rs.Session_ID) AS Total_Sessions_Count,
        AVG(rs.Interim_Clinical_Score) AS Avg_Interim_Score,
        MAX(rs.Initial_Clinical_Score) AS Initial_Clinical_Score,
        MAX(rs.Latest_Clinical_Score) AS Latest_Clinical_Score,
        (MAX(rs.Latest_Clinical_Score) - MAX(rs.Initial_Clinical_Score)) AS Net_Score_Improvement
    FROM Ranked_Sessions rs
    GROUP BY rs.Treatment_ID
)
-- DQ Step 4: Final Join & Aggregation by Side_Effect_Severity and Medication_Change_Flag
SELECT 
    ft.Side_Effect_Severity,
    ft.Clean_Medication_Change_Flag AS Medication_Change_Flag,
    COUNT(DISTINCT ft.Treatment_ID) AS Total_Treatments_Count,
    CAST(AVG(sm.Net_Score_Improvement) AS DECIMAL(10,2)) AS Average_Net_Improvement,
    CAST(AVG(sm.Avg_Interim_Score) AS DECIMAL(10,2)) AS Average_Overall_Score
FROM DQ_Filtered_Treatments ft
INNER JOIN Session_Metrics_CTE sm 
    ON ft.Treatment_ID = sm.Treatment_ID
LEFT JOIN dbo.Outcomes o 
    ON ft.Treatment_ID = o.Treatment_ID
GROUP BY 
    ft.Side_Effect_Severity,
    ft.Clean_Medication_Change_Flag
ORDER BY 
    ft.Side_Effect_Severity ASC,
    ft.Clean_Medication_Change_Flag DESC;