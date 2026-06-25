-- Drop existing tables if they exist
DROP TABLE IF EXISTS public.credit_card_balance CASCADE;
DROP TABLE IF EXISTS public.installments_payments CASCADE;
DROP TABLE IF EXISTS public.pos_cash_balance CASCADE;
DROP TABLE IF EXISTS public.bureau_balance CASCADE;
DROP TABLE IF EXISTS public.bureau CASCADE;
DROP TABLE IF EXISTS public.previous_application CASCADE;
DROP TABLE IF EXISTS public.application_train CASCADE;

-- 1. Main Application Table (307K loans)
CREATE TABLE public.application_train (
  sk_id_curr                         BIGINT PRIMARY KEY,
  target                             NUMERIC,
  name_contract_type                 VARCHAR(255),
  code_gender                        VARCHAR(10),
  flag_own_car                       VARCHAR(10),
  flag_own_realty                    VARCHAR(10),
  cnt_children                       NUMERIC,
  amt_income_total                   NUMERIC,
  amt_credit                         NUMERIC,
  amt_annuity                        NUMERIC,
  amt_goods_price                    NUMERIC,
  name_type_suite                    VARCHAR(255),
  name_income_type                   VARCHAR(255),
  name_education_type                VARCHAR(255),
  name_family_status                 VARCHAR(255),
  name_housing_type                  VARCHAR(255),
  region_population_relative         NUMERIC,
  days_birth                         NUMERIC,
  days_employed                      NUMERIC,
  days_registration                  NUMERIC,
  days_id_publish                    NUMERIC,
  own_car_age                        NUMERIC,
  flag_mobil                         NUMERIC,
  flag_emp_phone                     NUMERIC,
  flag_work_phone                    NUMERIC,
  flag_cont_mobile                   NUMERIC,
  flag_phone                         NUMERIC,
  flag_email                         NUMERIC,
  occupation_type                    VARCHAR(255),
  cnt_fam_members                    NUMERIC,
  region_rating_client               NUMERIC,
  region_rating_client_w_city        NUMERIC,
  weekday_appr_process_start         VARCHAR(255),
  hour_appr_process_start            NUMERIC,
  reg_region_not_live_region         NUMERIC,
  reg_region_not_work_region         NUMERIC,
  live_region_not_work_region        NUMERIC,
  reg_city_not_live_city             NUMERIC,
  reg_city_not_work_city             NUMERIC,
  live_city_not_work_city            NUMERIC,
  organization_type                  VARCHAR(255),
  ext_source_1                       NUMERIC,
  ext_source_2                       NUMERIC,
  ext_source_3                       NUMERIC,
  apartments_avg                     NUMERIC,
  basementarea_avg                   NUMERIC,
  years_beginexpluatation_avg        NUMERIC,
  years_build_avg                    NUMERIC,
  commonarea_avg                     NUMERIC,
  elevators_avg                      NUMERIC,
  entrances_avg                      NUMERIC,
  floorsmax_avg                      NUMERIC,
  floorsmin_avg                      NUMERIC,
  landarea_avg                       NUMERIC,
  livingapartments_avg               NUMERIC,
  livingarea_avg                     NUMERIC,
  nonlivingapartments_avg            NUMERIC,
  nonlivingarea_avg                  NUMERIC,
  apartments_mode                    NUMERIC,
  basementarea_mode                  NUMERIC,
  years_beginexpluatation_mode       NUMERIC,
  years_build_mode                   NUMERIC,
  commonarea_mode                    NUMERIC,
  elevators_mode                     NUMERIC,
  entrances_mode                     NUMERIC,
  floorsmax_mode                     NUMERIC,
  floorsmin_mode                     NUMERIC,
  landarea_mode                      NUMERIC,
  livingapartments_mode              NUMERIC,
  livingarea_mode                    NUMERIC,
  nonlivingapartments_mode           NUMERIC,
  nonlivingarea_mode                 NUMERIC,
  apartments_medi                    NUMERIC,
  basementarea_medi                  NUMERIC,
  years_beginexpluatation_medi       NUMERIC,
  years_build_medi                   NUMERIC,
  commonarea_medi                    NUMERIC,
  elevators_medi                     NUMERIC,
  entrances_medi                     NUMERIC,
  floorsmax_medi                     NUMERIC,
  floorsmin_medi                     NUMERIC,
  landarea_medi                      NUMERIC,
  livingapartments_medi              NUMERIC,
  livingarea_medi                    NUMERIC,
  nonlivingapartments_medi           NUMERIC,
  nonlivingarea_medi                 NUMERIC,
  fondkapremont_mode                 VARCHAR(255),
  housetype_mode                     VARCHAR(255),
  totalarea_mode                     NUMERIC,
  wallsmaterial_mode                 VARCHAR(255),
  emergencystate_mode                VARCHAR(255),
  obs_30_cnt_social_circle           NUMERIC,
  def_30_cnt_social_circle           NUMERIC,
  obs_60_cnt_social_circle           NUMERIC,
  def_60_cnt_social_circle           NUMERIC,
  days_last_phone_change             NUMERIC,
  flag_document_2                    NUMERIC,
  flag_document_3                    NUMERIC,
  flag_document_4                    NUMERIC,
  flag_document_5                    NUMERIC,
  flag_document_6                    NUMERIC,
  flag_document_7                    NUMERIC,
  flag_document_8                    NUMERIC,
  flag_document_9                    NUMERIC,
  flag_document_10                   NUMERIC,
  flag_document_11                   NUMERIC,
  flag_document_12                   NUMERIC,
  flag_document_13                   NUMERIC,
  flag_document_14                   NUMERIC,
  flag_document_15                   NUMERIC,
  flag_document_16                   NUMERIC,
  flag_document_17                   NUMERIC,
  flag_document_18                   NUMERIC,
  flag_document_19                   NUMERIC,
  flag_document_20                   NUMERIC,
  flag_document_21                   NUMERIC,
  amt_req_credit_bureau_hour         NUMERIC,
  amt_req_credit_bureau_day          NUMERIC,
  amt_req_credit_bureau_week         NUMERIC,
  amt_req_credit_bureau_mon          NUMERIC,
  amt_req_credit_bureau_qrt          NUMERIC,
  amt_req_credit_bureau_year         NUMERIC
);

-- 2. Previous Applications (applications to Home Credit, one row per application)
CREATE TABLE public.previous_application (
  sk_id_prev                         BIGINT PRIMARY KEY,
  sk_id_curr                         BIGINT NOT NULL REFERENCES public.application_train(sk_id_curr),
  name_contract_type                 VARCHAR(255),
  amt_annuity                        NUMERIC,
  amt_application                    NUMERIC,
  amt_credit                         NUMERIC,
  amt_down_payment                   NUMERIC,
  amt_goods_price                    NUMERIC,
  weekday_appr_process_start         VARCHAR(255),
  hour_appr_process_start            NUMERIC,
  flag_last_appl_per_contract        VARCHAR(10),
  nflag_last_appl_in_day             NUMERIC,
  rate_down_payment                  NUMERIC,
  rate_interest_primary              NUMERIC,
  rate_interest_privileged           NUMERIC,
  name_cash_loan_purpose             VARCHAR(255),
  name_contract_status               VARCHAR(255),
  days_decision                      NUMERIC,
  name_payment_type                  VARCHAR(255),
  code_reject_reason                 VARCHAR(255),
  name_type_suite                    VARCHAR(255),
  name_client_type                   VARCHAR(255),
  name_goods_category                VARCHAR(255),
  name_portfolio                     VARCHAR(255),
  name_product_type                  VARCHAR(255),
  channel_type                       VARCHAR(255),
  sellerplace_area                   NUMERIC,
  name_seller_industry               VARCHAR(255),
  cnt_payment                        NUMERIC,
  name_yield_group                   VARCHAR(255),
  product_combination                VARCHAR(255),
  days_first_drawing                 NUMERIC,
  days_first_due                     NUMERIC,
  days_last_due_1st_version          NUMERIC,
  days_last_due                      NUMERIC,
  days_termination                   NUMERIC,
  nflag_insured_on_approval          NUMERIC
);

-- 3. Bureau (credit history from other financial institutions)
CREATE TABLE public.bureau (
  sk_id_bureau                       BIGINT PRIMARY KEY,
  sk_id_curr                         BIGINT NOT NULL REFERENCES public.application_train(sk_id_curr),
  credit_active                      VARCHAR(255),
  credit_currency                    VARCHAR(10),
  days_credit                        NUMERIC,
  credit_day_overdue                 NUMERIC,
  days_credit_enddate                NUMERIC,
  days_enddate_fact                  NUMERIC,
  amt_credit_max_overdue             NUMERIC,
  cnt_credit_prolong                 NUMERIC,
  amt_credit_sum                     NUMERIC,
  amt_credit_sum_debt                NUMERIC,
  amt_credit_sum_limit               NUMERIC,
  amt_credit_sum_overdue             NUMERIC,
  credit_type                        VARCHAR(255),
  days_credit_update                 NUMERIC,
  amt_annuity                        NUMERIC
);

-- 4. Bureau Balance (monthly status of bureau credits)
CREATE TABLE public.bureau_balance (
  sk_id_bureau                       BIGINT NOT NULL REFERENCES public.bureau(sk_id_bureau),
  months_balance                     NUMERIC,
  status                             VARCHAR(10),
  PRIMARY KEY (sk_id_bureau, months_balance)
);

-- 5. Credit Card Balance (monthly balances and transactions)
CREATE TABLE public.credit_card_balance (
  sk_id_prev                         BIGINT NOT NULL REFERENCES public.previous_application(sk_id_prev),
  sk_id_curr                         BIGINT NOT NULL REFERENCES public.application_train(sk_id_curr),
  months_balance                     NUMERIC,
  amt_balance                        NUMERIC,
  amt_credit_limit_actual            NUMERIC,
  amt_drawings_atm_current           NUMERIC,
  amt_drawings_current               NUMERIC,
  amt_drawings_other_current         NUMERIC,
  amt_drawings_pos_current           NUMERIC,
  amt_inst_min_regularity            NUMERIC,
  amt_payment_current                NUMERIC,
  amt_payment_total_current          NUMERIC,
  amt_receivable_principal           NUMERIC,
  amt_recivable                      NUMERIC,
  amt_total_receivable               NUMERIC,
  cnt_drawings_atm_current           NUMERIC,
  cnt_drawings_current               NUMERIC,
  cnt_drawings_other_current         NUMERIC,
  cnt_drawings_pos_current           NUMERIC,
  cnt_instalment_mature_cum          NUMERIC,
  name_contract_status               VARCHAR(255),
  sk_dpd                             NUMERIC,
  sk_dpd_def                         NUMERIC,
  PRIMARY KEY (sk_id_prev, sk_id_curr, months_balance)
);

-- 6. Installments Payments (individual payment records)
CREATE TABLE public.installments_payments (
  sk_id_prev                         BIGINT NOT NULL REFERENCES public.previous_application(sk_id_prev),
  sk_id_curr                         BIGINT NOT NULL REFERENCES public.application_train(sk_id_curr),
  num_instalment_version             NUMERIC,
  num_instalment_number              NUMERIC,
  days_instalment                    NUMERIC,
  days_entry_payment                 NUMERIC,
  amt_instalment                     NUMERIC,
  amt_payment                        NUMERIC,
  PRIMARY KEY (sk_id_prev, sk_id_curr, num_instalment_number)
);

-- 7. POS CASH Balance (point-of-sale cash transactions)
CREATE TABLE public.pos_cash_balance (
  sk_id_prev                         BIGINT NOT NULL REFERENCES public.previous_application(sk_id_prev),
  sk_id_curr                         BIGINT NOT NULL REFERENCES public.application_train(sk_id_curr),
  months_balance                     NUMERIC,
  cnt_instalment                     NUMERIC,
  cnt_instalment_future              NUMERIC,
  name_contract_status               VARCHAR(255),
  sk_dpd                             NUMERIC,
  sk_dpd_def                         NUMERIC,
  PRIMARY KEY (sk_id_prev, sk_id_curr, months_balance)
);

-- Indexes
CREATE INDEX idx_bureau_sk_id_curr ON public.bureau(sk_id_curr);
CREATE INDEX idx_bureau_balance_sk_id_bureau ON public.bureau_balance(sk_id_bureau);
CREATE INDEX idx_credit_card_balance_sk_id_curr ON public.credit_card_balance(sk_id_curr);
CREATE INDEX idx_credit_card_balance_sk_id_prev ON public.credit_card_balance(sk_id_prev);
CREATE INDEX idx_installments_sk_id_curr ON public.installments_payments(sk_id_curr);
CREATE INDEX idx_installments_sk_id_prev ON public.installments_payments(sk_id_prev);
CREATE INDEX idx_pos_cash_sk_id_curr ON public.pos_cash_balance(sk_id_curr);
CREATE INDEX idx_pos_cash_sk_id_prev ON public.pos_cash_balance(sk_id_prev);
CREATE INDEX idx_previous_app_sk_id_curr ON public.previous_application(sk_id_curr);

-- Grants (credit_app user read/write access)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO credit_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO credit_app;