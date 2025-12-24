BEGIN;

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.patients;
CREATE TABLE mart.patients AS
SELECT
  "Id" AS patient_id,
  NULLIF("BIRTHDATE",'')::date AS birth_date,
  NULLIF("DEATHDATE",'')::date AS death_date,
  "GENDER" AS gender,
  "RACE" AS race,
  "ETHNICITY" AS ethnicity,
  "CITY" AS city,
  "STATE" AS state,
  "ZIP" AS zip,
  NULLIF("LAT",'')::numeric AS lat,
  NULLIF("LON",'')::numeric AS lon,
  NULLIF("HEALTHCARE_EXPENSES",'')::numeric AS healthcare_expenses,
  NULLIF("HEALTHCARE_COVERAGE",'')::numeric AS healthcare_coverage
FROM raw.patients;

CREATE INDEX IF NOT EXISTS idx_mart_patients_patient_id ON mart.patients(patient_id);

DROP TABLE IF EXISTS mart.encounters;
CREATE TABLE mart.encounters AS
SELECT
  "Id" AS encounter_id,
  "PATIENT" AS patient_id,
  NULLIF("START",'')::timestamptz AS start_ts,
  NULLIF("STOP",'')::timestamptz AS stop_ts,
  "ENCOUNTERCLASS" AS encounter_class,
  "CODE" AS encounter_code,
  "DESCRIPTION" AS encounter_description,
  "REASONCODE" AS reason_code,
  "REASONDESCRIPTION" AS reason_description,
  NULLIF("BASE_ENCOUNTER_COST",'')::numeric AS base_encounter_cost,
  NULLIF("TOTAL_CLAIM_COST",'')::numeric AS total_claim_cost,
  NULLIF("PAYER_COVERAGE",'')::numeric AS payer_coverage
FROM raw.encounters;

CREATE INDEX IF NOT EXISTS idx_mart_encounters_patient_id ON mart.encounters(patient_id);
CREATE INDEX IF NOT EXISTS idx_mart_encounters_start_ts ON mart.encounters(start_ts);

DROP TABLE IF EXISTS mart.conditions;
CREATE TABLE mart.conditions AS
SELECT
  "PATIENT" AS patient_id,
  "ENCOUNTER" AS encounter_id,
  NULLIF("START",'')::timestamptz AS start_ts,
  NULLIF("STOP",'')::timestamptz AS stop_ts,
  "SYSTEM" AS system,
  "CODE" AS code,
  "DESCRIPTION" AS condition_description
FROM raw.conditions;

CREATE INDEX IF NOT EXISTS idx_mart_conditions_patient_id ON mart.conditions(patient_id);
CREATE INDEX IF NOT EXISTS idx_mart_conditions_encounter_id ON mart.conditions(encounter_id);

DROP TABLE IF EXISTS mart.medications;
CREATE TABLE mart.medications AS
SELECT
  "PATIENT" AS patient_id,
  "ENCOUNTER" AS encounter_id,
  NULLIF("START",'')::timestamptz AS start_ts,
  NULLIF("STOP",'')::timestamptz AS stop_ts,
  "CODE" AS medication_code,
  "DESCRIPTION" AS medication_description,
  NULLIF("BASE_COST",'')::numeric AS base_cost,
  NULLIF("PAYER_COVERAGE",'')::numeric AS payer_coverage,
  NULLIF("TOTALCOST",'')::numeric AS total_cost,
  NULLIF("DISPENSES",'')::numeric AS dispenses
FROM raw.medications;

CREATE INDEX IF NOT EXISTS idx_mart_meds_patient_id ON mart.medications(patient_id);
CREATE INDEX IF NOT EXISTS idx_mart_meds_encounter_id ON mart.medications(encounter_id);

COMMIT;

SELECT COUNT(*) AS n_patients FROM mart.patients;
SELECT COUNT(*) AS n_encounters FROM mart.encounters;
SELECT COUNT(*) AS n_conditions FROM mart.conditions;
SELECT COUNT(*) AS n_medications FROM mart.medications;

