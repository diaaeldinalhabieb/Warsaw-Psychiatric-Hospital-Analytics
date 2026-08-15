-- =============================================================================
-- [MODULE 3.1 / ANA-301]: Prior Authorization Latency & Claim Denial Cascade
-- OBJECTIVE: Quantify direct financial revenue leakage resulting from insurer claim denials across payer classifications, mandatory prior authorization requirements, approval latency tiers, and clinical specialties.
-- =============================================================================

-- SQL ID: SQL-ANA-301-01
-- Investigation ID: ANA-301
-- Grain Level: Payer & Specialty Authorization Latency Segment
-- Target Schema: dbo.Financials, dbo.Insurance_Workflow, dbo.Treatments, dbo.Appointments, dbo.Providers
-- Join Keys & Duplicate Prevention Logic: Appointments and Providers are pre-aggregated at the Patient_ID level in Patient_Operational_Summary to maintain Grain Lock on Treatment_ID and prevent Cartesian fan-out of billed amounts.
-- Data Quality (DQ) Guardrails: Enforces non-negative boundaries on billed amounts, uses TRY_CAST for robust extraction of string-based numeric delays, sanitizes boolean flags to avoid implicit conversion errors, and strictly categorizes NULL attributes.

WITH Patient_Operational_Summary AS (
    -- DQ Step 1: Pre-aggregate Appointment & Provider context at Patient_ID level to prevent Cartesian fan-out
    SELECT 
        a.Patient_ID,
        MAX(COALESCE(NULLIF(LTRIM(RTRIM(pr.Specialty)), ''), 'Unrecorded Specialty')) AS Primary_Specialty,
        AVG(CAST(COALESCE(a.Wait_Time_Days, 0) AS FLOAT)) AS Avg_Patient_Wait_Days
    FROM dbo.Appointments a
    LEFT JOIN dbo.Providers pr 
        ON CAST(a.Provider_ID AS NVARCHAR(50)) = CAST(pr.Provider_ID AS NVARCHAR(50))
    WHERE a.Patient_ID IS NOT NULL
    GROUP BY a.Patient_ID
),
DQ_Filtered_Financial_Workflow AS (
    -- DQ Step 2: Join core financial anchors, sanitize data types, handle formatting anomalies
    SELECT 
        f.Treatment_ID,
        t.Patient_ID,
        COALESCE(f.Total_Billed_PLN, 0.0) AS Clean_Billed_PLN,
        TRY_CAST(LTRIM(RTRIM(f.Authorization_Delay_Days)) AS FLOAT) AS Clean_Auth_Delay_Days,
        CASE WHEN f.Claim_Rejected_Flag IN (1, '1') THEN 1 ELSE 0 END AS Clean_Rejected_Flag,
        CASE WHEN iw.Prior_Authorization_Required IN (1, '1') THEN 1 ELSE 0 END AS Clean_Prior_Auth_Flag,
        COALESCE(NULLIF(LTRIM(RTRIM(f.Insurance_Type)), ''), 'Unrecorded Insurance') AS Clean_Insurance_Type,
        COALESCE(pos.Primary_Specialty, 'Unrecorded Specialty') AS Clean_Specialty
    FROM dbo.Financials f
    LEFT JOIN dbo.Insurance_Workflow iw 
        ON f.Treatment_ID = iw.Treatment_ID
    INNER JOIN dbo.Treatments t 
        ON f.Treatment_ID = t.Treatment_ID
    LEFT JOIN Patient_Operational_Summary pos 
        ON t.Patient_ID = pos.Patient_ID
    WHERE f.Treatment_ID IS NOT NULL
),
Enriched_Authorization_Cohort AS (
    -- DQ Step 3: Categorize authorization status, latency buckets, and enforce non-negative bounds
    SELECT 
        fw.Treatment_ID,
        fw.Patient_ID,
        fw.Clean_Billed_PLN,
        fw.Clean_Auth_Delay_Days,
        fw.Clean_Rejected_Flag,
        fw.Clean_Insurance_Type,
        fw.Clean_Specialty,
        CASE 
            WHEN fw.Clean_Prior_Auth_Flag = 1 THEN '1. Prior Auth Required' 
            ELSE '2. No Auth Required' 
        END AS Auth_Requirement_Group,
        CASE 
            WHEN fw.Clean_Auth_Delay_Days IS NULL THEN '4. No Delay Recorded'
            WHEN fw.Clean_Auth_Delay_Days < 7 THEN '1. Prompt (< 7 days)'
            WHEN fw.Clean_Auth_Delay_Days BETWEEN 7 AND 13.9999 THEN '2. Moderate Delay (7 - 13 days)'
            WHEN fw.Clean_Auth_Delay_Days >= 14 THEN '3. Severe Delay (>= 14 days)'
            ELSE '4. No Delay Recorded'
        END AS Auth_Delay_Bucket
    FROM DQ_Filtered_Financial_Workflow fw
    WHERE fw.Clean_Billed_PLN >= 0
)
-- Step 4: Final Aggregation & Financial KPI Computation
SELECT 
    eac.Clean_Insurance_Type,
    eac.Clean_Specialty,
    eac.Auth_Requirement_Group,
    eac.Auth_Delay_Bucket,
    COUNT(DISTINCT eac.Treatment_ID) AS Total_Claims_Count,
    COUNT(DISTINCT eac.Patient_ID) AS Total_Unique_Patients,
    COUNT(DISTINCT CASE WHEN eac.Clean_Rejected_Flag = 1 THEN eac.Treatment_ID END) AS Rejected_Claims_Count,
    COUNT(DISTINCT CASE WHEN eac.Clean_Rejected_Flag = 0 THEN eac.Treatment_ID END) AS Paid_Claims_Count,
    CAST(
        (COUNT(DISTINCT CASE WHEN eac.Clean_Rejected_Flag = 1 THEN eac.Treatment_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT eac.Treatment_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Claim_Rejection_Rate_Pct,
    CAST(SUM(eac.Clean_Billed_PLN) AS DECIMAL(14,2)) AS Total_Billed_PLN_Sum,
    CAST(
        SUM(CASE WHEN eac.Clean_Rejected_Flag = 1 THEN eac.Clean_Billed_PLN ELSE 0.0 END) 
        AS DECIMAL(14,2)
    ) AS Direct_Rejected_PLN_Sum,
    CAST(
        SUM(CASE WHEN eac.Clean_Rejected_Flag = 0 THEN eac.Clean_Billed_PLN ELSE 0.0 END) 
        AS DECIMAL(14,2)
    ) AS Direct_Paid_PLN_Sum,
    CAST(AVG(eac.Clean_Auth_Delay_Days) AS DECIMAL(10,2)) AS Avg_Auth_Delay_Days,
    CAST(AVG(eac.Clean_Billed_PLN) AS DECIMAL(10,2)) AS Avg_Claim_Amount_PLN
FROM Enriched_Authorization_Cohort eac
GROUP BY 
    eac.Clean_Insurance_Type,
    eac.Clean_Specialty,
    eac.Auth_Requirement_Group,
    eac.Auth_Delay_Bucket
ORDER BY 
    Direct_Rejected_PLN_Sum DESC,
    Claim_Rejection_Rate_Pct DESC;