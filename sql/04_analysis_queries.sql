SELECT
  (SELECT COUNT(*) FROM raw.patients)    AS raw_patients,
  (SELECT COUNT(*) FROM raw.encounters)  AS raw_encounters,
  (SELECT COUNT(*) FROM raw.conditions)  AS raw_conditions,
  (SELECT COUNT(*) FROM raw.medications) AS raw_medications;

SELECT
  (SELECT COUNT(*) FROM mart.patients)    AS mart_patients,
  (SELECT COUNT(*) FROM mart.encounters)  AS mart_encounters,
  (SELECT COUNT(*) FROM mart.conditions)  AS mart_conditions,
  (SELECT COUNT(*) FROM mart.medications) AS mart_medications;

SELECT encounter_class, COUNT(*) AS n_encounters
FROM mart.encounters
GROUP BY 1
ORDER BY n_encounters DESC;

SELECT
  condition_description,
  COUNT(*) AS n_records,
  CASE
    -- Kategori 1: Respiratory & ENT
    WHEN condition_description ILIKE '%pharyngitis%'
      OR condition_description ILIKE '%bronchitis%'
      OR condition_description ILIKE '%sinusitis%'
      OR condition_description ILIKE '%otitis%'
      OR condition_description ILIKE '%streptococcal%'
    THEN 'Respiratory & ENT'

    -- Kategori 2: Dental & Oral Health
    WHEN condition_description ILIKE '%gingivitis%'
      OR condition_description ILIKE '%gingival%'
      OR condition_description ILIKE '%dental%'
      OR condition_description ILIKE '%tooth%'
    THEN 'Dental & Oral Health'

    -- Kategori 3: Cardiovascular
    WHEN condition_description ILIKE '%hypertension%'
      OR condition_description ILIKE '%ischemic heart%'
    THEN 'Cardiovascular'

    -- Kategori 4: Trauma & Toxicology
    WHEN condition_description ILIKE '%fracture%'
      OR condition_description ILIKE '%overdose%'
    THEN 'Trauma & Toxicology'

    -- Kategori 5: Hematology
    WHEN condition_description ILIKE '%anemia%'
    THEN 'Hematology'

    ELSE 'Other'
  END AS clinical_category
FROM mart.conditions
WHERE condition_description NOT ILIKE '%employment%'
  AND condition_description NOT ILIKE '%medication review%'
  AND condition_description NOT ILIKE '%finding%'
  AND condition_description NOT ILIKE '%pregnancy%'
GROUP BY 1, 3
ORDER BY n_records DESC
LIMIT 15;

SELECT
  medication_description,
  SUM(COALESCE(total_cost,0)) AS total_cost_sum
FROM mart.medications
GROUP BY 1
ORDER BY total_cost_sum DESC
LIMIT 15;

SELECT
  encounter_class,
  COUNT(*) AS n_encounters,
  SUM(COALESCE(total_claim_cost,0)) AS total_claim_cost_sum,
  SUM(COALESCE(payer_coverage,0))   AS payer_coverage_sum
FROM mart.encounters
GROUP BY 1
ORDER BY total_claim_cost_sum DESC;

SELECT
  ROUND(
    100.0 * SUM(COALESCE(payer_coverage,0))
    / NULLIF(SUM(COALESCE(total_claim_cost,0)),0)
  , 2) AS payer_coverage_pct
FROM mart.encounters;

SELECT
  p.patient_id,
  COUNT(e.encounter_id) AS total_encounters,
  SUM(e.total_claim_cost) AS total_cost
FROM mart.patients p
JOIN mart.encounters e ON p.patient_id = e.patient_id
GROUP BY p.patient_id
ORDER BY total_encounters DESC
LIMIT 20;

SELECT
  e.encounter_class,
  m.medication_description,
  SUM(COALESCE(m.total_cost,0)) AS total_cost_sum
FROM mart.medications m
JOIN mart.encounters e
  ON m.encounter_id = e.encounter_id
GROUP BY 1,2
ORDER BY total_cost_sum DESC
LIMIT 20;