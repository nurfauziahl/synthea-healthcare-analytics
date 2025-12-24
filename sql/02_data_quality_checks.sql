-- =====================================================
-- DATA QUALITY ASSESSMENT
-- Run after CSV import to validate data integrity
-- =====================================================

-- Check 1: Null/Missing Critical Fields

SELECT
  'patients' AS table_name,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN "Id" IS NULL THEN 1 ELSE 0 END) AS missing_id,
  SUM(CASE WHEN "BIRTHDATE" IS NULL THEN 1 ELSE 0 END) AS missing_birthdate,
  SUM(CASE WHEN "GENDER" IS NULL THEN 1 ELSE 0 END) AS missing_gender
FROM raw.patients

UNION ALL

SELECT
  'encounters' AS table_name,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN "Id" IS NULL THEN 1 ELSE 0 END) AS missing_id,
  SUM(CASE WHEN "PATIENT" IS NULL THEN 1 ELSE 0 END) AS missing_patient,
  SUM(CASE WHEN "ENCOUNTERCLASS" IS NULL THEN 1 ELSE 0 END) AS missing_encounterclass
FROM raw.encounters;

-- Expected result: zero orphan records in synthetic dataset

-- Check 2: Referential Integrity
SELECT 'Orphan encounters (no patient match)' AS issue,
       COUNT(*) AS issue_count
FROM raw.encounters e
LEFT JOIN raw.patients p ON e."PATIENT" = p."Id"
WHERE p."Id" IS NULL

UNION ALL

SELECT 'Orphan medications (no patient match)' AS issue,
       COUNT(*) AS issue_count
FROM raw.medications m
LEFT JOIN raw.patients p
  ON m."PATIENT" = p."Id"
WHERE p."Id" IS NULL;

-- Check 3A: Logical Consistency (Dates)
SELECT 'Future birthdates' AS issue,
       COUNT(*) AS issue_count
FROM raw.patients
WHERE "BIRTHDATE"::date > CURRENT_DATE;

-- Check 3B: Negative medication costs (analytics layer)
SELECT 'Negative medication costs' AS issue,
       COUNT(*) AS issue_count
FROM mart.medications
WHERE total_cost < 0;

-- Data Quality Report Summary
SELECT 
  ROUND(100.0 * COUNT(*) FILTER (WHERE "DEATHDATE" IS NOT NULL) / COUNT(*), 2) AS deceased_pct,
  ROUND(AVG(EXTRACT(YEAR FROM AGE(COALESCE("DEATHDATE"::date, CURRENT_DATE), "BIRTHDATE"::date)))::numeric, 1) AS avg_age_years,
  MIN("BIRTHDATE"::date) AS oldest_birthdate,
  MAX("BIRTHDATE"::date) AS youngest_birthdate
FROM raw.patients;