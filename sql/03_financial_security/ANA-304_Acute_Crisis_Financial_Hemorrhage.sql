-- =============================================================================
-- [MODULE 3.4 / ANA-304]: Acute Crisis Financial Hemorrhage & Payer SLA Optimization
-- OBJECTIVE: Quantify the acute financial volume (Total_Billed_PLN) and claim rejection exposure consumed by emergency room events and psychiatric hospitalizations stemming from scheduling latencies and non-attendance, segmented across primary diagnoses and payer groups.
-- =============================================================================

-- SQL ID: SQL-ANA-304-01
-- Investigation ID: ANA-304
-- Grain Level: Payer, Primary Diagnosis, Scheduling Latency & Acute Utilization Segment
-- Target Schema: dbo.Financials, dbo.Crisis_Events, dbo.Treatments, dbo.Appointments, dbo.Comorbidities, dbo.Patients
-- Join Keys & Duplicate Prevention Logic: Crisis_Events, Appointments, and Financials (via Treatments) are pre-aggregated at the atomic Patient_ID grain in separate CTEs before joining to Patients and Comorbidities. This Grain Lock eliminates Cartesian fan-out on billed revenue and event counts.
-- Data Quality (DQ) Guardrails: Enforces explicit type casting for Patient_ID and bit flags, sanitizes categorical fields, handles NULL metrics with COALESCE, and utilizes NULLIF() to prevent divide-by-zero errors in rate calculations.

WITH Patient_Crisis_Summary AS (
    -- DQ Step 1: Pre-aggregate crisis events at Patient_ID grain
    SELECT 
        CAST(Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        COUNT(DISTINCT Event_ID) AS Total_Crisis_Events,
        SUM(CASE WHEN ER_Visit_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Total_ER_Visits,
        SUM(CASE WHEN Hospitalization_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Total_Hospitalizations,
        MAX(CASE WHEN ER_Visit_Flag IN (1, '1') OR Hospitalization_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Has_Acute_Crisis_Flag,
        MAX(COALESCE(NULLIF(LTRIM(RTRIM(Crisis_Type)), ''), 'Unspecified Crisis')) AS Dominant_Crisis_Type
    FROM dbo.Crisis_Events
    WHERE Patient_ID IS NOT NULL
    GROUP BY CAST(Patient_ID AS NVARCHAR(50))
),
Patient_Operational_Summary AS (
    -- DQ Step 2: Pre-aggregate operational scheduling latency and non-attendance at Patient_ID grain
    SELECT 
        CAST(Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        COUNT(DISTINCT Appointment_ID) AS Total_Appointments_Count,
        COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(Status))) = 'NO-SHOW' THEN Appointment_ID END) AS Total_No_Show_Count,
        COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(Status))) = 'CANCELLED' THEN Appointment_ID END) AS Total_Cancelled_Count,
        MAX(COALESCE(Wait_Time_Days, 0)) AS Max_Wait_Time_Days,
        AVG(CAST(COALESCE(Wait_Time_Days, 0) AS FLOAT)) AS Avg_Wait_Time_Days
    FROM dbo.Appointments
    WHERE Patient_ID IS NOT NULL
    GROUP BY CAST(Patient_ID AS NVARCHAR(50))
),
Patient_Financial_Summary AS (
    -- DQ Step 3: Pre-aggregate financial revenue and rejection volume at Patient_ID grain
    SELECT 
        CAST(t.Patient_ID AS NVARCHAR(50)) AS Patient_ID_Clean,
        SUM(COALESCE(f.Total_Billed_PLN, 0.0)) AS Total_Billed_PLN_Sum,
        SUM(CASE WHEN f.Claim_Rejected_Flag IN (1, '1') THEN COALESCE(f.Total_Billed_PLN, 0.0) ELSE 0.0 END) AS Total_Rejected_PLN_Sum,
        SUM(CASE WHEN f.Claim_Rejected_Flag = 0 OR f.Claim_Rejected_Flag IS NULL THEN COALESCE(f.Total_Billed_PLN, 0.0) ELSE 0.0 END) AS Total_Paid_PLN_Sum,
        COUNT(DISTINCT f.Treatment_ID) AS Total_Claims_Count,
        COUNT(DISTINCT CASE WHEN f.Claim_Rejected_Flag IN (1, '1') THEN f.Treatment_ID END) AS Rejected_Claims_Count,
        MAX(COALESCE(NULLIF(LTRIM(RTRIM(f.Insurance_Type)), ''), 'Unrecorded Insurance')) AS Primary_Insurance_Type
    FROM dbo.Treatments t
    INNER JOIN dbo.Financials f 
        ON t.Treatment_ID = f.Treatment_ID
    WHERE t.Patient_ID IS NOT NULL
    GROUP BY CAST(t.Patient_ID AS NVARCHAR(50))
),
Enriched_Crisis_Financial_Cohort AS (
    -- DQ Step 4: Join Patient/Comorbidity baseline with pre-aggregated Crisis, Operational, and Financial CTEs
    SELECT 
        p.Patient_ID,
        COALESCE(NULLIF(LTRIM(RTRIM(c.Primary_Diagnosis)), ''), 'Unrecorded Diagnosis') AS Clean_Diagnosis,
        COALESCE(pfs.Primary_Insurance_Type, 'Unrecorded Insurance') AS Clean_Insurance,
        CASE 
            WHEN COALESCE(pos.Max_Wait_Time_Days, 0) >= 30 THEN '3. Severe Delay (>= 30 days)'
            WHEN COALESCE(pos.Max_Wait_Time_Days, 0) BETWEEN 7 AND 29 THEN '2. Standard (7 - 29 days)'
            ELSE '1. Prompt (< 7 days)'
        END AS Scheduling_Latency_Tier,
        CASE 
            WHEN COALESCE(pos.Total_No_Show_Count, 0) > 0 THEN '1. History of No-Show'
            WHEN COALESCE(pos.Total_Cancelled_Count, 0) > 0 THEN '2. History of Cancellation'
            ELSE '3. Fully Attended'
        END AS Attendance_Risk_Tier,
        CASE 
            WHEN COALESCE(pcs.Total_Hospitalizations, 0) > 0 THEN '1. Inpatient Hospitalization'
            WHEN COALESCE(pcs.Total_ER_Visits, 0) > 0 THEN '2. ER Visit Only'
            ELSE '3. No Acute Crisis'
        END AS Acute_Utilization_Group,
        COALESCE(pcs.Has_Acute_Crisis_Flag, 0) AS Has_Acute_Crisis_Flag,
        COALESCE(pcs.Total_ER_Visits, 0) AS Total_ER_Visits,
        COALESCE(pcs.Total_Hospitalizations, 0) AS Total_Hospitalizations,
        COALESCE(pfs.Total_Billed_PLN_Sum, 0.0) AS Total_Billed_PLN_Sum,
        COALESCE(pfs.Total_Rejected_PLN_Sum, 0.0) AS Total_Rejected_PLN_Sum,
        COALESCE(pfs.Total_Paid_PLN_Sum, 0.0) AS Total_Paid_PLN_Sum,
        COALESCE(pfs.Rejected_Claims_Count, 0) AS Rejected_Claims_Count,
        COALESCE(pfs.Total_Claims_Count, 0) AS Total_Claims_Count,
        COALESCE(pos.Avg_Wait_Time_Days, 0.0) AS Avg_Wait_Time_Days
    FROM dbo.Patients p
    LEFT JOIN dbo.Comorbidities c 
        ON p.Patient_ID = c.Patient_ID
    LEFT JOIN Patient_Crisis_Summary pcs 
        ON CAST(p.Patient_ID AS NVARCHAR(50)) = pcs.Patient_ID_Clean
    LEFT JOIN Patient_Operational_Summary pos 
        ON CAST(p.Patient_ID AS NVARCHAR(50)) = pos.Patient_ID_Clean
    LEFT JOIN Patient_Financial_Summary pfs 
        ON CAST(p.Patient_ID AS NVARCHAR(50)) = pfs.Patient_ID_Clean
)
-- Step 5: Multi-Dimensional Aggregation & Financial KPI Computation
SELECT 
    ecfc.Clean_Insurance,
    ecfc.Clean_Diagnosis,
    ecfc.Scheduling_Latency_Tier,
    ecfc.Acute_Utilization_Group,
    
    COUNT(DISTINCT ecfc.Patient_ID) AS Total_Unique_Patients,
    COUNT(DISTINCT CASE WHEN ecfc.Has_Acute_Crisis_Flag = 1 THEN ecfc.Patient_ID END) AS Patients_With_Acute_Crisis,
    CAST(
        (COUNT(DISTINCT CASE WHEN ecfc.Has_Acute_Crisis_Flag = 1 THEN ecfc.Patient_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT ecfc.Patient_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Acute_Crisis_Rate_Pct,
    
    SUM(ecfc.Total_ER_Visits) AS Total_ER_Visits_Count,
    SUM(ecfc.Total_Hospitalizations) AS Total_Hospitalizations_Count,
    
    CAST(SUM(ecfc.Total_Billed_PLN_Sum) AS DECIMAL(14,2)) AS Total_Billed_PLN_Volume,
    CAST(SUM(ecfc.Total_Rejected_PLN_Sum) AS DECIMAL(14,2)) AS Direct_Rejected_PLN_Volume,
    CAST(SUM(ecfc.Total_Paid_PLN_Sum) AS DECIMAL(14,2)) AS Direct_Paid_PLN_Volume,
    
    CAST(
        (SUM(ecfc.Rejected_Claims_Count) * 100.0) 
        / NULLIF(SUM(ecfc.Total_Claims_Count), 0) 
        AS DECIMAL(5,2)
    ) AS Claim_Rejection_Rate_Pct,
    
    CAST(AVG(ecfc.Total_Billed_PLN_Sum) AS DECIMAL(10,2)) AS Avg_Cost_Per_Patient_PLN,
    CAST(AVG(ecfc.Avg_Wait_Time_Days) AS DECIMAL(10,2)) AS Avg_Wait_Time_Days

FROM Enriched_Crisis_Financial_Cohort ecfc
GROUP BY 
    ecfc.Clean_Insurance,
    ecfc.Clean_Diagnosis,
    ecfc.Scheduling_Latency_Tier,
    ecfc.Acute_Utilization_Group
ORDER BY 
    Total_Billed_PLN_Volume DESC,
    Direct_Rejected_PLN_Volume DESC,
    Acute_Crisis_Rate_Pct DESC;