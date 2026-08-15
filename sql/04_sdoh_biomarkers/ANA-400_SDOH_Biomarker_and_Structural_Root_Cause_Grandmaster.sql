-- =============================================================================
-- [MODULE ANA-400]:  SDOH, BIOMARKER & STRUCTURAL ROOT-CAUSE SYNTHESIS
-- OBJECTIVE: Establish the definitive multidimensional root-cause synthesis intersecting SDOH, Social Support, Biomarkers, and Trauma with operational, clinical, and financial outcomes.
-- =============================================================================

-- SQL ID: SQL-ANA-400-GRANDMASTER
-- Investigation ID: ANA-400
-- Grain Level: Multidimensional SDOH, Biomarker & Social Support Segment
-- Target Schema: dbo.Patients, dbo.SDOH, dbo.Social_Graph, dbo.Biomarkers, dbo.Clinical_Notes, dbo.Treatments, dbo.Longitudinal_Sessions, dbo.Outcomes, dbo.Appointments, dbo.Crisis_Events, dbo.Financials
-- Join Keys & Duplicate Prevention Logic: Strict application of the Grain Lock Rule. All child operational, clinical, and financial tables are pre-aggregated to the 1:1 Patient_ID atomic grain in distinct CTEs before merging into the Master Multidimensional Cohort. This absolutely prevents Cartesian fan-out on Total_Billed_PLN and critical event counts.
-- Data Quality (DQ) Guardrails: Enforces explicit COALESCE(), robust TRY_CAST() for numerical conversions on text fields (Income, Scores), handles bit flags resiliently, and protects all ratio computations with NULLIF() divide-by-zero checks.

WITH CTE_Appt_Summary AS (
    -- DQ Step 1: Pre-aggregate Appointments at Patient_ID grain
    SELECT 
        Patient_ID,
        COUNT(DISTINCT Appointment_ID) AS Total_Appts,
        COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(Status))) = 'NO-SHOW' THEN Appointment_ID END) AS Total_No_Shows,
        COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(Status))) = 'COMPLETED' THEN Appointment_ID END) AS Total_Completed,
        AVG(CAST(COALESCE(Wait_Time_Days, 0) AS FLOAT)) AS Avg_Wait_Days
    FROM dbo.Appointments
    WHERE Patient_ID IS NOT NULL
    GROUP BY Patient_ID
),
CTE_Crisis_Summary AS (
    -- DQ Step 2: Pre-aggregate Crisis Events at Patient_ID grain (with nvarchar cast for safe joining)
    SELECT 
        CAST(Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        COUNT(DISTINCT Event_ID) AS Total_Crises,
        SUM(CASE WHEN ER_Visit_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Total_ER_Visits,
        SUM(CASE WHEN Hospitalization_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Total_Admissions,
        MAX(CASE WHEN ER_Visit_Flag IN (1, '1') OR Hospitalization_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Has_Crisis_Flag
    FROM dbo.Crisis_Events
    WHERE Patient_ID IS NOT NULL
    GROUP BY CAST(Patient_ID AS NVARCHAR(50))
),
CTE_Notes_Summary AS (
    -- DQ Step 3: Pre-aggregate Clinical Notes at Patient_ID grain
    SELECT 
        CAST(Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        AVG(CAST(COALESCE(Sentiment_Score, 0.0) AS FLOAT)) AS Avg_Sentiment,
        SUM(CASE WHEN Self_Harm_Mentions IN (1, '1') THEN 1 ELSE 0 END) AS Total_Self_Harm
    FROM dbo.Clinical_Notes
    WHERE Patient_ID IS NOT NULL
    GROUP BY CAST(Patient_ID AS NVARCHAR(50))
),
CTE_Social_Summary AS (
    -- DQ Step 4: Pre-aggregate Social Graph Support at Patient_ID grain
    SELECT 
        Patient_ID,
        MAX(CASE WHEN Caregiver_Involved_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Has_Caregiver,
        MAX(CASE WHEN Peer_Support_Group_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Has_Peer_Group,
        AVG(TRY_CAST(LTRIM(RTRIM(Family_Support_Score)) AS FLOAT)) AS Avg_Family_Support
    FROM dbo.Social_Graph
    WHERE Patient_ID IS NOT NULL
    GROUP BY Patient_ID
),
CTE_Session_PreAgg AS (
    -- DQ Step 5a: Intermediate aggregation of Sessions to Treatment_ID grain to prevent financial fan-out
    SELECT 
        Treatment_ID,
        AVG(CAST(COALESCE(App_Usage_Hours, 0.0) AS FLOAT)) AS Avg_Weekly_App_Hours,
        COUNT(DISTINCT Session_ID) AS Total_Sessions,
        COUNT(DISTINCT CASE WHEN Homework_Completed IN (1, '1') THEN Session_ID END) AS Completed_Homeworks
    FROM dbo.Longitudinal_Sessions
    WHERE Treatment_ID IS NOT NULL
    GROUP BY Treatment_ID
),
CTE_Treatment_Summary AS (
    -- DQ Step 5b: Pre-aggregate Treatments, Outcomes, Financials, and Sessions at Patient_ID grain
    SELECT 
        t.Patient_ID,
        SUM(COALESCE(f.Total_Billed_PLN, 0.0)) AS Total_Billed_PLN,
        SUM(CASE WHEN f.Claim_Rejected_Flag IN (1, '1') THEN COALESCE(f.Total_Billed_PLN, 0.0) ELSE 0.0 END) AS Rejected_Billed_PLN,
        MAX(CASE WHEN UPPER(LTRIM(RTRIM(o.Trajectory_Outcome))) = 'FULL REMISSION' THEN 1 ELSE 0 END) AS Has_Full_Remission,
        MAX(CASE WHEN t.Medication_Change_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Has_Med_Change,
        AVG(ls.Avg_Weekly_App_Hours) AS Avg_Weekly_App_Hours,
        CAST(
            (SUM(ls.Completed_Homeworks) * 100.0) / NULLIF(SUM(ls.Total_Sessions), 0) 
            AS DECIMAL(5,2)
        ) AS Homework_Completion_Rate
    FROM dbo.Treatments t
    LEFT JOIN dbo.Outcomes o 
        ON t.Treatment_ID = o.Treatment_ID
    LEFT JOIN dbo.Financials f 
        ON t.Treatment_ID = f.Treatment_ID
    LEFT JOIN CTE_Session_PreAgg ls 
        ON t.Treatment_ID = ls.Treatment_ID
    WHERE t.Patient_ID IS NOT NULL
    GROUP BY t.Patient_ID
),
CTE_Grand_Master_Cohort AS (
    -- DQ Step 6: Master Multidimensional Cohort Synthesis
    SELECT 
        p.Patient_ID,
        
        -- Dimension: Housing
        CASE 
            WHEN sd.Housing_Instability IN (1, '1') THEN '1. Unstable Housing' 
            ELSE '2. Stable Housing' 
        END AS Housing_Status,
        
        -- Dimension: Income
        CASE 
            WHEN TRY_CAST(LTRIM(RTRIM(p.Monthly_Income_PLN)) AS FLOAT) < 3000 THEN '1. Low Income (< 3000 PLN)'
            WHEN TRY_CAST(LTRIM(RTRIM(p.Monthly_Income_PLN)) AS FLOAT) BETWEEN 3000 AND 7000 THEN '2. Middle Income (3000-7000 PLN)'
            ELSE '3. High Income (> 7000 PLN)'
        END AS Income_Tier,
        
        -- Dimension: Social Support Capital
        CASE 
            WHEN COALESCE(soc.Has_Caregiver, 0) = 1 AND COALESCE(soc.Has_Peer_Group, 0) = 1 THEN '1. Comprehensive Support (Caregiver + Peer)'
            WHEN COALESCE(soc.Has_Caregiver, 0) = 1 OR COALESCE(soc.Has_Peer_Group, 0) = 1 THEN '2. Partial Support'
            ELSE '3. Isolated (No Caregiver / No Peer Group)'
        END AS Social_Support_Tier,
        
        -- Dimension: Neuro-Inflammatory Biomarkers
        CASE 
            WHEN b.CRP_Level >= 3.0 AND b.Sleep_Hours_Avg < 5.0 THEN '1. High Neuro-Stress (High CRP + Severe Sleep Loss)'
            WHEN b.CRP_Level >= 3.0 OR b.Sleep_Hours_Avg < 5.0 THEN '2. Moderate Neuro-Stress'
            ELSE '3. Normal Biological Baseline'
        END AS Neuro_Inflammatory_Tier,
        
        -- Dimension: Trauma History
        CASE 
            WHEN sd.Trauma_History_Flag IN (1, '1') THEN '1. Documented Trauma History' 
            ELSE '2. No Trauma History' 
        END AS Trauma_Status,
        
        -- Dimension: Immigration Status
        COALESCE(NULLIF(LTRIM(RTRIM(sd.Immigration_Status)), ''), 'Unrecorded Status') AS Immigration_Segment,
        
        -- Pre-Aggregated Metrics for Final Summation
        COALESCE(app.Total_No_Shows, 0) AS Total_No_Shows,
        COALESCE(app.Total_Appts, 0) AS Total_Appts,
        COALESCE(trm.Has_Full_Remission, 0) AS Has_Full_Remission,
        COALESCE(crs.Total_Crises, 0) AS Total_Crises,
        COALESCE(crs.Has_Crisis_Flag, 0) AS Has_Crisis_Flag,
        COALESCE(trm.Total_Billed_PLN, 0.0) AS Total_Billed_PLN,
        COALESCE(trm.Rejected_Billed_PLN, 0.0) AS Rejected_Billed_PLN,
        b.CRP_Level,
        b.Sleep_Hours_Avg,
        trm.Avg_Weekly_App_Hours,
        nts.Avg_Sentiment
        
    FROM dbo.Patients p
    INNER JOIN dbo.SDOH sd 
        ON p.Patient_ID = sd.Patient_ID
    LEFT JOIN dbo.Biomarkers b 
        ON p.Patient_ID = b.Patient_ID
    LEFT JOIN CTE_Social_Summary soc 
        ON p.Patient_ID = soc.Patient_ID
    LEFT JOIN CTE_Appt_Summary app 
        ON p.Patient_ID = app.Patient_ID
    LEFT JOIN CTE_Crisis_Summary crs 
        ON CAST(p.Patient_ID AS NVARCHAR(50)) = crs.Patient_ID_Clean
    LEFT JOIN CTE_Notes_Summary nts 
        ON CAST(p.Patient_ID AS NVARCHAR(50)) = nts.Patient_ID_Clean
    LEFT JOIN CTE_Treatment_Summary trm 
        ON p.Patient_ID = trm.Patient_ID
)
-- Step 7: Master Aggregation & Metric Computation
SELECT 
    Housing_Status,
    Income_Tier,
    Social_Support_Tier,
    Neuro_Inflammatory_Tier,
    Trauma_Status,
    Immigration_Segment,
    
    -- Population & Operational Metrics
    COUNT(DISTINCT Patient_ID) AS Total_Patient_Volume,
    SUM(Total_No_Shows) AS Total_No_Show_Volume,
    CAST(
        (SUM(Total_No_Shows) * 100.0) / NULLIF(SUM(Total_Appts), 0) 
        AS DECIMAL(5,2)
    ) AS No_Show_Rate_Pct,
    
    -- Clinical Outcome Metrics
    COUNT(DISTINCT CASE WHEN Has_Full_Remission = 1 THEN Patient_ID END) AS Full_Remission_Patients,
    CAST(
        (COUNT(DISTINCT CASE WHEN Has_Full_Remission = 1 THEN Patient_ID END) * 100.0) / NULLIF(COUNT(DISTINCT Patient_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Full_Remission_Rate_Pct,
    
    -- Acute Decompensation Metrics
    SUM(Total_Crises) AS Total_Crises_Count,
    CAST(
        (COUNT(DISTINCT CASE WHEN Has_Crisis_Flag = 1 THEN Patient_ID END) * 100.0) / NULLIF(COUNT(DISTINCT Patient_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Crisis_Decompensation_Rate_Pct,
    
    -- Financial Leakage Metrics
    CAST(SUM(Total_Billed_PLN) AS DECIMAL(14,2)) AS Total_Billed_PLN_Sum,
    CAST(SUM(Rejected_Billed_PLN) AS DECIMAL(14,2)) AS Direct_Rejected_PLN_Sum,
    CAST(
        (SUM(Rejected_Billed_PLN) * 100.0) / NULLIF(SUM(Total_Billed_PLN), 0) 
        AS DECIMAL(5,2)
    ) AS Financial_Denial_Rate_Pct,
    
    -- Biological & Behavioral Baselines
    CAST(AVG(CAST(COALESCE(CRP_Level, 0.0) AS FLOAT)) AS DECIMAL(6,2)) AS Avg_CRP_Level,
    CAST(AVG(CAST(COALESCE(Sleep_Hours_Avg, 0.0) AS FLOAT)) AS DECIMAL(4,2)) AS Avg_Sleep_Hours,
    CAST(AVG(CAST(COALESCE(Avg_Weekly_App_Hours, 0.0) AS FLOAT)) AS DECIMAL(5,2)) AS Avg_App_Hours_Weekly,
    CAST(AVG(CAST(COALESCE(Avg_Sentiment, 0.0) AS FLOAT)) AS DECIMAL(4,2)) AS Avg_Notes_Sentiment

FROM CTE_Grand_Master_Cohort
GROUP BY 
    Housing_Status,
    Income_Tier,
    Social_Support_Tier,
    Neuro_Inflammatory_Tier,
    Trauma_Status,
    Immigration_Segment
ORDER BY 
    Total_Patient_Volume DESC,
    Crisis_Decompensation_Rate_Pct DESC,
    Direct_Rejected_PLN_Sum DESC;