-- =====================================================
-- CLINICAL ANALYSIS 1: Medication Cost per Therapeutic Class
-- Business Question: Which therapeutic areas drive highest spend?
-- Clinical Context: Helps prioritize formulary management efforts
-- =====================================================

WITH medication_costs AS (
  SELECT 
    medication_description,
    COUNT(DISTINCT patient_id) AS patient_count,
    SUM(COALESCE(total_cost, 0)) AS total_spend,
    AVG(COALESCE(total_cost, 0)) AS avg_cost_per_prescription
  FROM mart.medications
  GROUP BY medication_description
)
SELECT 
  medication_description,
  patient_count,
  ROUND(total_spend::numeric, 2) AS total_spend_usd,
  ROUND(avg_cost_per_prescription::numeric, 2) AS avg_cost_per_rx,
  ROUND(100.0 * total_spend / SUM(total_spend) OVER (), 2) AS pct_of_total_spend
FROM medication_costs
ORDER BY total_spend DESC
LIMIT 20;

-- INTERPRETATION GUIDE:
-- - Look for medications with high total_spend + high patient_count = population health opportunity
-- - High avg_cost_per_rx medications = candidates for generic substitution or step therapy
-- - Top 10 medications typically represent 40-50% of total drug spend

-- =====================================================
-- CLINICAL ANALYSIS 2: Comorbidity Patterns
-- Business Question: Which condition combinations drive highest costs?
-- Clinical Context: Comorbid patients need integrated care management
-- =====================================================

SELECT
  c1.condition_description AS condition_1,
  c2.condition_description AS condition_2,
  COUNT(DISTINCT c1.patient_id) AS patient_count,
  ROUND(AVG(enc.total_claim_cost)::numeric, 2) AS avg_encounter_cost
FROM mart.conditions c1
JOIN mart.conditions c2
  ON c1.patient_id = c2.patient_id
  AND c1.condition_description < c2.condition_description
LEFT JOIN mart.encounters enc
  ON c1.patient_id = enc.patient_id
WHERE c1.condition_description NOT ILIKE '%employment%'  -- Filter baru
  AND c1.condition_description NOT ILIKE '%medication review%' -- Filter baru
  AND c1.condition_description NOT ILIKE '%finding%' -- Filter baru
  AND c2.condition_description NOT ILIKE '%employment%'  -- Filter baru
  AND c2.condition_description NOT ILIKE '%medication review%' -- Filter baru
  AND c2.condition_description NOT ILIKE '%finding%' -- Filter baru 
GROUP BY c1.condition_description, c2.condition_description
HAVING COUNT(DISTINCT c1.patient_id) >= 10
ORDER BY patient_count DESC
LIMIT 15;

-- INTERPRETATION GUIDE:
-- - Common comorbidity pairs: Diabetes + Hypertension, COPD + Heart Failure
-- - High patient_count pairs = opportunities for disease management programs
-- - High avg_encounter_cost = target for care coordination to reduce acute events
