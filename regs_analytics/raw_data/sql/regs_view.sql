with
raw_history_regs as (select * from `raw_history_regs`),
raw_webhook_regs as (select * from `webhook_regs`),

union_table as (
  select
    url,
    datetime,
    name,
    REGEXP_REPLACE(phone, r'[^0-9]', '') AS phone,
    email,
    checkbox,
    tranid,
    formid,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    referer
  from raw_webhook_regs

  UNION ALL

  select
    REGEXP_EXTRACT(referer, r'://([^/]+)') as url,
    safe_cast(created as datetime) as datetime,
    name,
    REGEXP_REPLACE(phone, r'[^0-9]', '') AS phone,
    email,
    safe_cast(checkbox as bool),
    null as tranid,
    formid,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    referer
  from raw_history_regs
),

prep as (
  select
    url as domen,
    DATETIME_ADD(`datetime`, interval 5 HOUR) as dtime_of_reg,
    CAST(DATETIME_ADD(`datetime`, interval 5 HOUR) as date) as dt,
    EXTRACT(HOUR FROM (DATETIME_ADD(`datetime`, INTERVAL 5 HOUR))) as hour_of_reg,
    DATE_TRUNC(CAST(DATETIME_ADD(`datetime`, interval 5 HOUR) AS DATE), MONTH) AS dt_first_month,
    name,
    phone,
    formid,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    REGEXP_EXTRACT(referer, r'^https?://[^/]+/([^/?#]+)') as pod_domen,
    case when `datetime` is not null then 1 else 0 end as num_of_regs
  from union_table
),

dict_regs as (select * from `dict_regs`),
dict_source as (select * from `dict_source`),

clean_and_join as (
  select 
    prep.*,
    ds.targetolog,
    ds.channel,
    ds.channel_aggregated,
    ds.webname
  from prep
  left join dict_source ds
    on prep.utm_source = ds.utm_source
  -- Убираем ненужные реги
  left join dict_regs dr
    on prep.pod_domen = dr.pod_domen
  where dr.pod_domen is null
),

dict_shifts as (
  select 
    webname,
    parse_date('%d.%m.%Y', dt_fact) as dt_fact,
    cast(time_treshold as float64) as time_treshold,
    parse_date('%d.%m.%Y', dt_reg_fake) as dt_reg_fake
  from `dict_shifts`
),

-- Для последующих расчетов сдвигов сначала считаем надо ли сдвигать для реги ее фактическую дату в след день
calc_dt_for_shifts as (
  select 
    caj.*,
    d.time_treshold,
    case 
      when d.time_treshold is not null and caj.hour_of_reg >= d.time_treshold 
      then DATE_ADD(caj.dt, INTERVAL 1 DAY) 
      else caj.dt 
    end as dt_for_shifts
  from clean_and_join caj
  left join dict_shifts d
    on caj.dt = d.dt_fact and caj.webname = d.webname
),

-- Рассчитываем дату потока. Джойним еще раз, чтобы сдвиги делать от даты для сдвигов
do_potok as (
  select
    c.*,
    d.dt_reg_fake as dt_potok
  from calc_dt_for_shifts c
  left join dict_shifts d
    on c.dt_for_shifts = d.dt_fact and c.webname = d.webname
),

-- Считаем для каждого юзера предыдущую дату регистрации
calc_prev_reg_dtime as (
  select 
    *,
    LAG(dtime_of_reg) OVER (PARTITION BY phone ORDER BY dtime_of_reg) as prev_reg_dtime  
  from do_potok
)

select 
  *,
  case 
    --Если это самая первая рега юзера в жизни (нет прошлой даты) -> уник
    when prev_reg_dtime is null then 1 
    -- Если с прошлой реги прошло 30 и более дней -> уник
    when DATETIME_DIFF(dtime_of_reg, prev_reg_dtime, DAY) >= 30 then 1 
    else null
  end as num_of_uniq_regs
from calc_prev_reg_dtime
