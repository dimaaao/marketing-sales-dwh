with
raw_sales as (select * from `beibit-499311.amo.amo_view`),
raw_regs as (select * from `beibit-499311.regs.regs_view`),
raw_checkins as (select * from `beibit-499311.checkins.checkins_view`),
raw_costs as (select * from `beibit-499311.beibit_costs.cost_view`),
raw_apps as (select * from `beibit-499311.views.application_view`),

-- общий по меткам (добавлены даты dt_potok)
utm_dict as (select distinct dt, utm_source, utm_medium, utm_campaign, utm_content, utm_term from
(
  -- реги
  select dt, IFNULL(utm_source,'null') as utm_source, IFNULL(utm_medium,'null') as utm_medium, IFNULL(utm_campaign,'null') as utm_campaign, IFNULL(utm_content,'null') as utm_content, IFNULL(utm_term,'null') as utm_term from raw_regs
  UNION ALL
  select dt_potok, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_regs 
  UNION ALL
  -- заявки
  select application_date, IFNULL(r_sourse,'null'), IFNULL(r_medium,'null'), IFNULL(r_campaign,'null'), IFNULL(r_content,'null'), IFNULL(r_term,'null') from raw_apps
  UNION ALL
  select dt_potok, IFNULL(r_sourse,'null'), IFNULL(r_medium,'null'), IFNULL(r_campaign,'null'), IFNULL(r_content,'null'), IFNULL(r_term,'null') from raw_apps 
  UNION ALL
  -- ОП дата транша
  select dt_of_payment, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_sales
  UNION ALL
  -- ОП дата прожади
  select dt_of_sale, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_sales
  UNION ALL
  -- ОП дата создания
  select dt_create, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_sales
  UNION ALL
  -- ОП дата закрытия
  select dt_close, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_sales
  UNION ALL
  -- ОП поток
  select dt_potok, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_sales 
  UNION ALL
  -- расходы
  select dt, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_costs
  UNION ALL
  select dt_potok, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_costs 
  UNION ALL
  -- чекины
  select dt_of_web, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_checkins
  UNION ALL
  select dt_potok, IFNULL(utm_source,'null'), IFNULL(utm_medium,'null'), IFNULL(utm_campaign,'null'), IFNULL(utm_content,'null'), IFNULL(utm_term,'null') from raw_checkins
)),

--реги
regs as (
  select
    dt, 
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_regs) as num_of_regs,
    sum(num_of_uniq_regs) as num_of_uniq_regs
  from raw_regs
  group by dt, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

regs_by_dt_potok as (
  select
    dt_potok, 
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_regs) as num_of_regs,
    sum(num_of_uniq_regs) as num_of_uniq_regs
  from raw_regs
  group by dt_potok, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

--заявки
applications as (
  select
    application_date,
    IFNULL(r_sourse, 'null') as utm_source, 
    IFNULL(r_medium, 'null') as utm_medium,
    IFNULL(r_campaign, 'null') as utm_campaign,
    IFNULL(r_content, 'null') as utm_content,
    IFNULL(r_term, 'null') as utm_term,
    sum(num_of_apps) as num_of_application,
    sum(num_of_uniq_apps) as num_of_uniq_apps
  from raw_apps
  group by application_date, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

applications_by_dt_potok as (
  select
    dt_potok,
    IFNULL(r_sourse, 'null') as utm_source, 
    IFNULL(r_medium, 'null') as utm_medium,
    IFNULL(r_campaign, 'null') as utm_campaign,
    IFNULL(r_content, 'null') as utm_content,
    IFNULL(r_term, 'null') as utm_term,
    sum(num_of_apps) as num_of_application,
    sum(num_of_uniq_apps) as num_of_uniq_apps
  from raw_apps
  group by dt_potok, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

sales_by_dt_of_payment as (
  select
    dt_of_payment,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_deals) as num_of_deals,
    sum(num_of_prepayment) as num_of_prepayment,
    sum(num_of_succes_deals) as num_of_succes_deals,
    sum(num_of_clean_success_deals) as num_of_clean_success_deals,
    sum(sum_of_payment) as sum_of_payment,
    sum(sum_of_refund) as sum_of_refund,
    sum(sum_of_clean_payment) as sum_of_clean_payment
  from raw_sales
  group by dt_of_payment, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

sales_by_dt_of_sale as (
  select
    dt_of_sale,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_deals) as num_of_deals,
    sum(num_of_prepayment) as num_of_prepayment,
    sum(num_of_succes_deals) as num_of_succes_deals,
    sum(num_of_clean_success_deals) as num_of_clean_success_deals,
    sum(sum_of_payment) as sum_of_payment,
    sum(sum_of_refund) as sum_of_refund,
    sum(sum_of_clean_payment) as sum_of_clean_payment
  from raw_sales
  group by dt_of_sale, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

sales_by_dt_create as (
  select
    dt_create,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_deals) as num_of_deals,
    sum(num_of_prepayment) as num_of_prepayment,
    sum(num_of_succes_deals) as num_of_succes_deals,
    sum(num_of_clean_success_deals) as num_of_clean_success_deals,
    sum(sum_of_payment) as sum_of_payment,
    sum(sum_of_refund) as sum_of_refund,
    sum(sum_of_clean_payment) as sum_of_clean_payment
  from raw_sales
  group by dt_create, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

sales_by_dt_close as (
  select
    dt_close,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_deals) as num_of_deals,
    sum(num_of_prepayment) as num_of_prepayment,
    sum(num_of_succes_deals) as num_of_succes_deals,
    sum(num_of_clean_success_deals) as num_of_clean_success_deals,
    sum(sum_of_payment) as sum_of_payment,
    sum(sum_of_refund) as sum_of_refund,
    sum(sum_of_clean_payment) as sum_of_clean_payment
  from raw_sales
  group by dt_close, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

sales_by_dt_potok as (
  select
    dt_potok,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_deals) as num_of_deals,
    sum(num_of_prepayment) as num_of_prepayment,
    sum(num_of_succes_deals) as num_of_succes_deals,
    sum(num_of_clean_success_deals) as num_of_clean_success_deals,
    sum(sum_of_payment) as sum_of_payment,
    sum(sum_of_refund) as sum_of_refund,
    sum(sum_of_clean_payment) as sum_of_clean_payment
  from raw_sales
  group by dt_potok, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

costs as (
  select
    dt,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(spend_USD) as spend_USD,
    sum(spend_KZT) as spend_KZT,
    sum(clicks) as num_of_clicks,
    sum(impressions) as num_of_impressions
  from raw_costs
  group by dt, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

costs_by_dt_potok as (
  select
    dt_potok,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(spend_USD) as spend_USD,
    sum(spend_KZT) as spend_KZT,
    sum(clicks) as num_of_clicks,
    sum(impressions) as num_of_impressions
  from raw_costs
  group by dt_potok, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

checkins as (
  select
    dt_of_web,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_checkins) as num_of_checkins,
    sum(num_of_uniq_checkins) as num_of_uniq_checkins
  from raw_checkins
  group by dt_of_web, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

checkins_by_dt_potok as (
  select
    dt_potok,
    IFNULL(utm_source, 'null') as utm_source, 
    IFNULL(utm_medium, 'null') as utm_medium,
    IFNULL(utm_campaign, 'null') as utm_campaign,
    IFNULL(utm_content, 'null') as utm_content,
    IFNULL(utm_term, 'null') as utm_term,
    sum(num_of_checkins) as num_of_checkins,
    sum(num_of_uniq_checkins) as num_of_uniq_checkins
  from raw_checkins
  group by dt_potok, utm_source, utm_medium, utm_campaign, utm_content, utm_term
),

final_table as (
  select

  d.*,

  sum(r.num_of_regs) as num_of_regs,
  sum(r.num_of_uniq_regs) as num_of_uniq_regs,
  sum(rp.num_of_regs) as num_of_regs_by_dt_potok,
  sum(rp.num_of_uniq_regs) as num_of_uniq_regs_by_dt_potok,

  sum(a.num_of_application) as num_of_application,
  sum(a.num_of_uniq_apps) as num_of_uniq_apps,
  sum(ap.num_of_application) as num_of_application_by_dt_potok,
  sum(ap.num_of_uniq_apps) as num_of_uniq_apps_by_dt_potok,

  sum(ch.num_of_checkins) as num_of_checkins,
  sum(ch.num_of_uniq_checkins) as num_of_uniq_checkins,
  sum(chp.num_of_checkins) as num_of_checkins_by_dt_potok,
  sum(chp.num_of_uniq_checkins) as num_of_uniq_checkins_by_dt_potok,

  sum(sp.num_of_deals) as num_of_deals_by_dt_of_payment,
  sum(sp.num_of_prepayment) as num_of_prepayment_by_dt_of_payment,
  sum(sp.num_of_succes_deals) as num_of_succes_deals_by_dt_of_payment,
  sum(sp.num_of_clean_success_deals) as num_of_clean_success_deals_by_dt_of_payment,
  sum(sp.sum_of_payment) as sum_of_payment_by_dt_of_payment,
  sum(sp.sum_of_refund) as sum_of_refund_by_dt_of_payment,
  sum(sp.sum_of_clean_payment) as sum_of_clean_payment_by_dt_of_payment,

  sum(ss.num_of_deals) as num_of_deals_by_dt_of_sale,
  sum(ss.num_of_prepayment) as num_of_prepayment_by_dt_of_sale,
  sum(ss.num_of_succes_deals) as num_of_succes_deals_by_dt_of_sale,
  sum(ss.num_of_clean_success_deals) as num_of_clean_success_deals_by_dt_of_sale,
  sum(ss.sum_of_payment) as sum_of_payment_by_dt_of_sale,
  sum(ss.sum_of_refund) as sum_of_refund_by_dt_of_sale,
  sum(ss.sum_of_clean_payment) as sum_of_clean_payment_by_dt_of_sale,

  sum(scr.num_of_deals) as num_of_deals_by_dt_create,
  sum(scr.num_of_prepayment) as num_of_prepayment_by_dt_create,
  sum(scr.num_of_succes_deals) as num_of_succes_deals_by_dt_create,
  sum(scr.num_of_clean_success_deals) as num_of_clean_success_deals_by_dt_create,
  sum(scr.sum_of_payment) as sum_of_payment_by_dt_create,
  sum(scr.sum_of_refund) as sum_of_refund_by_dt_create,
  sum(scr.sum_of_clean_payment) as sum_of_clean_payment_by_dt_create,

  sum(scl.num_of_deals) as num_of_deals_by_dt_close,
  sum(scl.num_of_prepayment) as num_of_prepayment_by_dt_close,
  sum(scl.num_of_succes_deals) as num_of_succes_deals_by_dt_close,
  sum(scl.num_of_clean_success_deals) as num_of_clean_success_deals_by_dt_close,
  sum(scl.sum_of_payment) as sum_of_payment_by_dt_close,
  sum(scl.sum_of_refund) as sum_of_refund_by_dt_close,
  sum(scl.sum_of_clean_payment) as sum_of_clean_payment_by_dt_close,

  sum(spotok.num_of_deals) as num_of_deals_by_dt_potok,
  sum(spotok.num_of_prepayment) as num_of_prepayment_by_dt_potok,
  sum(spotok.num_of_succes_deals) as num_of_succes_deals_by_dt_potok,
  sum(spotok.num_of_clean_success_deals) as num_of_clean_success_deals_by_dt_potok,
  sum(spotok.sum_of_payment) as sum_of_payment_by_dt_potok,
  sum(spotok.sum_of_refund) as sum_of_refund_by_dt_potok,
  sum(spotok.sum_of_clean_payment) as sum_of_clean_payment_by_dt_potok,

  sum(c.spend_USD) as spend_USD,
  sum(c.spend_KZT) as spend_KZT,
  sum(c.num_of_clicks) as num_of_clicks,
  sum(c.num_of_impressions) as num_of_impressions,

  sum(cpotok.spend_USD) as spend_USD_by_dt_potok,
  sum(cpotok.spend_KZT) as spend_KZT_by_dt_potok,
  sum(cpotok.num_of_clicks) as num_of_clicks_by_dt_potok,
  sum(cpotok.num_of_impressions) as num_of_impressions_by_dt_potok

from utm_dict d

left join regs r on
  r.dt = d.dt and
  r.utm_source = d.utm_source and
  r.utm_medium = d.utm_medium and
  r.utm_campaign = d.utm_campaign and
  r.utm_content = d.utm_content and
  r.utm_term = d.utm_term

left join regs_by_dt_potok rp on
  rp.dt_potok = d.dt and
  rp.utm_source = d.utm_source and
  rp.utm_medium = d.utm_medium and
  rp.utm_campaign = d.utm_campaign and
  rp.utm_content = d.utm_content and
  rp.utm_term = d.utm_term

left join applications a on
  a.application_date = d.dt and
  a.utm_source = d.utm_source and
  a.utm_medium = d.utm_medium and
  a.utm_campaign = d.utm_campaign and
  a.utm_content = d.utm_content and
  a.utm_term = d.utm_term

left join applications_by_dt_potok ap on
  ap.dt_potok = d.dt and
  ap.utm_source = d.utm_source and
  ap.utm_medium = d.utm_medium and
  ap.utm_campaign = d.utm_campaign and
  ap.utm_content = d.utm_content and
  ap.utm_term = d.utm_term

left join checkins ch on
  ch.dt_of_web = d.dt and
  ch.utm_source = d.utm_source and
  ch.utm_medium = d.utm_medium and
  ch.utm_campaign = d.utm_campaign and
  ch.utm_content = d.utm_content and
  ch.utm_term = d.utm_term

left join checkins_by_dt_potok chp on
  chp.dt_potok = d.dt and
  chp.utm_source = d.utm_source and
  chp.utm_medium = d.utm_medium and
  chp.utm_campaign = d.utm_campaign and
  chp.utm_content = d.utm_content and
  chp.utm_term = d.utm_term

left join sales_by_dt_of_payment sp on
  sp.dt_of_payment = d.dt and
  sp.utm_source = d.utm_source and
  sp.utm_medium = d.utm_medium and
  sp.utm_campaign = d.utm_campaign and
  sp.utm_content = d.utm_content and
  sp.utm_term = d.utm_term

left join sales_by_dt_of_sale ss on
  ss.dt_of_sale = d.dt and
  ss.utm_source = d.utm_source and
  ss.utm_medium = d.utm_medium and
  ss.utm_campaign = d.utm_campaign and
  ss.utm_content = d.utm_content and
  ss.utm_term = d.utm_term

left join sales_by_dt_create scr on
  scr.dt_create = d.dt and
  scr.utm_source = d.utm_source and
  scr.utm_medium = d.utm_medium and
  scr.utm_campaign = d.utm_campaign and
  scr.utm_content = d.utm_content and
  scr.utm_term = d.utm_term

left join sales_by_dt_close scl on
  scl.dt_close = d.dt and
  scl.utm_source = d.utm_source and
  scl.utm_medium = d.utm_medium and
  scl.utm_campaign = d.utm_campaign and
  scl.utm_content = d.utm_content and
  scl.utm_term = d.utm_term

left join sales_by_dt_potok spotok on
  spotok.dt_potok = d.dt and
  spotok.utm_source = d.utm_source and
  spotok.utm_medium = d.utm_medium and
  spotok.utm_campaign = d.utm_campaign and
  spotok.utm_content = d.utm_content and
  spotok.utm_term = d.utm_term

left join costs c on
  c.dt = d.dt and
  c.utm_source = d.utm_source and
  c.utm_medium = d.utm_medium and
  c.utm_campaign = d.utm_campaign and
  c.utm_content = d.utm_content and
  c.utm_term = d.utm_term

left join costs_by_dt_potok cpotok on
  cpotok.dt_potok = d.dt and
  cpotok.utm_source = d.utm_source and
  cpotok.utm_medium = d.utm_medium and
  cpotok.utm_campaign = d.utm_campaign and
  cpotok.utm_content = d.utm_content and
  cpotok.utm_term = d.utm_term

group by
  d.dt, d.utm_source, d.utm_medium, d.utm_campaign, d.utm_content, d.utm_term
),

dict_source as (select * from `beibit-499311.dicts.dict_source`)

select 
  f.*,
  d.targetolog,
  d.channel,
  d.channel_aggregated,
  d.webname
from final_table f
left join dict_source d on f.utm_source = d.utm_source
