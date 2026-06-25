# Feature Definitions — Credit Risk Intelligence Platform

**Author:** Nihira Sharma  
**Last Updated:** June 25, 2026  
**Status:** In Progress (to be extended later)

---

## Overview

This document defines every column across the 7 relational tables in the Home Credit Default Risk dataset. It covers:
- **Column name** (as in Postgres)
- **Data type**
- **Meaning** (credit domain interpretation)
- **Notes** (missing data strategy, sentinel values, aggregation hints)

Updated incrementally as features are engineered later.

---

## Table: application_train

**Grain:** One row per loan applicant (SK_ID_CURR)  
**Rows:** 307,511  
**Target:** TARGET (0 = repaid, 1 = default)

### Core Identifiers

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_CURR | BIGINT | Unique applicant ID | Primary key; used to join all child tables |
| TARGET | NUMERIC | Default indicator | 0 = non-default, 1 = default; ~8% rate |

### Loan Characteristics

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| NAME_CONTRACT_TYPE | VARCHAR | Loan product type | e.g., "Cash loans", "Revolving loans" |
| AMT_CREDIT | NUMERIC | Loan amount (currency units) | Principal requested |
| AMT_ANNUITY | NUMERIC | Loan annuity (periodic payment) | Used to derive annuity-to-income ratio |
| AMT_GOODS_PRICE | NUMERIC | Price of goods financed | May differ from credit amount (down payment) |
| AMT_INCOME_TOTAL | NUMERIC | Total household income | Basis for affordability ratios |

### Demographics & Personal

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| CODE_GENDER | VARCHAR | Gender | "M" or "F"; check for encoding issues |
| DAYS_BIRTH | NUMERIC | Days since birth (negative) | Derive age = -DAYS_BIRTH / 365.25 |
| CNT_CHILDREN | NUMERIC | Number of children | May include 0 for no children |
| CNT_FAM_MEMBERS | NUMERIC | Family size | Use with income to derive per-capita figures |
| NAME_FAMILY_STATUS | VARCHAR | Marital status | e.g., "Single", "Married", "Separated" |
| NAME_EDUCATION_TYPE | VARCHAR | Education level | e.g., "Secondary", "Higher education" |
| NAME_INCOME_TYPE | VARCHAR | Income source type | e.g., "Working", "Pensioner", "State servant" |
| OCCUPATION_TYPE | VARCHAR | Job/occupation category | High missingness (~31%); may drop or bin as "Unknown" |
| NAME_HOUSING_TYPE | VARCHAR | Housing type | e.g., "House / apartment", "Rented apartment" |

### Contact & Flags

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| FLAG_PHONE | NUMERIC | Has phone contact info | 0/1; likely high correlation with FLAG_MOBIL |
| FLAG_EMAIL | NUMERIC | Has email contact | 0/1 |
| FLAG_MOBIL | NUMERIC | Has mobile phone | 0/1 |
| FLAG_EMP_PHONE | NUMERIC | Has work phone | 0/1 |
| FLAG_WORK_PHONE | NUMERIC | Has work phone registered | 0/1; may be duplicate of FLAG_EMP_PHONE |
| FLAG_CONT_MOBILE | NUMERIC | Contacted via mobile | 0/1 |
| DAYS_LAST_PHONE_CHANGE | NUMERIC | Days since last phone change | Negative; recency signal |
| FLAG_OWN_CAR | VARCHAR | Owns car | "Y" or "N" |
| FLAG_OWN_REALTY | VARCHAR | Owns real estate | "Y" or "N" |
| OWN_CAR_AGE | NUMERIC | Age of owned car (years) | Only if FLAG_OWN_CAR = "Y"; high missingness otherwise |

### Employment & Registration

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| DAYS_EMPLOYED | NUMERIC | Days employed at current job (negative) | **SENTINEL:** 365243 = unemployed; recode as NA |
| DAYS_REGISTRATION | NUMERIC | Days since address registration (negative) | Residential stability signal |
| DAYS_ID_PUBLISH | NUMERIC | Days since ID issue (negative) | Document freshness |

### Geographic & Regional

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| REGION_POPULATION_RELATIVE | NUMERIC | Relative population of applicant region | 0–1 scale; urbanization proxy |
| REGION_RATING_CLIENT | NUMERIC | Region rating (client perspective) | Categorical encoded as numeric; 1–3 range likely |
| REGION_RATING_CLIENT_W_CITY | NUMERIC | Region rating (with city weighting) | Similar to above; may be highly correlated |
| REG_REGION_NOT_LIVE_REGION | NUMERIC | Registration region ≠ living region | 0/1 flag |
| REG_REGION_NOT_WORK_REGION | NUMERIC | Registration region ≠ work region | 0/1 flag |
| LIVE_REGION_NOT_WORK_REGION | NUMERIC | Living region ≠ work region | 0/1 flag |
| REG_CITY_NOT_LIVE_CITY | NUMERIC | Registration city ≠ living city | 0/1 flag |
| REG_CITY_NOT_WORK_CITY | NUMERIC | Registration city ≠ work city | 0/1 flag |
| LIVE_CITY_NOT_WORK_CITY | NUMERIC | Living city ≠ work city | 0/1 flag |
| ORGANIZATION_TYPE | VARCHAR | Employer organization type | e.g., "Self-employed", "Private sector", "Government" |

### Application Process

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| WEEKDAY_APPR_PROCESS_START | VARCHAR | Day of week application submitted | e.g., "Monday", "Friday"; may encode day-of-week effects |
| HOUR_APPR_PROCESS_START | NUMERIC | Hour of day application submitted | 0–23; time-of-day signal for intentionality |

### External & Alternative Data Sources

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| EXT_SOURCE_1 | NUMERIC | External data source 1 (normalized score) | 0–1; highly missing (~40%); likely credit bureau score |
| EXT_SOURCE_2 | NUMERIC | External data source 2 (normalized score) | 0–1; highly missing (~55%); may be alternative bureau |
| EXT_SOURCE_3 | NUMERIC | External data source 3 (normalized score) | 0–1; highly missing (~60%); sparse but predictive |

### Social Circle & Risk Indicators

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| OBS_30_CNT_SOCIAL_CIRCLE | NUMERIC | Number of observations in social circle (30d) | Count; peer risk indicator |
| DEF_30_CNT_SOCIAL_CIRCLE | NUMERIC | Number of defaults in social circle (30d) | Count; social default contagion signal |
| OBS_60_CNT_SOCIAL_CIRCLE | NUMERIC | Number of observations in social circle (60d) | Count; longer window |
| DEF_60_CNT_SOCIAL_CIRCLE | NUMERIC | Number of defaults in social circle (60d) | Count; social default contagion signal |

### Document Submission

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| FLAG_DOCUMENT_2 to FLAG_DOCUMENT_21 | NUMERIC (each) | Document submission flags | 0/1 for each document type (ID, proof of income, etc.); 20 flags total; often 0 for most applicants |

### Credit Bureau Inquiry Frequency

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| AMT_REQ_CREDIT_BUREAU_HOUR | NUMERIC | Credit bureau inquiries in last hour | Count; recent credit-seeking signal |
| AMT_REQ_CREDIT_BUREAU_DAY | NUMERIC | Credit bureau inquiries in last day | Count |
| AMT_REQ_CREDIT_BUREAU_WEEK | NUMERIC | Credit bureau inquiries in last week | Count |
| AMT_REQ_CREDIT_BUREAU_MON | NUMERIC | Credit bureau inquiries in last month | Count |
| AMT_REQ_CREDIT_BUREAU_QRT | NUMERIC | Credit bureau inquiries in last quarter | Count |
| AMT_REQ_CREDIT_BUREAU_YEAR | NUMERIC | Credit bureau inquiries in last year | Count |

### Property & Apartment Features (Aggregated)

**These columns are aggregated statistics across properties associated with the applicant.** Three variants each (AVG, MODE, MEDI):

| Column Group | Type | Meaning | Notes |
|--------|------|---------|-------|
| APARTMENTS_* | NUMERIC | Number of apartments in building | AVG/MODE/MEDI; property complexity |
| BASEMENTAREA_* | NUMERIC | Basement area (sq meters) | AVG/MODE/MEDI |
| YEARS_BEGINEXPLUATATION_* | NUMERIC | Years since building began operation | AVG/MODE/MEDI; building age proxy |
| YEARS_BUILD_* | NUMERIC | Year building was built | AVG/MODE/MEDI; explicit age |
| COMMONAREA_* | NUMERIC | Common area size (sq meters) | AVG/MODE/MEDI; shared facilities |
| ELEVATORS_* | NUMERIC | Number of elevators | AVG/MODE/MEDI; building amenities |
| ENTRANCES_* | NUMERIC | Number of entrances | AVG/MODE/MEDI |
| FLOORSMAX_* | NUMERIC | Maximum floors | AVG/MODE/MEDI; building height |
| FLOORSMIN_* | NUMERIC | Minimum floors | AVG/MODE/MEDI |
| LANDAREA_* | NUMERIC | Land area (sq meters) | AVG/MODE/MEDI |
| LIVINGAPARTMENTS_* | NUMERIC | Number of living apartments | AVG/MODE/MEDI |
| LIVINGAREA_* | NUMERIC | Living area (sq meters) | AVG/MODE/MEDI |
| NONLIVINGAPARTMENTS_* | NUMERIC | Number of non-living apartments (commercial) | AVG/MODE/MEDI |
| NONLIVINGAREA_* | NUMERIC | Non-living area (sq meters) | AVG/MODE/MEDI |
| TOTALAREA_* | NUMERIC | Total area (sq meters) | MODE variant only |

**Note:** High missingness on property features (~50–70%); handle as "no property data" vs. imputation.

### Building & Environment

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| FONDKAPREMONT_MODE | VARCHAR | Type of apartment renovation fund | e.g., "Capital repair fund", "Not specified" |
| HOUSETYPE_MODE | VARCHAR | House type | e.g., "Block of flats", "Specific housing" |
| WALLSMATERIAL_MODE | VARCHAR | Wall material | e.g., "Brick", "Panel", "Monolithic" |
| EMERGENCYSTATE_MODE | VARCHAR | Emergency state of building | e.g., "No", "Partial" |

---

## Table: previous_application

**Grain:** One row per previous application to Home Credit (SK_ID_PREV)  
**Rows:** 1,670,214  
**Relationship:** Many-to-one with application_train (SK_ID_CURR)

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_PREV | BIGINT | Previous application ID | Primary key for this table |
| SK_ID_CURR | BIGINT | Applicant ID | Foreign key to application_train |
| NAME_CONTRACT_TYPE | VARCHAR | Type of previous loan | e.g., "Cash loans", "Revolving loans" |
| AMT_APPLICATION | NUMERIC | Amount of previous application | Requested vs. granted |
| AMT_CREDIT | NUMERIC | Amount of previous credit | Granted amount |
| AMT_ANNUITY | NUMERIC | Annuity of previous loan | Monthly payment |
| AMT_DOWN_PAYMENT | NUMERIC | Down payment on previous loan | Applicant's skin in the game |
| AMT_GOODS_PRICE | NUMERIC | Price of goods in previous application | |
| DAYS_DECISION | NUMERIC | Days since previous application decision (negative) | Recency of prior application |
| NAME_CONTRACT_STATUS | VARCHAR | Status of previous application | e.g., "Approved", "Refused", "Canceled" |
| CODE_REJECT_REASON | VARCHAR | Reason for rejection (if applicable) | e.g., "XAP", "LIMIT_TOO_HIGH" |
| RATE_DOWN_PAYMENT | NUMERIC | Down payment rate (down_payment / goods_price) | Affordability signal |
| RATE_INTEREST_PRIMARY | NUMERIC | Interest rate offered | Credit pricing |
| RATE_INTEREST_PRIVILEGED | NUMERIC | Privileged interest rate | e.g., for VIP clients |
| NAME_CASH_LOAN_PURPOSE | VARCHAR | Stated purpose of loan | e.g., "Purchase of a used car", "Repairs" |
| NAME_PAYMENT_TYPE | VARCHAR | Payment type | e.g., "Cash through the bank" |
| NAME_TYPE_SUITE | VARCHAR | Applicant role in previous application | e.g., "Unaccompanied", "Spouse, partner" |
| NAME_CLIENT_TYPE | VARCHAR | Client type in previous application | e.g., "Repeater", "New" |
| NAME_GOODS_CATEGORY | VARCHAR | Category of goods financed | e.g., "Electronics", "Furniture" |
| NAME_PORTFOLIO | VARCHAR | Loan portfolio | e.g., "POS", "CASH" |
| NAME_PRODUCT_TYPE | VARCHAR | Product type | e.g., "XLP", "Point of sale" |
| CHANNEL_TYPE | VARCHAR | Application channel | e.g., "Country-wide", "Regional", "Branch" |
| SELLERPLACE_AREA | NUMERIC | Seller place area (for POS) | Only relevant for point-of-sale |
| NAME_SELLER_INDUSTRY | VARCHAR | Seller industry (for POS) | e.g., "Furniture", "Electronics" |
| CNT_PAYMENT | NUMERIC | Number of payments in previous loan | Duration proxy |
| NAME_YIELD_GROUP | VARCHAR | Yield group (internal classification) | Risk segment |
| PRODUCT_COMBINATION | VARCHAR | Product combination code | e.g., "POS household with interest" |
| DAYS_FIRST_DRAWING | NUMERIC | Days since first drawing (negative) | Drawdown activity |
| DAYS_FIRST_DUE | NUMERIC | Days since first due date (negative) | Early in loan lifecycle |
| DAYS_LAST_DUE_1ST_VERSION | NUMERIC | Days since last due date (1st version) (negative) | Loan maturity tracking |
| DAYS_LAST_DUE | NUMERIC | Days since last due date (negative) | Current maturity status |
| DAYS_TERMINATION | NUMERIC | Days since termination (negative) | Loan completion date |
| NFLAG_INSURED_ON_APPROVAL | NUMERIC | Insurance on approval flag | 0/1 |
| WEEKDAY_APPR_PROCESS_START | VARCHAR | Day of week application submitted | |
| HOUR_APPR_PROCESS_START | NUMERIC | Hour of day application submitted | |
| FLAG_LAST_APPL_PER_CONTRACT | VARCHAR | Last application per contract | "Y"/"N" |
| NFLAG_LAST_APPL_IN_DAY | NUMERIC | Last application in the day | 0/1 |

---

## Table: bureau

**Grain:** One row per credit facility at other financial institutions  
**Rows:** 1,716,428  
**Relationship:** Many-to-one with application_train (SK_ID_CURR)

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_BUREAU | BIGINT | Bureau record ID | NOT unique; same ID can appear multiple times (see bureau_balance) |
| SK_ID_CURR | BIGINT | Applicant ID | Foreign key to application_train |
| CREDIT_ACTIVE | VARCHAR | Current credit status | "Active", "Closed", "Sold" |
| CREDIT_CURRENCY | VARCHAR | Credit currency | Usually "currency 1" (local) or foreign currency |
| DAYS_CREDIT | NUMERIC | Days since credit opened (negative) | Credit age / account longevity |
| CREDIT_DAY_OVERDUE | NUMERIC | Current days overdue | 0 if current; >0 if delinquent |
| DAYS_CREDIT_ENDDATE | NUMERIC | Days until credit end date (negative) | Remaining life of credit |
| DAYS_ENDDATE_FACT | NUMERIC | Days since actual credit end date (negative) | When credit actually closed |
| AMT_CREDIT_MAX_OVERDUE | NUMERIC | Maximum overdue amount ever | Historical delinquency severity |
| CNT_CREDIT_PROLONG | NUMERIC | Number of credit prolongations | Refinancing activity; may signal distress |
| AMT_CREDIT_SUM | NUMERIC | Total credit sum | Total facility size |
| AMT_CREDIT_SUM_DEBT | NUMERIC | Current debt on credit | Outstanding balance |
| AMT_CREDIT_SUM_LIMIT | NUMERIC | Credit limit | For revolving products |
| AMT_CREDIT_SUM_OVERDUE | NUMERIC | Total overdue amount | Current delinquency |
| CREDIT_TYPE | VARCHAR | Type of credit | e.g., "Consumer credit", "Credit card", "Mortgage" |
| DAYS_CREDIT_UPDATE | NUMERIC | Days since bureau last updated (negative) | Data freshness |
| AMT_ANNUITY | NUMERIC | Annuity of credit | Monthly payment (if known) |

---

## Table: bureau_balance

**Grain:** One row per bureau credit per month  
**Rows:** 27,299,925  
**Relationship:** Many-to-one with bureau (SK_ID_BUREAU)

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_BUREAU | BIGINT | Bureau record ID | Links to bureau table |
| MONTHS_BALANCE | NUMERIC | Month number (negative, relative to application) | -1 = last month before application, -2 = 2 months prior, etc. |
| STATUS | VARCHAR | Delinquency status in that month | "0" = paid on time, "1" = 1–30 days late, "2" = 30–60 days late, etc.; "X" = no consumption, "C" = paid in full, "5+" = severely delinquent |

**Aggregation strategy for later:**
- Count months at each delinquency level
- Worst (maximum) delinquency status ever
- Share of months with status "0" (paid on time)
- Recency of delinquency (most recent month with status > "0")

---

## Table: credit_card_balance

**Grain:** One row per credit card per month  
**Rows:** 3,840,312  
**Relationship:** Many-to-one with previous_application (SK_ID_PREV) and application_train (SK_ID_CURR)

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_PREV | BIGINT | Previous application ID (credit card product) | Links to previous_application |
| SK_ID_CURR | BIGINT | Applicant ID | Links to application_train |
| MONTHS_BALANCE | NUMERIC | Month relative to application (negative) | -1 = last month, etc. |
| AMT_BALANCE | NUMERIC | Balance on card | Current outstanding balance |
| AMT_CREDIT_LIMIT_ACTUAL | NUMERIC | Actual credit limit | Card's available limit |
| AMT_DRAWINGS_ATM_CURRENT | NUMERIC | ATM withdrawals in current month | Cash advance activity |
| AMT_DRAWINGS_CURRENT | NUMERIC | Total drawings in current month | All withdrawal types |
| AMT_DRAWINGS_OTHER_CURRENT | NUMERIC | Other drawings in current month | Non-ATM |
| AMT_DRAWINGS_POS_CURRENT | NUMERIC | Point-of-sale drawings in current month | In-store purchases |
| AMT_INST_MIN_REGULARITY | NUMERIC | Minimum installment regularity | Whether minimum payments made on time |
| AMT_PAYMENT_CURRENT | NUMERIC | Payment in current month | Amount paid back |
| AMT_PAYMENT_TOTAL_CURRENT | NUMERIC | Total payments in current month | |
| AMT_RECEIVABLE_PRINCIPAL | NUMERIC | Receivable principal | Portion of balance that is principal |
| AMT_RECIVABLE | NUMERIC | Receivable amount (typo in column name) | Total receivable |
| AMT_TOTAL_RECEIVABLE | NUMERIC | Total receivable | Principal + interest |
| CNT_DRAWINGS_ATM_CURRENT | NUMERIC | Count of ATM withdrawals | Frequency signal |
| CNT_DRAWINGS_CURRENT | NUMERIC | Count of drawings | Total transaction count |
| CNT_DRAWINGS_OTHER_CURRENT | NUMERIC | Count of other drawings | |
| CNT_DRAWINGS_POS_CURRENT | NUMERIC | Count of POS transactions | In-store purchase frequency |
| CNT_INSTALMENT_MATURE_CUM | NUMERIC | Cumulative matured installments | |
| NAME_CONTRACT_STATUS | VARCHAR | Contract status in that month | "Active", "Completed", "Closed", etc. |
| SK_DPD | NUMERIC | Days past due | Current delinquency (0 if current) |
| SK_DPD_DEF | NUMERIC | Days past due (definition variant) | May differ slightly from SK_DPD |

**Aggregation strategy for later:**
- Mean/max utilization ratio (balance / limit)
- Mean/max DPD (days past due)
- Count of months with DPD > 0
- Mean payment-to-balance ratio (payment behavior)
- Variability in utilization (risky if jumping)

---

## Table: installments_payments

**Grain:** One row per installment payment  
**Rows:** 13,605,401  
**Relationship:** Many-to-one with previous_application (SK_ID_PREV) and application_train (SK_ID_CURR)

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_PREV | BIGINT | Previous application ID | Links to previous_application |
| SK_ID_CURR | BIGINT | Applicant ID | Links to application_train |
| NUM_INSTALMENT_VERSION | NUMERIC | Installment plan version | If rescheduled, version increments |
| NUM_INSTALMENT_NUMBER | NUMERIC | Installment number | 1, 2, 3, ... for each scheduled payment |
| DAYS_INSTALMENT | NUMERIC | Days instalment due (negative) | When payment was due |
| DAYS_ENTRY_PAYMENT | NUMERIC | Days payment entered (negative) | When payment was actually made |
| AMT_INSTALMENT | NUMERIC | Scheduled installment amount | What was due |
| AMT_PAYMENT | NUMERIC | Actual payment amount | What was paid |

**Aggregation strategy for later:**
- Count of payments on time (DAYS_ENTRY_PAYMENT <= DAYS_INSTALMENT)
- Count of late payments
- Count of underpaid installments (AMT_PAYMENT < AMT_INSTALMENT)
- Mean days late (if late)
- Payment regularity / consistency
- Most recent payment status

---

## Table: pos_cash_balance

**Grain:** One row per POS credit per month  
**Rows:** 10,001,358  
**Relationship:** Many-to-one with previous_application (SK_ID_PREV) and application_train (SK_ID_CURR)

| Column | Type | Meaning | Notes |
|--------|------|---------|-------|
| SK_ID_PREV | BIGINT | Previous application ID (POS credit) | Links to previous_application |
| SK_ID_CURR | BIGINT | Applicant ID | Links to application_train |
| MONTHS_BALANCE | NUMERIC | Month relative to application (negative) | -1 = last month, etc. |
| CNT_INSTALMENT | NUMERIC | Number of installments | How many payments in the contract |
| CNT_INSTALMENT_FUTURE | NUMERIC | Number of future installments | How many remaining |
| NAME_CONTRACT_STATUS | VARCHAR | Contract status | "Active", "Completed", "Closed", "Demand", "Signed" |
| SK_DPD | NUMERIC | Days past due | Current delinquency |
| SK_DPD_DEF | NUMERIC | Days past due (definition variant) | May differ from SK_DPD |

**Aggregation strategy for later:**
- Mean/max DPD
- Share of months with DPD > 0
- Contract completion rate
- Recency of POS activity

---

## Data Quality Notes & Handling Strategy

### Sentinels & Special Values

| Column(s) | Sentinel | Handling |
|-----------|----------|----------|
| DAYS_EMPLOYED | 365243 | Recode as NA; indicates "unemployed" or missing employment info |
| EXT_SOURCE_*, property features | NAs | High missingness (40–70%); decide per feature: drop, impute, or create "missing" indicator |
| OCCUPATION_TYPE | NULL | ~31% missing; consider binning as "Unknown" or dropping |
| OWN_CAR_AGE | NULL | Only meaningful if FLAG_OWN_CAR = "Y"; otherwise recode as 0 or NA |

### High-Missing Columns (>40%)

- `EXT_SOURCE_3` (~60% missing)
- `EXT_SOURCE_2` (~55% missing)
- `EXT_SOURCE_1` (~40% missing)
- Property features (APARTMENTS_*, BASEMENTAREA_*, etc.) (~50–70% missing)
- `OCCUPATION_TYPE` (~31% missing)

**Decision:** Drop these entirely, or create binary "has_ext_source_X" and impute with median for modeling (will be documented later).

### Class Imbalance

- **Default rate:** 8% (non-default: 92%)
- **Strategy:** Stratified train/test split; natural distribution in training (no SMOTE for scorecard); judge on Gini/KS

### No Out-of-Time Validation

- **Issue:** application_train has no absolute dates; times are anonymized day-offsets.
- **Mitigation:** Use stratified k-fold CV + explicit train/test split; document as limitation.

### Foreign Key Integrity

- Child tables (bureau, previous_application, etc.) have orphaned records (SK_ID_CURR not in application_train).
- **Decision:** Keep orphans; they represent valid history but will be dropped during aggregation (LEFT JOIN).

---

## Derived Features (Computed later)

These will be created during feature engineering:

| Feature | Computation | Rationale |
|---------|-----------|-----------|
| age_years | -DAYS_BIRTH / 365.25 | Interpretable age for modeling |
| employment_years | -DAYS_EMPLOYED / 365.25 (post-sentinel fix) | Employment duration |
| credit_to_income | AMT_CREDIT / AMT_INCOME_TOTAL | Affordability proxy |
| annuity_to_income | AMT_ANNUITY / AMT_INCOME_TOTAL | Payment burden |
| income_per_family | AMT_INCOME_TOTAL / (CNT_FAM_MEMBERS + 1) | Per-capita income |
| credit_to_goods | AMT_CREDIT / AMT_GOODS_PRICE | Loan-to-value |
| bureau_active_count | COUNT(bureau) WHERE CREDIT_ACTIVE = "Active" | Active credit facilities |
| bureau_overdue_max | MAX(AMT_CREDIT_MAX_OVERDUE) across all bureau records | Historical delinquency severity |
| installments_late_pct | COUNT(late) / COUNT(total) | Payment reliability |
| credit_card_util_mean | MEAN(AMT_BALANCE / AMT_CREDIT_LIMIT_ACTUAL) | Card usage pattern |

---

## WOE/IV Notes (later)

Columns will be binned and assigned Weight of Evidence (WOE) during feature selection:

- **Numeric:** Auto-binned to maximize information value (IV)
- **Categorical:** Grouped by IV contribution
- **Flags (0/1):** Kept as-is or combined with others
- **High-missing:** Separate "missing" bin vs. imputation decision

**IV thresholds:**
- `IV < 0.02`: Low predictive power; consider dropping
- `IV 0.02–0.5`: Strong signal; include
- `IV > 0.5`: Investigate for leakage

---

## Document Version History

| Date | Phase | Update |
|------|-------|--------|
| 2026-06-25 | 1 | Initial data dictionary created; all 122 columns in application_train, all child tables documented |
| TBD | 2 | Extended with WOE bins, IV scores, final feature selection |
| TBD | 3 | Validated against final model; any features modified |
| TBD | 4 | Points scorecard mapping added |

---