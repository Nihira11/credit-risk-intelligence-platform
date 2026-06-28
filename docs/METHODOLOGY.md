# Methodology

Credit Risk Intelligence Platform – how the scorecard is built, end to end.

This document explains the *why* behind each stage. For metric numbers and the model decision, see `MODEL_COMPARISON.md`. For feature definitions, see `FEATURE_DEFINITIONS.md`.

---

## 1. Problem

Predict the probability that a loan applicant defaults, using the Home Credit Default Risk dataset (307,511 applicants, ~8% default rate), and convert that prediction into a deployable points scorecard with approve / review / decline cutoffs.

The deliverable is not a Kaggle leaderboard score. It is an auditable, regulator-friendly lending tool: a logistic model, a points card a credit analyst can read row by row, and a decision policy with quantified default rates per band.

---

## 2. Data engineering (PostgreSQL)

The raw data spans seven tables and roughly 58.6M historical records (bureau, bureau balance, previous applications, POS/cash balances, instalment payments, credit-card balances), keyed to 307,511 current applicants.

Rather than aggregate in memory, the child tables were aggregated in PostgreSQL:

- `01_create_tables.sql` – schema and bulk load of the seven raw tables.
- `02_feature_engineering.sql` – per-applicant aggregations of the child tables (counts, means, shares, max-ever values) into application-level features.
- `03_create_analytics_table.sql` – assembles a single `analytics_base` table joining the application row to every aggregated feature.
- `04_validation_splits.sql` – documents the train/test split logic at the database level.

Doing the aggregation in SQL keeps the heavy join/group-by work where it belongs and makes the feature pipeline reproducible from raw data.

---

## 3. Feature selection (WOE / IV)

Features were transformed with **Weight of Evidence (WOE)** and ranked by **Information Value (IV)**.

WOE replaces each feature's bins with the log-odds of good-vs-bad within that bin. This does three useful things for a credit model:

- It linearises each feature's relationship with the log-odds of default, which is exactly what logistic regression expects.
- It handles missing values and outliers gracefully (they become their own bin).
- It produces monotonic, interpretable inputs – the basis for a points scorecard.

Features were retained by IV (a standard "medium-or-better predictive power" threshold), yielding the modelling dataset of 22 WOE features plus the target. The WOE binning rules are persisted (`woe_bins.rds`) so the same transformation can be replayed at scoring time.

---

## 4. Modelling

**Split.** A stratified 70/30 train/test split (seed 42) preserves the ~8% default rate in both sets. The split is stratified so neither set is accidentally easier or harder than the other.

**Production model – logistic regression.** Fit on all WOE features. Six count-type features (e.g. `bureau_count`, `pos_count`, `prev_app_count`) were perfectly collinear and aliased to `NA` coefficients; they were dropped because they add no information. The model is chosen for production because:

1. Coefficients map directly to log-odds – every decision is explainable.
2. The relationship between feature and risk is monotonic – regulator-friendly.
3. It converts directly into a points scorecard.
4. Coefficients are stable across retrains, unlike tree ensembles.

**Benchmark – XGBoost.** Trained on the same split for comparison only, to confirm we are not leaving large amounts of signal on the table by choosing a simpler model.

**Validation.** Test-set Gini, KS and AUC; a train-vs-test gap check for overfitting; and a decile calibration check (predicted vs. observed default rate per bin).

---

## 5. Scorecard generation

The logistic model outputs log-odds, which are hard to read. The scorecard rescales them into points using the industry-standard **PDO** (Points to Double the Odds) method:

```
Score = Offset + Factor × ln(odds_good)
Factor = PDO / ln(2)
Offset = base_score − Factor × ln(base_odds)
```

anchored at base score 600, base odds 50:1, PDO 20. Each WOE bin of each feature is then worth a fixed number of points; an applicant's score is the sum of their matched bins. Higher score = lower risk, like a FICO score.

Because the scorecard is a monotonic rescaling of the model's probabilities, its ranking power (Gini / KS / AUC) is identical to the model's – this is verified explicitly, and any discrepancy would signal a scaling bug.

**Decision policy.** Cutoffs were calibrated to the model's actual score range (scores compress because the data's separability is moderate), not to a generic 300–850 assumption:

- Decline below the lower cutoff (highest-risk band).
- Review in the middle.
- Approve at or above the upper cutoff.

The cutoffs trade approval volume against expected loss; they are tuned for a usable auto-approve rate at a default rate well below the population average, and can be moved to match a given risk appetite.

---

## 6. Honesty over inflation

The reported metrics are modest by design. The Home Credit signal is genuinely diffuse, and the goal here is a model with no leakage and no look-ahead bias – a model that would behave the same way on next month's applicants. Inflated metrics (Gini ~0.80) on this dataset almost always indicate leakage. A stable, well-calibrated, honestly-validated model is the more defensible artifact for production lending.

---

## Reproducing the pipeline

1. Load the seven raw CSVs into PostgreSQL and run `sql/01`–`sql/04`.
2. Knit `notebooks/01_eda.Rmd` and `notebooks/02_feature_selection.Rmd` to produce `modeling_dataset_woe.csv` and `woe_bins.rds`.
3. Knit `notebooks/03_modeling.Rmd` → model + predictions.
4. Knit `notebooks/04_scorecard_generation.Rmd` → points card + decision policy.
5. Launch `shiny_app/app.R` for the interactive dashboard.