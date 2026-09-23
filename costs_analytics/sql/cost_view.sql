with prep_fb as (select
account_id,
account_name,
ad_id,
ad_name,
adset_name,
campaign_id,
campaign_name,
creative_id,
mechanic_primary,
mechanic_result,
mechanic_reason,
lead_form_name,
utms,
destination_url,
image_url,
image_hash,
video_id,
cast(date_start as date) as dt,
safe_cast(spend as float64) as spend_USD,
safe_cast(impressions as float64) as impressions,
safe_cast(clicks as float64) as clicks,
case when utm_source='' then null else utm_source end as utm_source,
case when utm_medium='' then null else utm_medium end as utm_medium,
case when utm_campaign='' then null else utm_campaign end as utm_campaign,
case when utm_content='' then null else utm_content end as utm_content,
case when utm_term='' then null else utm_term end as utm_term,
  REGEXP_EXTRACT(destination_URL, r'https?://([^/]+)') as domen,   -- Домен (host)
  REGEXP_EXTRACT(destination_URL, r'https?://[^/]+/([^/?#]+)') as pod_domen -- под-домен
from  `raw_v2_beibit_costs`
WHERE campaign_id NOT IN ('120246717216810381', '120248147267540381', '120256921705850001', '120256943871020001', '120246184856480752', '120247123889440752', '120248623602570522', '120248971849950522', '120249382482450522', '120248634368780162', '120248203107490162', '120248204575580162') OR campaign_id IS NULL -- Не попада строка которую мы искусственно добавили
),

prep_ga as (
select
account_id,
account_name,
ad_id,
"null" as ad_name,
"null" as adset_name,
"null" as campaign_id,
"null" as campaign_name,
"null" as creative_id,
"null" as mechanic_primary,
"null" as mechanic_result,
"null" as mechanic_reason,
"null" as lead_form_name,
"null" as utms,
destination_url,
image_url,
"null" as image_hash,
"null" as video_id,
cast(date as date) as dt,
safe_cast(spend as float64) as spend_USD,
safe_cast(impressions as float64) as impressions,
safe_cast(clicks as float64) as clicks,
case when utm_source='' then null else utm_source end as utm_source,
case when utm_medium='' then null else utm_medium end as utm_medium,
case when utm_campaign='' then null else utm_campaign end as utm_campaign,
case when utm_content='' then null else utm_content end as utm_content,
case when utm_term='' then null else utm_term end as utm_term,
  REGEXP_EXTRACT(destination_URL, r'https?://([^/]+)') as domen,   -- Домен (host)
  REGEXP_EXTRACT(destination_URL, r'https?://[^/]+/([^/?#]+)') as pod_domen -- под-домен
from `raw_gads_beibit_costs`
),

united_data as (
select * from prep_fb
Union ALL
select * from prep_ga
),

curr_conv as (
select
  date as dt,
  max(rate) as rate
from currencies_convertation
where base_currency='USD' and target_currency='KZT' and date>='2025-08-01'
group by 1
),

dict_accounts as (select * from `dict_accounts`), -- подгружаю справочник акков чтобы подставить utm_source тем кто ее потерял

utm_dict_source as (select * from `dict_source`), --каналы,источники,таргетологи

spend_normalized as (select
p.* except (utm_source, spend_USD),
-- Костыль для конвертации валют (таргетолог запустил каб с дерхамах)
case when p.account_id in ('896912175630720', '646780393572025') then p.spend_USD * 0.2723 else p.spend_USD end as spend_USD,
case when p.account_id in ('896912175630720', '646780393572025') then (p.spend_USD * 0.2723) * c.rate else p.spend_USD*c.rate end as spend_KZT,
coalesce(p.utm_source,utm_source_reserv) as utm_source
from united_data as p
left join curr_conv as c on c.dt=p.dt
left join dict_accounts as d on d.account_id=p.account_id
),

spend_with_utm as (
  select 
    sn.*,
    us.targetolog,
    us.channel,
    us.channel_aggregated,
    us.webname
  from spend_normalized as sn
  left join utm_dict_source us on us.utm_source=sn.utm_source
),

dict_shifts as (
select 
webname,
parse_date('%d.%m.%Y',dt_fact) as dt_fact,
cast(time_treshold as float64) as time_treshold,
parse_date('%d.%m.%Y',dt_reg_fake) as dt_reg_fake,
from `dict_shifts`)


select
  swu.*,
  d.dt_reg_fake as dt_potok
from spend_with_utm swu
left join dict_shifts d
  on swu.dt = d.dt_fact and swu.webname = d.webname



  
