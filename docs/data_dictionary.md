# Data Dictionary  
*Synthea Healthcare Analytics Portfolio*

---

## Purpose

This data dictionary describes the **analytics-ready tables** created in the `mart` schema.  
It provides definitions, data types, and clinical relevance for key variables used in downstream analyses.

The goal of this document is to ensure:
- Transparency
- Reproducibility
- Shared understanding between technical and clinical stakeholders

---

## Schema Overview

- **raw schema**  
  Contains staging tables that closely mirror Synthea CSV outputs.  
  These tables are not intended for direct analysis.

- **mart schema**  
  Contains curated, analytics-ready tables derived from the raw layer.  
  All analyses and insights are generated from this schema.

---

## mart.patient_summary

**Description:**  
Patient-level summary table used for demographic profiling, utilization analysis, and cost aggregation.

**Grain:**  
One row per patient.

| Column Name | Data Type | Description | Analytical / Clinical Relevance |
|------------|----------|-------------|---------------------------------|
| patient_id | TEXT | Unique patient identifier | Primary key for patient-level analysis |
| gender | TEXT | Patient gender | Demographic stratification |
| birth_date | DATE | Date of birth | Age calculation |
| age | INTEGER | Patient age at analysis | Risk and utilization stratification |
| age_group | TEXT | Age bucket (e.g., 18–44, 45–64, ≥65) | Population segmentation |
| total_encounters | INTEGER | Total number of encounters | Utilization intensity |
| total_conditions | INTEGER | Number of documented conditions | Clinical complexity proxy |
| total_medications | INTEGER | Number of medication orders | Polypharmacy indicator |
| total_cost | NUMERIC | Total aggregated medical + pharmacy cost | High-cost patient identification |

---

## mart.encounter_summary

**Description:**  
Encounter-level aggregation capturing visit characteristics and utilization patterns.

**Grain:**  
One row per encounter.

| Column Name | Data Type | Description | Analytical / Clinical Relevance |
|------------|----------|-------------|---------------------------------|
| encounter_id | TEXT | Unique encounter identifier | Primary key |
| patient_id | TEXT | Linked patient identifier | Patient-level joins |
| encounter_date | DATE | Encounter start date | Temporal analysis |
| encounter_class | TEXT | Encounter type (e.g., inpatient, outpatient, emergency) | Care setting analysis |
| encounter_cost | NUMERIC | Total cost attributed to encounter | Cost per visit |
| medication_count | INTEGER | Number of medications prescribed | Treatment intensity |

---

## mart.medications

**Description:**  
Medication-level table used for pharmacy cost analysis and utilization patterns.

**Grain:**  
One row per medication order per patient encounter.

| Column Name | Data Type | Description | Analytical / Clinical Relevance |
|------------|----------|-------------|---------------------------------|
| medication_id | TEXT | Unique medication order identifier | Primary key |
| patient_id | TEXT | Linked patient identifier | Patient-level analysis |
| encounter_id | TEXT | Linked encounter identifier | Encounter context |
| medication_description | TEXT | Medication name/description | Drug-level aggregation |
| start_date | DATE | Medication start date | Temporal trends |
| stop_date | DATE | Medication stop date | Duration estimation |
| medication_cost | NUMERIC | Cost attributed to medication | Pharmacy spend analysis |

---

## mart.conditions

**Description:**  
Condition-level table capturing diagnosed clinical conditions.

**Grain:**  
One row per condition per patient.

| Column Name | Data Type | Description | Analytical / Clinical Relevance |
|------------|----------|-------------|---------------------------------|
| condition_id | TEXT | Unique condition identifier | Primary key |
| patient_id | TEXT | Linked patient identifier | Patient-level joins |
| condition_description | TEXT | Clinical condition name | Disease pattern analysis |
| condition_category | TEXT | Derived clinical category | Comorbidity grouping |
| onset_date | DATE | Condition onset date | Disease timeline |
| encounter_id | TEXT | Related encounter | Clinical context |

---

## Derived Variables and Business Logic

### Age Grouping
Age groups are derived using rule-based bucketing to support population-level analysis and risk stratification.

### Cost Aggregation
- Medication costs are aggregated at the **medication_description** level for Pareto and concentration analysis.
- Patient-level total cost represents the sum of all associated medication and encounter costs.

### Clinical Categorization
Condition categories are derived using **rule-based pattern matching** on condition descriptions (SNOMED-derived text).  
This approach prioritizes:
- Interpretability
- Reproducibility
- Alignment with service-line level analysis

---

## Data Quality Notes

- All foreign key relationships between patient, encounter, condition, and medication tables were validated.
- Data quality checks confirmed zero orphan records across mart tables.
- Missing or invalid values were standardized using `NULL` handling during transformation.

---

## Limitations

- All data is synthetic and may not fully reflect real-world coding or prescribing practices.
- Medication cost values are simulated and should not be interpreted as real reimbursement rates.
- Clinical severity and dosing details are not explicitly modeled.

---

## Intended Use

This data dictionary supports:
- Analytical reproducibility
- Reviewer understanding of variable definitions
- Future extensions of the data mart

It is not intended for clinical decision-making.

---
