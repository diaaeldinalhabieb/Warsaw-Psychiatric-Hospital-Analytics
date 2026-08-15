-- =============================================================================
-- [MODULE 2.3 / ANA-207 - PIVOTED]: Operational Scheduling Latency & Capacity Utilization
-- OBJECTIVE: Quantify operational scheduling latency (Referral_Date to Scheduled_Date) across clinical specialties to identify capacity bottlenecks and outlier delays (Wait_Time_Days >= 30 days).
-- =============================================================================

-- SQL ID: SQL-ANA-207-06
-- Investigation ID: ANA-207
-- Grain Level: Specialty & Latency Tier
-- Target Schema: dbo.Appointments, dbo.Providers
-- Join Keys & Duplicate Prevention Logic: dbo.Appointments is LEFT JOINed to dbo.Providers matching on Provider_ID explicitly cast to NVARCHAR(50). Pre-filtering at Appointment_ID grain isolates fan-out risks.
-- Data Quality (DQ) Guardrails: Filters for completed visits, ensures non-null referral/scheduled dates, calculates coalesced wait days, enforces non-negative bounds (Final_Wait_Days >= 0), and securely handles missing specialties.

WITH DQ_Filtered_Appointments AS (
    -- DQ Step 1: Filter completed appointments, ensure valid dates, and compute operational latency
    SELECT 
        a.Appointment_ID,
        a.Patient_ID,
        a.Provider_ID,
        a.Referral_Date,
        a.Scheduled_Date,
        a.Wait_Time_Days,
        DATEDIFF(DAY, a.Referral_Date, a.Scheduled_Date) AS Calculated_Latency_Days,
        COALESCE(a.Wait_Time_Days, DATEDIFF(DAY, a.Referral_Date, a.Scheduled_Date)) AS Final_Wait_Days
    FROM dbo.Appointments a
    WHERE a.Appointment_ID IS NOT NULL
      AND UPPER(LTRIM(RTRIM(a.Status))) LIKE '%COMPLET%'
      AND a.Referral_Date IS NOT NULL 
      AND a.Scheduled_Date IS NOT NULL
      AND COALESCE(a.Wait_Time_Days, DATEDIFF(DAY, a.Referral_Date, a.Scheduled_Date)) >= 0
),
Enriched_Latency_Cohort AS (
    -- DQ Step 2: LEFT JOIN with Providers, standardize specialty, flag outliers, and assign latency tiers
    SELECT 
        fa.Appointment_ID,
        fa.Patient_ID,
        fa.Provider_ID,
        fa.Final_Wait_Days,
        p.Weekly_Caseload,
        COALESCE(NULLIF(LTRIM(RTRIM(p.Specialty)), ''), 'Unrecorded Specialty') AS Specialty,
        CASE 
            WHEN fa.Final_Wait_Days >= 30 THEN 1 
            ELSE 0 
        END AS Outlier_Delay_Flag,
        CASE 
            WHEN fa.Final_Wait_Days < 7 THEN '1. Prompt (< 7 days)'
            WHEN fa.Final_Wait_Days BETWEEN 7 AND 29 THEN '2. Standard (7 - 29 days)'
            WHEN fa.Final_Wait_Days >= 30 THEN '3. Severe Delay (>= 30 days)'
        END AS Latency_Tier
    FROM DQ_Filtered_Appointments fa
    LEFT JOIN dbo.Providers p 
        ON CAST(fa.Provider_ID AS NVARCHAR(50)) = CAST(p.Provider_ID AS NVARCHAR(50))
)
-- Step 3: Multi-Dimensional Aggregation & KPI Computation
SELECT 
    elc.Specialty,
    elc.Latency_Tier,
    COUNT(DISTINCT elc.Appointment_ID) AS Total_Completed_Visits,
    COUNT(DISTINCT elc.Patient_ID) AS Total_Unique_Patients,
    COUNT(DISTINCT elc.Provider_ID) AS Total_Clinicians_Count,
    CAST(AVG(CAST(elc.Final_Wait_Days AS FLOAT)) AS DECIMAL(10,2)) AS Avg_Wait_Time_Days,
    CAST(AVG(CAST(elc.Weekly_Caseload AS FLOAT)) AS DECIMAL(10,2)) AS Avg_Provider_Caseload,
    COUNT(DISTINCT CASE WHEN elc.Outlier_Delay_Flag = 1 THEN elc.Appointment_ID END) AS Outlier_Visits_Count,
    CAST(
        (COUNT(DISTINCT CASE WHEN elc.Outlier_Delay_Flag = 1 THEN elc.Appointment_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT elc.Appointment_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Outlier_Delay_Rate_Pct
FROM Enriched_Latency_Cohort elc
GROUP BY 
    elc.Specialty,
    elc.Latency_Tier
ORDER BY 
    Avg_Wait_Time_Days DESC,
    Outlier_Delay_Rate_Pct DESC;