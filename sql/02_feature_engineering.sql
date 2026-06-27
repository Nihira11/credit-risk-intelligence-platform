-- This script creates credit-meaningful aggregated features from:
-- - bureau (other-institution credit history)
-- - bureau_balance (monthly delinquency status)
-- - installments_payments (payment behavior)
-- - credit_card_balance (card utilization & delinquency)
-- - pos_cash_balance (point-of-sale transactions)
-- - previous_application (prior application outcomes)
--
-- Final output: analytics_base (307,511 rows, 1 per SK_ID_CURR)

-- 1. Bureau Aggregations
DROP TABLE IF EXISTS bureau_agg CASCADE;

CREATE TABLE bureau_agg AS
SELECT
  sk_id_curr,
  
  -- Count of bureau records
  COUNT(DISTINCT sk_id_bureau) as bureau_count,
  COUNT(CASE WHEN credit_active = 'Active' THEN 1 END) as bureau_active_count,
  COUNT(CASE WHEN credit_active = 'Closed' THEN 1 END) as bureau_closed_count,
  
  -- Credit amounts
  SUM(amt_credit_sum) as bureau_credit_sum_total,
  AVG(amt_credit_sum) as bureau_credit_sum_mean,
  MAX(amt_credit_sum) as bureau_credit_sum_max,
  SUM(amt_credit_sum_debt) as bureau_credit_debt_total,
  AVG(amt_credit_sum_debt) as bureau_credit_debt_mean,
  SUM(amt_credit_sum_overdue) as bureau_credit_overdue_total,
  MAX(amt_credit_sum_overdue) as bureau_credit_overdue_max,
  MAX(amt_credit_max_overdue) as bureau_overdue_max_ever,
  
  -- Delinquency ratios
  CASE 
    WHEN SUM(amt_credit_sum) > 0 
    THEN SUM(amt_credit_sum_overdue) / SUM(amt_credit_sum) 
    ELSE 0 
  END as bureau_overdue_ratio,
  
  -- Prolongation (refinancing activity – may signal distress)
  SUM(cnt_credit_prolong) as bureau_prolong_count,
  AVG(cnt_credit_prolong) as bureau_prolong_mean,
  
  -- Credit limits (for revolving products)
  SUM(amt_credit_sum_limit) as bureau_limit_total,
  AVG(amt_credit_sum_limit) as bureau_limit_mean,
  MAX(amt_credit_sum_limit) as bureau_limit_max,
  
  -- Days since most recent bureau activity
  MIN(days_credit_update) as bureau_recency_days,
  
  -- Credit types
  COUNT(CASE WHEN credit_type = 'Credit card' THEN 1 END) as bureau_credit_cards,
  COUNT(CASE WHEN credit_type = 'Consumer credit' THEN 1 END) as bureau_consumer_credits,
  COUNT(CASE WHEN credit_type = 'Mortgage' THEN 1 END) as bureau_mortgages,
  COUNT(CASE WHEN credit_type = 'Car loan' THEN 1 END) as bureau_car_loans,
  COUNT(CASE WHEN credit_type = 'Microloan' THEN 1 END) as bureau_microloans
  
FROM bureau
GROUP BY sk_id_curr;

CREATE INDEX idx_bureau_agg_sk_id_curr ON bureau_agg(sk_id_curr);

-- 2. Bureau Balance Aggregations (Delinquency patterns)
DROP TABLE IF EXISTS bureau_balance_agg CASCADE;

CREATE TABLE bureau_balance_agg AS
SELECT
  b.sk_id_curr,
  
  -- Worst delinquency status ever (assuming status: 0=paid, 1–5+=days late, X=no use, C=paid in full)
  MAX(CASE 
    WHEN bb.status IN ('5+', '4', '3', '2', '1') THEN 1 
    ELSE 0 
  END) as bureau_ever_delinquent,
  
  -- Count of months in each delinquency status
  COUNT(CASE WHEN bb.status = '0' THEN 1 END) as bureau_months_paid_on_time,
  COUNT(CASE WHEN bb.status IN ('1', '2', '3', '4', '5+') THEN 1 END) as bureau_months_delinquent,
  
  -- Share of months paid on time
  COUNT(CASE WHEN bb.status = '0' THEN 1 END)::FLOAT / 
    NULLIF(COUNT(*), 0) as bureau_months_paid_on_time_share,
  
  -- Maximum delinquency severity (higher status = worse)
  MAX(CASE 
    WHEN bb.status = '5+' THEN 5
    WHEN bb.status = '4' THEN 4
    WHEN bb.status = '3' THEN 3
    WHEN bb.status = '2' THEN 2
    WHEN bb.status = '1' THEN 1
    ELSE 0
  END) as bureau_max_delinquency_level
  
FROM bureau b
LEFT JOIN bureau_balance bb ON b.sk_id_bureau = bb.sk_id_bureau
GROUP BY b.sk_id_curr;

CREATE INDEX idx_bureau_balance_agg_sk_id_curr ON bureau_balance_agg(sk_id_curr);

-- 3. Installments Payments Aggregations (Payment behavior)
DROP TABLE IF EXISTS installments_agg CASCADE;

CREATE TABLE installments_agg AS
SELECT
  sk_id_curr,
  
  -- Count of installments
  COUNT(*) as inst_total_count,
  COUNT(CASE WHEN amt_payment > 0 THEN 1 END) as inst_paid_count,
  
  -- Payment timeliness
  COUNT(CASE WHEN days_entry_payment <= days_instalment THEN 1 END) as inst_on_time_count,
  COUNT(CASE WHEN days_entry_payment > days_instalment THEN 1 END) as inst_late_count,
  COUNT(CASE WHEN days_entry_payment > days_instalment THEN 1 END)::FLOAT / 
    NULLIF(COUNT(*), 0) as inst_late_share,
  
  -- Underpayment (paid less than due)
  COUNT(CASE WHEN amt_payment < amt_instalment AND amt_payment > 0 THEN 1 END) as inst_underpaid_count,
  COUNT(CASE WHEN amt_payment < amt_instalment AND amt_payment > 0 THEN 1 END)::FLOAT / 
    NULLIF(COUNT(CASE WHEN amt_payment > 0 THEN 1 END), 0) as inst_underpaid_share,
  
  -- Days late (if late)
  MAX(CASE WHEN days_entry_payment > days_instalment 
      THEN days_entry_payment - days_instalment 
      ELSE 0 END) as inst_max_days_late,
  AVG(CASE WHEN days_entry_payment > days_instalment 
      THEN days_entry_payment - days_instalment 
      ELSE 0 END) as inst_mean_days_late,
  
  -- Payment to installment ratio
  AVG(CASE WHEN amt_instalment > 0 THEN amt_payment / amt_instalment ELSE 0 END) as inst_payment_ratio_mean,
  MIN(CASE WHEN amt_instalment > 0 THEN amt_payment / amt_instalment ELSE 0 END) as inst_payment_ratio_min,
  
  -- Total amounts
  SUM(amt_instalment) as inst_scheduled_total,
  SUM(amt_payment) as inst_paid_total
  
FROM installments_payments
GROUP BY sk_id_curr;

CREATE INDEX idx_installments_agg_sk_id_curr ON installments_agg(sk_id_curr);

-- 4. Credit Card Balance Aggregations (Card utilization & DPD)
DROP TABLE IF EXISTS credit_card_agg CASCADE;

CREATE TABLE credit_card_agg AS
SELECT
  sk_id_curr,
  
  -- Count of credit cards
  COUNT(DISTINCT sk_id_prev) as card_count,
  
  -- Utilization (balance / limit)
  AVG(CASE WHEN amt_credit_limit_actual > 0 
      THEN amt_balance / amt_credit_limit_actual 
      ELSE 0 END) as card_util_mean,
  MAX(CASE WHEN amt_credit_limit_actual > 0 
      THEN amt_balance / amt_credit_limit_actual 
      ELSE 0 END) as card_util_max,
  MIN(CASE WHEN amt_credit_limit_actual > 0 
      THEN amt_balance / amt_credit_limit_actual 
      ELSE 0 END) as card_util_min,
  
  -- Days past due
  AVG(sk_dpd) as card_dpd_mean,
  MAX(sk_dpd) as card_dpd_max,
  COUNT(CASE WHEN sk_dpd > 0 THEN 1 END) as card_dpd_months_count,
  COUNT(CASE WHEN sk_dpd > 0 THEN 1 END)::FLOAT / 
    NULLIF(COUNT(*), 0) as card_dpd_share,
  
  -- Delinquency levels
  COUNT(CASE WHEN sk_dpd > 90 THEN 1 END) as card_severely_delinquent_months,
  COUNT(CASE WHEN sk_dpd > 30 AND sk_dpd <= 90 THEN 1 END) as card_moderately_delinquent_months,
  
  -- ATM/cash withdrawals (riskier behavior)
  SUM(amt_drawings_atm_current) as card_atm_total,
  SUM(cnt_drawings_atm_current) as card_atm_count,
  AVG(cnt_drawings_atm_current) as card_atm_count_mean,
  
  -- Overall drawings
  SUM(amt_drawings_current) as card_drawings_total,
  AVG(amt_drawings_current) as card_drawings_mean,
  
  -- Payments
  SUM(amt_payment_current) as card_payments_total,
  AVG(amt_payment_current) as card_payments_mean,
  
  -- Balance patterns
  SUM(amt_balance) as card_balance_total,
  AVG(amt_balance) as card_balance_mean
  
FROM credit_card_balance
GROUP BY sk_id_curr;

CREATE INDEX idx_credit_card_agg_sk_id_curr ON credit_card_agg(sk_id_curr);

-- 5. POS CASH Balance Aggregations
DROP TABLE IF EXISTS pos_cash_agg CASCADE;

CREATE TABLE pos_cash_agg AS
SELECT
  sk_id_curr,
  
  -- Count of POS credits
  COUNT(DISTINCT sk_id_prev) as pos_count,
  
  -- Completed contracts
  COUNT(CASE WHEN name_contract_status = 'Completed' THEN 1 END) as pos_completed_count,
  COUNT(CASE WHEN name_contract_status = 'Active' THEN 1 END) as pos_active_count,
  COUNT(CASE WHEN name_contract_status = 'Closed' THEN 1 END) as pos_closed_count,
  
  -- DPD patterns
  AVG(sk_dpd) as pos_dpd_mean,
  MAX(sk_dpd) as pos_dpd_max,
  COUNT(CASE WHEN sk_dpd > 0 THEN 1 END) as pos_dpd_months_count,
  
  -- Installment tracking
  AVG(cnt_instalment) as pos_instalment_mean,
  AVG(cnt_instalment_future) as pos_instalment_future_mean
  
FROM pos_cash_balance
GROUP BY sk_id_curr;

CREATE INDEX idx_pos_cash_agg_sk_id_curr ON pos_cash_agg(sk_id_curr);

-- 6. Previous Application Aggregations
DROP TABLE IF EXISTS previous_app_agg CASCADE;

CREATE TABLE previous_app_agg AS
SELECT
  sk_id_curr,
  
  -- Count of previous applications
  COUNT(*) as prev_app_count,
  COUNT(CASE WHEN name_contract_status = 'Approved' THEN 1 END) as prev_app_approved_count,
  COUNT(CASE WHEN name_contract_status = 'Refused' THEN 1 END) as prev_app_refused_count,
  COUNT(CASE WHEN name_contract_status = 'Canceled' THEN 1 END) as prev_app_canceled_count,
  
  -- Approval rate
  COUNT(CASE WHEN name_contract_status = 'Approved' THEN 1 END)::FLOAT / 
    NULLIF(COUNT(*), 0) as prev_app_approval_rate,
  
  -- Application amounts
  AVG(amt_application) as prev_app_amount_mean,
  MAX(amt_application) as prev_app_amount_max,
  AVG(amt_credit) as prev_credit_mean,
  MAX(amt_credit) as prev_credit_max,
  AVG(amt_down_payment) as prev_down_payment_mean,
  
  -- Annuity
  AVG(amt_annuity) as prev_annuity_mean,
  
  -- Interest rates
  AVG(rate_interest_primary) as prev_rate_mean,
  MAX(rate_interest_primary) as prev_rate_max,
  
  -- Down payment rates
  AVG(rate_down_payment) as prev_down_payment_rate_mean,
  
  -- Recency (most recent application)
  MIN(days_decision) as prev_app_recency_days,
  
  -- Product mix
  COUNT(CASE WHEN name_contract_type = 'Revolving loans' THEN 1 END) as prev_revolving_count,
  COUNT(CASE WHEN name_contract_type = 'Cash loans' THEN 1 END) as prev_cash_loans_count
  
FROM previous_application
GROUP BY sk_id_curr;

CREATE INDEX idx_previous_app_agg_sk_id_curr ON previous_app_agg(sk_id_curr);

-- 7. Assemble Master analytics Table
DROP TABLE IF EXISTS analytics_base CASCADE;

CREATE TABLE analytics_base AS
SELECT
  a.*,
  ba.bureau_count,
  ba.bureau_active_count,
  ba.bureau_closed_count,
  ba.bureau_credit_sum_total,
  ba.bureau_credit_sum_mean,
  ba.bureau_credit_sum_max,
  ba.bureau_credit_debt_total,
  ba.bureau_credit_debt_mean,
  ba.bureau_credit_overdue_total,
  ba.bureau_credit_overdue_max,
  ba.bureau_overdue_max_ever,
  ba.bureau_overdue_ratio,
  ba.bureau_prolong_count,
  ba.bureau_prolong_mean,
  ba.bureau_limit_total,
  ba.bureau_limit_mean,
  ba.bureau_limit_max,
  ba.bureau_recency_days,
  ba.bureau_credit_cards,
  ba.bureau_consumer_credits,
  ba.bureau_mortgages,
  ba.bureau_car_loans,
  ba.bureau_microloans,
  bba.bureau_ever_delinquent,
  bba.bureau_months_paid_on_time,
  bba.bureau_months_delinquent,
  bba.bureau_months_paid_on_time_share,
  bba.bureau_max_delinquency_level,
  ia.inst_total_count,
  ia.inst_paid_count,
  ia.inst_on_time_count,
  ia.inst_late_count,
  ia.inst_late_share,
  ia.inst_underpaid_count,
  ia.inst_underpaid_share,
  ia.inst_max_days_late,
  ia.inst_mean_days_late,
  ia.inst_payment_ratio_mean,
  ia.inst_payment_ratio_min,
  ia.inst_scheduled_total,
  ia.inst_paid_total,
  ca.card_count,
  ca.card_util_mean,
  ca.card_util_max,
  ca.card_util_min,
  ca.card_dpd_mean,
  ca.card_dpd_max,
  ca.card_dpd_months_count,
  ca.card_dpd_share,
  ca.card_severely_delinquent_months,
  ca.card_moderately_delinquent_months,
  ca.card_atm_total,
  ca.card_atm_count,
  ca.card_atm_count_mean,
  ca.card_drawings_total,
  ca.card_drawings_mean,
  ca.card_payments_total,
  ca.card_payments_mean,
  ca.card_balance_total,
  ca.card_balance_mean,
  pa.pos_count,
  pa.pos_completed_count,
  pa.pos_active_count,
  pa.pos_closed_count,
  pa.pos_dpd_mean,
  pa.pos_dpd_max,
  pa.pos_dpd_months_count,
  pa.pos_instalment_mean,
  pa.pos_instalment_future_mean,
  paa.prev_app_count,
  paa.prev_app_approved_count,
  paa.prev_app_refused_count,
  paa.prev_app_canceled_count,
  paa.prev_app_approval_rate,
  paa.prev_app_amount_mean,
  paa.prev_app_amount_max,
  paa.prev_credit_mean,
  paa.prev_credit_max,
  paa.prev_down_payment_mean,
  paa.prev_annuity_mean,
  paa.prev_rate_mean,
  paa.prev_rate_max,
  paa.prev_down_payment_rate_mean,
  paa.prev_app_recency_days,
  paa.prev_revolving_count,
  paa.prev_cash_loans_count
  
FROM application_train a
LEFT JOIN bureau_agg ba ON a.sk_id_curr = ba.sk_id_curr
LEFT JOIN bureau_balance_agg bba ON a.sk_id_curr = bba.sk_id_curr
LEFT JOIN installments_agg ia ON a.sk_id_curr = ia.sk_id_curr
LEFT JOIN credit_card_agg ca ON a.sk_id_curr = ca.sk_id_curr
LEFT JOIN pos_cash_agg pa ON a.sk_id_curr = pa.sk_id_curr
LEFT JOIN previous_app_agg paa ON a.sk_id_curr = paa.sk_id_curr;

-- 8. Verification
-- Verify row count (should equal application_train)
SELECT 'analytics_base row count' as check_name, 
       COUNT(*) as row_count FROM analytics_base
UNION ALL
SELECT 'application_train row count', COUNT(*) FROM application_train;

-- Check for nulls in key new features (expected due to LEFT JOINs)
SELECT 
  'bureau_count' as column_name, 
  COUNT(CASE WHEN bureau_count IS NULL THEN 1 END) as null_count,
  COUNT(*) as total_count
FROM analytics_base
UNION ALL
SELECT 'inst_total_count', 
  COUNT(CASE WHEN inst_total_count IS NULL THEN 1 END),
  COUNT(*)
FROM analytics_base
UNION ALL
SELECT 'card_count', 
  COUNT(CASE WHEN card_count IS NULL THEN 1 END),
  COUNT(*)
FROM analytics_base;