-- =====================================================
-- PHARMACEUTICAL ANALYSIS 1: Generic vs Brand Opportunity
-- =====================================================
-- Identify potential cost savings from generic substitution
-- (Since Synthea doesn't distinguish, we'll simulate the analysis approach)

SELECT 
  medication_description,
  COUNT(*) AS prescription_count,
  SUM(total_cost) AS current_spend,
  -- Simulate 70% generic substitution rate with 80% cost reduction
  ROUND(SUM(total_cost) * 0.7 * 0.8, 2) AS potential_savings,
  ROUND((SUM(total_cost) * 0.7 * 0.8) / NULLIF(SUM(SUM(total_cost)) OVER (), 0) * 100, 2) AS pct_of_total_savings
FROM mart.medications
WHERE total_cost > 100 -- Focus on high-cost drugs
GROUP BY medication_description
ORDER BY potential_savings DESC
LIMIT 15;

-- BUSINESS CASE:
-- If we achieve 70% generic substitution on high-cost brands:
-- Estimated annual savings: $X across Y patients
-- Implementation: Prescriber education, formulary tiering, prior auth

-- =====================================================
-- PHARMACEUTICAL ANALYSIS 2: Medication Adherence Proxy
-- =====================================================

WITH chronic_meds AS (
SELECT DISTINCT medication_description
  FROM mart.medications
  WHERE medication_description ILIKE ANY (ARRAY [
  '%insulin%',
  '%metformin%',
  '%lisinopril%',
  '%atorvastatin%',
  '%levothy%' 
  ])
  ),
refill_events AS (
  SELECT
    patient_id,
    medication_description,
    start_ts AS fill_date,
    LEAD(start_ts) OVER (
      PARTITION BY patient_id, medication_description
      ORDER BY start_ts
    ) AS next_fill_date
  FROM mart.medications
  WHERE medication_description IN (
    SELECT medication_description FROM chronic_meds)
  AND start_ts IS NOT NULL ),
  
intervals AS (
  SELECT
    patient_id,
    medication_description,
    EXTRACT(DAY FROM (next_fill_date - fill_date)) AS days_between_fills
  FROM refill_events
  WHERE next_fill_date IS NOT NULL
    AND next_fill_date > fill_date)

 SELECT
  medication_description,
  COUNT(*) AS refill_intervals,
  ROUND(AVG(days_between_fills)::numeric, 1) AS avg_days_between_fills,
  ROUND(
     PERCENTILE_CONT(0.5)
     WITHIN GROUP (ORDER BY days_between_fills)::numeric,
     1
   ) AS median_days_between_fills
 
 FROM intervals
 GROUP BY medication_description
 ORDER BY refill_intervals DESC;

-- PHARMACY INTERVENTION:
-- Patients with gaps >30 days are at risk for:
-- - Disease progression
-- - Acute exacerbations
-- - Preventable hospitalizations
-- Solution: Medication synchronization program, automated refill reminders

-- =====================================================
-- PHARMACEUTICAL ANALYSIS 3: Polypharmacy & Interaction Risk Screening
-- =====================================================
-- Identify patients on potentially interacting medications

WITH patient_med_count AS (
  SELECT 
    patient_id,
    COUNT(DISTINCT medication_description) AS concurrent_meds,
    STRING_AGG(DISTINCT medication_description, '; ') AS medication_list
  FROM mart.medications
  -- PERBAIKAN: Ganti medication_stop_date menjadi stop_ts
  WHERE stop_ts IS NULL OR stop_ts > CURRENT_DATE
  GROUP BY patient_id
)
SELECT 
  patient_id,
  concurrent_meds,
  medication_list
FROM patient_med_count
WHERE concurrent_meds >= 5 -- Polypharmacy threshold
ORDER BY concurrent_meds DESC
LIMIT 20;

-- CLINICAL PHARMACIST ROLE:
-- Patients on 5+ medications need comprehensive medication review
-- Risk areas: Drug interactions, therapeutic duplications, inappropriate for age
-- ROI: Prevent adverse drug events (ADEs) which cost $30B annually in US