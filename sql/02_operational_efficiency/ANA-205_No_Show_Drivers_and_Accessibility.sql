-- =============================================================================
-- [MODULE 2.1 / ANA-205 - CORRECTED]: No-Show Drivers, Accessibility Friction & Capacity Loss Analysis
-- =============================================================================

-- SQL ID: SQL-ANA-205-02
-- Investigation ID: ANA-205
-- Grain Level: Multi-dimensional Operational Segment (District, Employment Status, Distance Bucket, Wait Time Bucket, Income Tier)
-- Target Schema: dbo.Appointments, dbo.Patients
-- Join Keys & Duplicate Prevention Logic: dbo.Appointments is LEFT JOINed to dbo.Patients on Patient_ID PK-FK to preserve all appointment records. Pre-aggregating at Appointment_ID grain ensures no fan-out inflation.
-- Data Quality (DQ) Guardrails: Uses TRY_CAST on distance, transport time, and wait time columns to safely absorb NVARCHAR schema mismatches and malformed text entries during AVG() calculations.

WITH DQ_Filtered_Appointments AS (
    -- DQ Step 1: Filter null anchors, sanitize Status string, and cast Wait_Time_Days safely
    SELECT 
        a.Appointment_ID,
        a.Patient_ID,
        a.Provider_ID,
        a.Scheduled_Date,
        a.Checkin_Timestamp,
        LTRIM(RTRIM(a.Status)) AS Clean_Status,
        TRY_CAST(a.Wait_Time_Days AS INT) AS Wait_Time_Days_Clean
    FROM dbo.Appointments a
    WHERE a.Appointment_ID IS NOT NULL
      AND a.Scheduled_Date IS NOT NULL
      AND TRY_CAST(a.Wait_Time_Days AS INT) >= 0
),
Enriched_Patient_Appointments AS (
    -- DQ Step 2: LEFT JOIN with Patients (lossless), safe numeric casting, and categorical bucketing
    SELECT 
        fa.Appointment_ID,
        fa.Patient_ID,
        fa.Clean_Status,
        fa.Wait_Time_Days_Clean,
        TRY_CAST(p.Distance_to_Clinic_km AS FLOAT) AS Distance_Clean,
        TRY_CAST(p.Transport_Time_mins AS FLOAT) AS Transport_Time_Clean,
        COALESCE(NULLIF(LTRIM(RTRIM(p.District)), ''), 'Unrecorded District') AS District,
        COALESCE(NULLIF(LTRIM(RTRIM(p.Employment_Status)), ''), 'Unrecorded') AS Employment_Status,
        CASE 
            WHEN fa.Wait_Time_Days_Clean < 3 THEN '1. Immediate (< 3 days)'
            WHEN fa.Wait_Time_Days_Clean BETWEEN 3 AND 13 THEN '2. Standard (3 - 13 days)'
            WHEN fa.Wait_Time_Days_Clean >= 14 THEN '3. Delayed (>= 14 days)'
            ELSE '4. Unrecorded Wait Time'
        END AS Wait_Time_Bucket,
        CASE 
            WHEN TRY_CAST(p.Distance_to_Clinic_km AS FLOAT) IS NULL THEN '4. Unrecorded Distance'
            WHEN TRY_CAST(p.Distance_to_Clinic_km AS FLOAT) < 5.0 THEN '1. Local (< 5.0 km)'
            WHEN TRY_CAST(p.Distance_to_Clinic_km AS FLOAT) BETWEEN 5.0 AND 14.9999 THEN '2. Regional (5.0 - 14.9 km)'
            WHEN TRY_CAST(p.Distance_to_Clinic_km AS FLOAT) >= 15.0 THEN '3. Remote (>= 15.0 km)'
        END AS Distance_Bucket,
        CASE 
            WHEN TRY_CAST(p.Monthly_Income_PLN AS FLOAT) IS NULL THEN '4. Unrecorded'
            WHEN TRY_CAST(p.Monthly_Income_PLN AS FLOAT) < 3000 THEN '1. Low (< 3000 PLN)'
            WHEN TRY_CAST(p.Monthly_Income_PLN AS FLOAT) BETWEEN 3000 AND 7000 THEN '2. Middle (3000 - 7000 PLN)'
            WHEN TRY_CAST(p.Monthly_Income_PLN AS FLOAT) > 7000 THEN '3. High (> 7000 PLN)'
        END AS Income_Tier
    FROM DQ_Filtered_Appointments fa
    LEFT JOIN dbo.Patients p 
        ON fa.Patient_ID = p.Patient_ID
)
-- Step 3: Multi-dimensional Aggregation & Operational Metric Computation
SELECT 
    epa.District,
    epa.Employment_Status,
    epa.Distance_Bucket,
    epa.Wait_Time_Bucket,
    epa.Income_Tier,
    COUNT(DISTINCT epa.Appointment_ID) AS Total_Appointments_Count,
    COUNT(DISTINCT epa.Patient_ID) AS Total_Unique_Patients,
    COUNT(DISTINCT CASE WHEN epa.Clean_Status = 'No-Show' THEN epa.Appointment_ID END) AS No_Show_Count,
    COUNT(DISTINCT CASE WHEN epa.Clean_Status = 'Completed' THEN epa.Appointment_ID END) AS Completed_Count,
    COUNT(DISTINCT CASE WHEN epa.Clean_Status = 'Cancelled' THEN epa.Appointment_ID END) AS Cancelled_Count,
    CAST(
        (COUNT(DISTINCT CASE WHEN epa.Clean_Status = 'No-Show' THEN epa.Appointment_ID END) * 100.0) 
        / NULLIF(COUNT(DISTINCT epa.Appointment_ID), 0) 
        AS DECIMAL(5,2)
    ) AS No_Show_Rate_Pct,
    CAST(AVG(CAST(epa.Wait_Time_Days_Clean AS FLOAT)) AS DECIMAL(10,2)) AS Avg_Wait_Time_Days,
    CAST(AVG(epa.Distance_Clean) AS DECIMAL(10,2)) AS Avg_Distance_km,
    CAST(AVG(epa.Transport_Time_Clean) AS DECIMAL(10,2)) AS Avg_Transport_Mins
FROM Enriched_Patient_Appointments epa
GROUP BY 
    epa.District,
    epa.Employment_Status,
    epa.Distance_Bucket,
    epa.Wait_Time_Bucket,
    epa.Income_Tier
ORDER BY 
    epa.District ASC,
    No_Show_Rate_Pct DESC;