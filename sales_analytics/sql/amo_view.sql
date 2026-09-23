with users as (select id, name from `dict_users`),
stages_pipelines as (select pipeline_id, pipeline_name, status_id, status_name from `dict_stages`),

  -- Достаем contact_id для всех сделок
leads_with_contact as (
  select 
    *,
    COALESCE(
      (SELECT id FROM UNNEST(_embedded.contacts) WHERE is_main = true LIMIT 1),
      (SELECT id FROM UNNEST(_embedded.contacts) LIMIT 1)
    ) as extracted_contact_id
  from `leads`
),

  -- Находим дату первой сделки по каждому contact_id
contact_first_deal as (
  select 
    extracted_contact_id as contact_id, 
    MIN(DATE(CASE WHEN created_at BETWEEN 0 AND 253402300799 THEN SAFE_CAST(TIMESTAMP_SECONDS(created_at) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty")) as first_deal_date
  from leads_with_contact
  where extracted_contact_id is not null
  group by contact_id
),

  -- Достаем дату создания самого контакта из справочника
contacts_info as (
  select 
    contact_id,
    name as contact_name,
    DATE(CASE WHEN created_at BETWEEN 0 AND 253402300799 THEN SAFE_CAST(TIMESTAMP_SECONDS(created_at) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty") as contact_created_date
  from `dict_contacts`
),

showcase as (
  select
    --- О сделке
    a.id,
    a.extracted_contact_id as contact_id,
    a.responsible_user_id,
    DATE(CASE WHEN a.closed_at BETWEEN 0 AND 253402300799 THEN SAFE_CAST(TIMESTAMP_SECONDS(a.closed_at) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty") AS dt_close,
    DATE(CASE WHEN a.created_at BETWEEN 0 AND 253402300799 THEN SAFE_CAST(TIMESTAMP_SECONDS(a.created_at) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty") AS dt_create,
    a.price,
    a.status_id,
    a.pipeline_id,
    u.name as manager,
    sp.pipeline_name,
    sp.status_name,
    
    --- Дата контакта для расчета цикла 
    COALESCE(c.contact_created_date, cfd.first_deal_date) AS contact_base_date,
    c.contact_name,

    --- Заявки
    MAX(DATE(CASE WHEN custom_fields.field_id = 1738385 THEN SAFE_CAST(TIMESTAMP_SECONDS(SAFE_CAST(facts.value AS INT64)) AS TIMESTAMP) ELSE NULL END, "Asia/Almaty")) AS application_date,

    --- Тариф
    MAX(CASE WHEN custom_fields.field_id = 1739561 THEN facts.value END) AS tariff,

    --- Платежи
    MAX(CASE WHEN custom_fields.field_id = 1891199 THEN facts.value END) AS prepayment_date,
    MAX(CASE WHEN custom_fields.field_id = 1891201 THEN facts.value END) AS prepayment_sum,
    MAX(CASE WHEN custom_fields.field_id = 1891203 THEN facts.value END) AS prepayment_payment_method,
    MAX(CASE WHEN custom_fields.field_id = 1907415 THEN facts.value END) AS prepayment_time,
    MAX(CASE WHEN custom_fields.field_id = 1891207 THEN facts.value END) AS first_transh_date,
    MAX(CASE WHEN custom_fields.field_id = 1891209 THEN facts.value END) AS first_transh_sum,
    MAX(CASE WHEN custom_fields.field_id = 1891211 THEN facts.value END) AS first_transh_payment_method,
    MAX(CASE WHEN custom_fields.field_id = 1907039 THEN facts.value END) AS first_transh_time,
    MAX(CASE WHEN custom_fields.field_id = 1891215 THEN facts.value END) AS second_transh_date,
    MAX(CASE WHEN custom_fields.field_id = 1891217 THEN facts.value END) AS second_transh_sum,
    MAX(CASE WHEN custom_fields.field_id = 1891219 THEN facts.value END) AS second_transh_payment_method,
    MAX(CASE WHEN custom_fields.field_id = 1907041 THEN facts.value END) AS second_transh_time,
    MAX(CASE WHEN custom_fields.field_id = 1891223 THEN facts.value END) AS refund_transh_date,
    MAX(CASE WHEN custom_fields.field_id = 1891225 THEN facts.value END) AS refund_transh_sum,
    MAX(CASE WHEN custom_fields.field_id = 1891227 THEN facts.value END) AS refund_transh_payment_method,
    MAX(CASE WHEN custom_fields.field_id = 1907043 THEN facts.value END) AS refund_transh_time,

    --- Метки

    -- Из раздела маркетинг
    MAX(CASE WHEN custom_fields.field_id = 1698447 THEN facts.value END) AS r_source,
    MAX(CASE WHEN custom_fields.field_id = 1698451 THEN facts.value END) AS r_medium,
    MAX(CASE WHEN custom_fields.field_id = 1698453 THEN facts.value END) AS r_campaign,
    MAX(CASE WHEN custom_fields.field_id = 1698455 THEN facts.value END) AS r_term,
    MAX(CASE WHEN custom_fields.field_id = 1698449 THEN facts.value END) AS r_content,

    -- Из раздела статистика
    MAX(CASE WHEN custom_fields.field_name = 'utm_source' THEN facts.value END) AS stat_source,
    MAX(CASE WHEN custom_fields.field_name = 'utm_medium' THEN facts.value END) AS stat_medium,
    MAX(CASE WHEN custom_fields.field_name = 'utm_campaign' THEN facts.value END) AS stat_campaign,
    MAX(CASE WHEN custom_fields.field_name = 'utm_term' THEN facts.value END) AS stat_term,
    MAX(CASE WHEN custom_fields.field_name = 'utm_content' THEN facts.value END) AS stat_content

  from leads_with_contact a
    left join UNNEST(a.custom_fields_values) AS custom_fields
    left join UNNEST(custom_fields.values) AS facts
    left join users as u on a.responsible_user_id = u.id
    left join stages_pipelines as sp on sp.pipeline_id = a.pipeline_id and sp.status_id = a.status_id
    left join contacts_info as c on a.extracted_contact_id = c.contact_id
    left join contact_first_deal as cfd on a.extracted_contact_id = cfd.contact_id

group by
    a.id,
    a.extracted_contact_id,
    c.contact_name,
    a.responsible_user_id, 
    dt_close, 
    dt_create,
    a.price, 
    a.status_id, 
    a.pipeline_id, 
    u.name,
    sp.pipeline_name,
    sp.status_name,
    contact_base_date
),

selection_utms as (
  select
    * except(r_source, r_medium, r_campaign, r_term, r_content, stat_source, stat_medium, stat_campaign, stat_term, stat_content),
    
    -- Если r_source заполнен, забираем всю группу R, иначе берем группу STAT
    CASE WHEN r_source IS NOT NULL THEN r_source ELSE stat_source END AS utm_source,
    CASE WHEN r_source IS NOT NULL THEN r_medium ELSE stat_medium END AS utm_medium,
    CASE WHEN r_source IS NOT NULL THEN r_campaign ELSE stat_campaign END AS utm_campaign,
    CASE WHEN r_source IS NOT NULL THEN r_term ELSE stat_term END AS utm_term,
    CASE WHEN r_source IS NOT NULL THEN r_content ELSE stat_content END AS utm_content,
    
  from showcase
),

--- Делим на транши
divide_transh as (
  select
    * except(prepayment_date, prepayment_sum, prepayment_payment_method, 
      first_transh_date, first_transh_sum, first_transh_payment_method, 
      second_transh_date, second_transh_sum, second_transh_payment_method,
      refund_transh_date, refund_transh_sum, refund_transh_payment_method, 
      prepayment_time, first_transh_time, second_transh_time, refund_transh_time),

    DATE(TIMESTAMP_SECONDS(SAFE_CAST(prepayment_date AS INT64)), "Asia/Almaty") as dt_of_payment,
    DATE(TIMESTAMP_SECONDS(SAFE_CAST(first_transh_date AS INT64)), "Asia/Almaty") as dt_of_sale,
    SAFE_CAST(prepayment_sum AS INT64) as sum_of_payment, 
    0 as sum_of_refund,
    prepayment_payment_method as payment_method,
    prepayment_time as time_of_payment,
    "Предоплата" as rn_of_payment, 
    1 as num_of_deals,
    1 as num_of_prepayment
  from selection_utms
    where prepayment_date is not null

  UNION ALL

  select
    * except(prepayment_date, prepayment_sum, prepayment_payment_method, 
      first_transh_date, first_transh_sum, first_transh_payment_method, 
      second_transh_date, second_transh_sum, second_transh_payment_method,
      refund_transh_date, refund_transh_sum, refund_transh_payment_method,
      prepayment_time, first_transh_time, second_transh_time, refund_transh_time),

    DATE(TIMESTAMP_SECONDS(SAFE_CAST(first_transh_date AS INT64)), "Asia/Almaty") as dt_of_payment,
    DATE(TIMESTAMP_SECONDS(SAFE_CAST(first_transh_date AS INT64)), "Asia/Almaty") as dt_of_sale,
    SAFE_CAST(first_transh_sum AS INT64) as sum_of_payment, 
    0 as sum_of_refund,
    first_transh_payment_method as payment_method,
    first_transh_time as time_of_payment,
    "1 Транш" as rn_of_payment,
    --- если предоплаты не было, считаем сделку здесь
    case when prepayment_date is null then 1 else null end as num_of_deals,  
    null as num_of_prepayment
  from selection_utms
    where first_transh_date is not null

  UNION ALL

  select
    * except(prepayment_date, prepayment_sum, prepayment_payment_method, 
      first_transh_date, first_transh_sum, first_transh_payment_method, 
      second_transh_date, second_transh_sum, second_transh_payment_method,
      refund_transh_date, refund_transh_sum, refund_transh_payment_method,
      prepayment_time, first_transh_time, second_transh_time, refund_transh_time),

    DATE(TIMESTAMP_SECONDS(SAFE_CAST(second_transh_date AS INT64)), "Asia/Almaty") as dt_of_payment,
    DATE(TIMESTAMP_SECONDS(SAFE_CAST(first_transh_date AS INT64)), "Asia/Almaty") as dt_of_sale,
    SAFE_CAST(second_transh_sum AS INT64) as sum_of_payment, 
    0 as sum_of_refund,
    second_transh_payment_method as payment_method,
    second_transh_time as time_of_payment,
    "2 Транш" as rn_of_payment,
    null as num_of_deals,
    null as num_of_prepayment
  from selection_utms
    where second_transh_date is not null

  UNION ALL

  select
    * except(prepayment_date, prepayment_sum, prepayment_payment_method, 
      first_transh_date, first_transh_sum, first_transh_payment_method, 
      second_transh_date, second_transh_sum, second_transh_payment_method,
      refund_transh_date, refund_transh_sum, refund_transh_payment_method,
      prepayment_time, first_transh_time, second_transh_time, refund_transh_time),

    DATE(TIMESTAMP_SECONDS(SAFE_CAST(refund_transh_date AS INT64)), "Asia/Almaty") as dt_of_payment,
    DATE(TIMESTAMP_SECONDS(SAFE_CAST(first_transh_date AS INT64)), "Asia/Almaty") as dt_of_sale,
    0 as sum_of_payment,
    SAFE_CAST(refund_transh_sum AS INT64) as sum_of_refund, 
    refund_transh_payment_method as payment_method,
    refund_transh_time as time_of_payment,
    "Возврат" as rn_of_payment,
    null as num_of_deals,
    null as num_of_prepayment
  from selection_utms
    where refund_transh_date is not null

  UNION ALL

  select
    * except(prepayment_date, prepayment_sum, prepayment_payment_method, 
      first_transh_date, first_transh_sum, first_transh_payment_method, 
      second_transh_date, second_transh_sum, second_transh_payment_method,
      refund_transh_date, refund_transh_sum, refund_transh_payment_method,
      prepayment_time, first_transh_time, second_transh_time, refund_transh_time),

    null as dt_of_payment,
    null as dt_of_sale,
    null as sum_of_payment, 
    null as sum_of_refund,
    null as payment_method,
    null as time_of_payment,
    null as rn_of_payment,
    1 as num_of_deals,
    null as num_of_prepayment
  from selection_utms
    where prepayment_date is null AND first_transh_date is null AND second_transh_date is null AND refund_transh_date is null
),

dict_commissions as (
  select
    payment_method,
    safe_cast(commission as FLOAT64) as commission,
    safe_cast(dt_start as DATE) as dt_start,
    safe_cast(dt_end as DATE) as dt_end,
  from `dict_commissions`
),

-- Приджойниваем справочник комиссий 
join_commission as (
  select
    dt.*,
    dc.commission
  from divide_transh dt
  left join dict_commissions dc
    on dt.payment_method = dc.payment_method and dt.dt_of_payment BETWEEN dc.dt_start and dc.dt_end
),

-- Расчитываем комиссии
commission_calculation as (
  select
    *,
    case when commission is not null then sum_of_payment * (1 - commission / 100) else sum_of_payment end as sum_of_payment_with_commission,
    case when commission is not null then sum_of_refund * (1 - commission/ 100) else sum_of_refund end as sum_of_refund_with_commission
  from join_commission 
),

-- Справочник меток
dict_source as (select * from `dicts.dict_source`),

pred_final as (
  select 
    c.*,
    -- Считаем цикл для каждой сделки 
    case when num_of_deals = 1 then DATE_DIFF(dt_close, contact_base_date, DAY) else null end as deal_cycle_days,
    -- Продажи
    case when rn_of_payment = '1 Транш' and sum_of_payment is not null then 1 else null end as num_of_succes_deals,
    -- Сделка с заявкой
    case when application_date is not null then 'Да' else 'Нет' end as application_flag,
    -- Чистые продажи 
    case 
      when rn_of_payment = '1 Транш' and sum_of_payment is not null 
      -- Считаем общую сумму всех оплат по сделке и общую сумму всех возвратов
      and SUM(sum_of_payment) OVER (PARTITION BY id) > SUM(sum_of_refund) OVER (PARTITION BY id)
    then 1 else null 
  end as num_of_clean_success_deals,
    --Сумма без возвратов
    (sum_of_payment - sum_of_refund) as sum_of_clean_payment,
    -- Выручка
    (sum_of_payment_with_commission - sum_of_refund_with_commission) as sum_of_revenue,
    -- Кол-во сделок с заявками
    case when application_date is not null and num_of_deals = 1 then 1 else null end as num_of_application,  
    d.targetolog,
    d.channel,
    d.channel_aggregated,
    d.webname
  from commission_calculation c 
  left join dict_source d on c.utm_source = d.utm_source
),

-- Справочник сдвигов
dict_shifts as (
  select 
    webname,
    parse_date('%d.%m.%Y',dt_fact) as dt_fact,
    cast(time_treshold as float64) as time_treshold,
    parse_date('%d.%m.%Y',dt_reg_fake) as dt_reg_fake,
  from `dicts.dict_shifts`
)

-- Приджойниваем справочник сдвигов. Достаем дату потока по правилу рег 
select
  p.*,
  d.dt_reg_fake as dt_potok
from pred_final p
left join dict_shifts d
  on p.dt_create = d.dt_fact and p.webname = d.webname

