with 
vakas_apps as (
  select
    name,
    email,
    phone,
    utm_source, 
    utm_medium,
    utm_campaign, 
    utm_content, 
    utm_term,
    amo_status_name as lead_status_name, 
    amo_old_status_name as old_lead_status_name, 
    amo_rsourse as r_sourse, 
    amo_rmedium as r_medium, 
    amo_rcampaing as r_campaign, 
    amo_rcontent as r_content, 
    amo_rterm as r_term,
    `amo_tip-trafika` as tip_trafika,
    DATE(SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(`amo_data-veba` AS INT64)) AS TIMESTAMP), "Asia/Almaty") as web_date,
    amo_bsourse as b_sourse, 
    amo_bmedium as b_medium, 
    amo_bcampaing as b_campaign,
    amo_bcontent as b_content, 
    amo_bterm as b_term,
    SAFE_CAST(`amo_byl-minut--` as FLOAT64) as min_on_web,
    amo_zsourse as z_sourse,
    DATE(SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(`amo_data-ostavleniya-zayavki` AS INT64)) AS TIMESTAMP), "Asia/Almaty") as application_date,
    DATETIME(SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(`amo_data-ostavleniya-zayavki` AS INT64)) AS TIMESTAMP), "Asia/Almaty") as application_dtime,
    SAFE_CAST(amo_lead_id AS INT64) as lead_id, 
    amo_lead_name as lead_name, 
    amo_tags_text as lead_tags, 
    amo_user_name as manager,
    'vakas' as source_system
  from `raw_applications` 
  where amo_lead_id is not null
),

users as (select id, name from `beibit-499311.amo.dict_users`),
stages_pipelines as (select pipeline_id, pipeline_name, status_id, status_name from `dict_stages`),

amo_leads_with_contact AS (
  select 
    *,
    COALESCE(
      (select id from UNNEST(_embedded.contacts) WHERE is_main = true LIMIT 1),
      (select id from UNNEST(_embedded.contacts) LIMIT 1)
    ) as extracted_contact_id
  FROM `leads`
),

amo_apps as (
  select
    -- Контакты
    MAX(c.name) as name,
    MAX(c.email) as email,
    MAX(SAFE_CAST(c.phone as STRING)) as phone,
    
    -- UTM из статистики
    MAX(CASE WHEN custom_fields.field_name = 'utm_source' THEN facts.value END) as utm_source,
    MAX(CASE WHEN custom_fields.field_name = 'utm_medium' THEN facts.value END) as utm_medium,
    MAX(CASE WHEN custom_fields.field_name = 'utm_campaign' THEN facts.value END) as utm_campaign,
    MAX(CASE WHEN custom_fields.field_name = 'utm_content' THEN facts.value END) as utm_content,
    MAX(CASE WHEN custom_fields.field_name = 'utm_term' THEN facts.value END) as utm_term,
    
    -- Данные сделки
    l.id as lead_id, 
    MAX(sp.status_name) as lead_status_name,  
    MAX(l.name) as lead_name,
    MAX(u.name) as manager,
    
    -- UTM из раздела "Маркетинг"
    MAX(CASE WHEN custom_fields.field_id = 1698447 THEN facts.value END) as r_sourse, 
    MAX(CASE WHEN custom_fields.field_id = 1698451 THEN facts.value END) as r_medium, 
    MAX(CASE WHEN custom_fields.field_id = 1698453 THEN facts.value END) as r_campaign, 
    MAX(CASE WHEN custom_fields.field_id = 1698449 THEN facts.value END) as r_content, 
    MAX(CASE WHEN custom_fields.field_id = 1698455 THEN facts.value END) as r_term,
    MAX(CASE WHEN custom_fields.field_id = 1893315 THEN facts.value END) as tip_trafika,
    MAX(DATE(CASE WHEN custom_fields.field_id = 1698443 THEN SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(facts.value AS INT64)) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty")) as web_date, 
    MAX(CASE WHEN custom_fields.field_id = 1698463 THEN facts.value END) as b_sourse, 
    MAX(CASE WHEN custom_fields.field_id = 1698775 THEN facts.value END) as b_medium, 
    MAX(CASE WHEN custom_fields.field_id = 1698467 THEN facts.value END) as b_campaign,
    MAX(CASE WHEN custom_fields.field_id = 1698465 THEN facts.value END) as b_content, 
    MAX(CASE WHEN custom_fields.field_id = 1698517 THEN facts.value END) as b_term,
    MAX(CASE WHEN custom_fields.field_id = 1698569 THEN facts.value END) as z_sourse,

    -- Дата заявки
    MAX(DATE(CASE WHEN custom_fields.field_id = 1738385 THEN SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(facts.value AS INT64)) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty")) as application_date,
    MAX(DATETIME(CASE WHEN custom_fields.field_id = 1738385 THEN SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(facts.value AS INT64)) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty")) as application_dtime,

    MAX(CASE WHEN custom_fields.field_id = 1738383 THEN SAFE_CAST(facts.value as FLOAT64) END) as min_on_web,

    -- Заглушки 
    CAST(NULL AS STRING) AS old_lead_status_name,
    CAST(NULL AS STRING) AS lead_tags,       

    'amo' as source_system
    
  from amo_leads_with_contact l
  left join UNNEST(l.custom_fields_values) AS custom_fields
  left join UNNEST(custom_fields.values) AS facts
  left join `dict_contacts` c ON l.extracted_contact_id = c.contact_id
  left join users as u on l.responsible_user_id = u.id
  left join stages_pipelines as sp on sp.pipeline_id = l.pipeline_id and sp.status_id = l.status_id
  group by l.id
),

union_table as (
  select * from vakas_apps
    where application_date is not null
  UNION ALL BY NAME
  select * from amo_apps
    where application_date is not null and application_date <'2026-07-27'
),

pred_final as (
  select
    u.*,
    1 as num_of_apps,
    case when min_on_web > 0 then 1 else null end as num_of_apps_visit_web,
    case when lead_status_name = "Успешно реализовано" then 1 else null end as num_of_succes_apps,
    d.targetolog,
    d.channel,
    d.channel_aggregated,
    d.webname
  from union_table u
  left join `dict_source` d
  on u.utm_source = d.utm_source
),

do_potok as (
  select 
    *,
    application_date as dt_potok
  from pred_final
),

-- Считаем для каждого юзера предыдущую дату заявки
calc_prev_app_dtime as (
  select 
    *,
    LAG(application_dtime) OVER (PARTITION BY phone ORDER BY application_dtime) as prev_app_dtime  
  from do_potok
)

select 
  *,
  case 
    --Если это самая первая заявка юзера в жизни (нет прошлой даты) -> уник
    when prev_app_dtime is null then 1 
    -- Если с прошлой заявки прошло 30 и более дней -> уник
    when DATETIME_DIFF(application_dtime, prev_app_dtime, DAY) >= 30 then 1 
    else null
  end as num_of_uniq_apps
from calc_prev_app_dtime


