# Model Comparison

Logistic regression vs. XGBoost on the Home Credit test set, and why logistic was chosen for production.

All metrics are on the held-out 30% test set (92,253 applicants), with no leakage and no look-ahead bias.

---

## Results

| Metric | Logistic (production) | XGBoost (benchmark) | Difference |
|---|---|---|---|
| Gini (test) | 0.313 | 0.322 | +0.009 |
| KS (test) | 0.227 | 0.228 | +0.001 |
| AUC (test) | 0.656 | 0.661 | +0.005 |

XGBoost was trained on the full raw application feature set; logistic on the 22 WOE-selected features (16 after dropping collinear ones). Both used the same stratified 70/30 split.

**The gap is marginal — about 0.009 Gini.** XGBoost does not meaningfully out-predict the logistic model on this data.

---

## Overfitting check

The logistic model shows no overfitting — train and test metrics are within ~0.002 Gini of each other. XGBoost shows a slightly larger train-test gap (it fits the training set harder), which is expected for a tree ensemble and is another small mark against deploying it here.

---

## Calibration

The logistic model is well-calibrated: predicted default probabilities track observed default rates closely across deciles (calibration MSE well below the 0.002 "excellent" threshold). Calibration matters for a scorecard because the points scale is anchored on odds — a miscalibrated model would produce misleading scores.

---

## Decision: logistic regression for production

The 0.009 Gini advantage of XGBoost does not justify deploying a black-box ensemble. Logistic wins on every dimension that matters for a lending decision:

1. **Interpretability** — each coefficient is a log-odds contribution a stakeholder can read. XGBoost is 100+ opaque trees.
2. **Regulatory compliance** — the feature-to-risk relationship is monotonic and explainable, which is what model-risk review (e.g. SR 11-7) expects.
3. **Scorecard conversion** — logistic converts directly into a points card; an ensemble does not.
4. **Stability** — logistic coefficients are stable across retrains; tree ensembles can shift materially on retrain.
5. **Deployment** — a single equation is far easier to version, audit, and debug than an ensemble.

XGBoost remains in the repo as an honest benchmark: it confirms that choosing the simpler, explainable model costs almost nothing in predictive power.

---

## On the absolute metric level

A test Gini of ~0.31 is modest but realistic for Home Credit without leakage. The dataset's signal is diffuse; published high scores on it typically rely on stacking and aggressive feature engineering that edge toward look-ahead bias. The priority here was a model that generalises honestly, is well-calibrated, and converts cleanly into a deployable, auditable scorecard — not a leaderboard number.

See `METHODOLOGY.md` for the full pipeline and `notebooks/03_modeling.html` for the validation detail.