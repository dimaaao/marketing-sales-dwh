WITH raw_data AS (
  SELECT *, 'Однодневник' as day_of_web FROM `raw_checkins`
  -- Дальше дописывать в uninon когда появятся новые дни
),

cleaned AS (
  select
    * EXCEPT (webinar_date, watch_start_time, watch_end_time, watched_to_end),
    SAFE.PARSE_DATE('%d.%m.%Y', webinar_date) AS dt_of_web,
    CAST(SPLIT(webroom_id, ':')[OFFSET(0)] AS INT64) AS bizon_id,
    SPLIT(SPLIT(webroom_id, ':')[OFFSET(1)], '*')[OFFSET(0)] AS bizon_webroom,
    SAFE.PARSE_DATETIME('%d.%m.%Y %H:%M', watch_start_time) AS start_dtime,
    SAFE.PARSE_DATETIME('%d.%m.%Y %H:%M', watch_end_time) AS end_dtime,
    SAFE_CAST(watched_to_end as INT64) as watched_to_end,
    1 AS num_of_checkins,

  from raw_data
),

pop_bad_dates as (
  select
    * except(end_dtime),
    case when end_dtime < '2026-01-01' then null else end_dtime end as end_dtime
  from cleaned
),

dict_source as (select * from `dict_source`),

pred_final as (
  select 
    pbd.*,
    DATETIME_DIFF(pbd.end_dtime, pbd.start_dtime, MINUTE) AS minutes_on_web,
    d.targetolog,
    d.channel,
    d.channel_aggregated,
    d.webname
  from pop_bad_dates pbd
  left join dict_source d
   on pbd.utm_source = d.utm_source
),

do_potok as (
  select 
    *,
    -- Дописывать сюда, когда появятся новые дни
    case
      when day_of_web = 'Однодневник' then dt_of_web
    else null end as dt_potok
  from pred_final
),

-- Считаем для каждого юзера предыдущую дату регистрации
calc_prev_checkin_dtime as (
  select 
    *,
    LAG(start_dtime) OVER (PARTITION BY phone ORDER BY start_dtime) as prev_checkin_dtime
  from do_potok
)

select 
  *,
  case 
    --Если это самая первая рега юзера в жизни (нет прошлой даты) -> уник
    when prev_checkin_dtime is null then 1 
    -- Если с прошлой реги прошло 30 и более дней -> уник
    when DATETIME_DIFF(start_dtime, prev_checkin_dtime, DAY) >= 30 then 1 
    else null
  end as num_of_uniq_checkins
from calc_prev_checkin_dtime
