-- =============================================================================
-- [MODULE 2.4 / ANA-208]: Integrated Operational & Financial Leakage Synthesis
-- OBJECTIVE: Measure direct financial leakage (rejected claims) and indirect capacity financial loss (unrealized revenue from No-Shows and Cancellations) across payer types, prior authorization requirements, provider specialties, and geographic distance buckets.
-- =============================================================================

-- SQL ID: SQL-ANA-208-01
-- Investigation ID: ANA-208
-- Grain Level: Integrated Payer & Operational Segment (Insurance Group, Specialty Group, Distance Bucket, Wait Time Bucket, Prior Auth Requirement)
-- Target Schema: dbo.Appointments, dbo.Financials, dbo.Insurance_Workflow, dbo.Treatments, dbo.Patients, dbo.Providers
-- Join Keys & Duplicate Prevention Logic: Financials and Insurance_Workflow are pre-aggregated at the Patient_ID level (via dbo.Treatments) inside Financial_Treatment_CTE to prevent Cartesian row multiplication (fan-out) of Total_Billed_PLN when joined to 1:N Appointments.
-- Data Quality (DQ) Guardrails: Enforces explicit COALESCE and TRY_CAST for financial metrics, sanitizes bit flags, handles NULL geographic and clinical attributes with explicit 'Unrecorded' buckets, and implements robust case-insensitive status matching.

WITH Financial_Treatment_CTE AS (
    -- DQ Step 1: Pre-aggregate financial and authorization metrics to the Patient level to strictly maintain Grain Lock and prevent billing fan-out
    SELECT 
        t.Patient_ID,
        AVG(COALESCE(f.Total_Billed_PLN, 0.0)) AS Patient_Avg_Billed_PLN,
        MAX(TRY_CAST(f.Authorization_Delay_Days AS FLOAT)) AS Patient_Max_Auth_Delay,
        MAX(CASE WHEN f.Claim_Rejected_Flag IN (1, '1') THEN 1 ELSE 0 END) AS Patient_Has_Rejection,
        MAX(CASE WHEN iw.Prior_Authorization_Required IN (1, '1') THEN 1 ELSE 0 END) AS Patient_Has_Prior_Auth,
        MAX(COALESCE(NULLIF(LTRIM(RTRIM(f.Insurance_Type)), ''), 'Unrecorded Insurance')) AS Primary_Insurance_Type
    FROM dbo.Financials f
    LEFT JOIN dbo.Insurance_Workflow iw 
        ON f.Treatment_ID = iw.Treatment_ID
    INNER JOIN dbo.Treatments t 
        ON f.Treatment_ID = t.Treatment_ID
    WHERE t.Patient_ID IS NOT NULL
    GROUP BY t.Patient_ID
),
Enriched_Operational_Appointments AS (
    -- DQ Step 2: Enrich appointments with geographic, operational, and pre-aggregated financial data
    SELECT 
        a.Appointment_ID,
        a.Patient_ID,
        a.Status,
        a.Wait_Time_Days,
        p.Distance_to_Clinic_km,
        COALESCE(ft.Patient_Has_Prior_Auth, 0) AS Patient_Has_Prior_Auth,
        COALESCE(NULLIF(LTRIM(RTRIM(pr.Specialty)), ''), 'Unrecorded Specialty') AS Specialty_Group,
        COALESCE(ft.Primary_Insurance_Type, 'Unrecorded Insurance') AS Insurance_Group,
        ft.Patient_Avg_Billed_PLN,
        ft.Patient_Has_Rejection,
        ft.Patient_Max_Auth_Delay,
        CASE 
            WHEN p.Distance_to_Clinic_km IS NULL THEN '4. Unrecorded Distance'
            WHEN p.Distance_to_Clinic_km < 5.0 THEN '1. Local (< 5.0 km)'
            WHEN p.Distance_to_Clinic_km BETWEEN 5.0 AND 14.9999 THEN '2. Regional (5.0 - 14.9 km)'
            WHEN p.Distance_to_Clinic_km >= 15.0 THEN '3. Remote (>= 15.0 km)'
        END AS Distance_Bucket,
        CASE 
            WHEN a.Wait_Time_Days IS NULL THEN '4. Unrecorded Wait Time'
            WHEN a.Wait_Time_Days < 7 THEN '1. Prompt (< 7 days)'
            WHEN a.Wait_Time_Days BETWEEN 7 AND 29 THEN '2. Standard (7 - 29 days)'
            WHEN a.Wait_Time_Days >= 30 THEN '3. Severe Delay (>= 30 days)'
        END AS Wait_Time_Bucket
    FROM dbo.Appointments a
    INNER JOIN dbo.Patients p 
        ON a.Patient_ID = p.Patient_ID
    LEFT JOIN dbo.Providers pr 
        ON CAST(a.Provider_ID AS NVARCHAR(50)) = CAST(pr.Provider_ID AS NVARCHAR(50))
    LEFT JOIN Financial_Treatment_CTE ft 
        ON a.Patient_ID = ft.Patient_ID
    WHERE a.Appointment_ID IS NOT NULL
)
-- Step 3: Multi-Dimensional Financial & Operational Synthesis Aggregation
SELECT 
    eoa.Insurance_Group,
    eoa.Specialty_Group,
    eoa.Distance_Bucket,
    eoa.Wait_Time_Bucket,
    eoa.Patient_Has_Prior_Auth,
    COUNT(DISTINCT eoa.Appointment_ID) AS Total_Appointments,
    COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(eoa.Status))) LIKE '%COMPLET%' THEN eoa.Appointment_ID END) AS Completed_Visits,
    COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(eoa.Status))) = 'NO-SHOW' THEN eoa.Appointment_ID END) AS No_Show_Visits,
    COUNT(DISTINCT CASE WHEN UPPER(LTRIM(RTRIM(eoa.Status))) = 'CANCELLED' THEN eoa.Appointment_ID END) AS Cancelled_Visits,
    COUNT(DISTINCT eoa.Patient_ID) AS Total_Unique_Patients,
    
    CAST(SUM(COALESCE(eoa.Patient_Avg_Billed_PLN, 0.0)) AS DECIMAL(12,2)) AS Total_Billed_PLN_Sum,
    
    CAST(SUM(CASE WHEN eoa.Patient_Has_Rejection = 1 THEN COALESCE(eoa.Patient_Avg_Billed_PLN, 0.0) ELSE 0.0 END) AS DECIMAL(12,2)) AS Direct_Rejected_Billed_PLN,
    
    CAST(SUM(CASE WHEN UPPER(LTRIM(RTRIM(eoa.Status))) IN ('NO-SHOW', 'CANCELLED') THEN COALESCE(eoa.Patient_Avg_Billed_PLN, 0.0) ELSE 0.0 END) AS DECIMAL(12,2)) AS Indirect_Lost_Capacity_PLN,
    
    CAST(SUM(CASE WHEN eoa.Patient_Has_Rejection = 1 OR UPPER(LTRIM(RTRIM(eoa.Status))) IN ('NO-SHOW', 'CANCELLED') THEN COALESCE(eoa.Patient_Avg_Billed_PLN, 0.0) ELSE 0.0 END) AS DECIMAL(12,2)) AS Total_Combined_Financial_Leakage_PLN,
    
    CAST(AVG(CAST(eoa.Patient_Max_Auth_Delay AS FLOAT)) AS DECIMAL(10,2)) AS Avg_Auth_Delay_Days,
    
    CAST(
        (COUNT(DISTINCT CASE WHEN eoa.Patient_Has_Rejection = 1 THEN eoa.Patient_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT eoa.Patient_ID), 0) 
        AS DECIMAL(5,2)
    ) AS Claim_Rejection_Rate_Pct

FROM Enriched_Operational_Appointments eoa
GROUP BY 
    eoa.Insurance_Group,
    eoa.Specialty_Group,
    eoa.Distance_Bucket,
    eoa.Wait_Time_Bucket,
    eoa.Patient_Has_Prior_Auth
ORDER BY 
    Total_Combined_Financial_Leakage_PLN DESC,
    Direct_Rejected_Billed_PLN DESC;