WITH base_metrics AS (
  SELECT 
    date,
    platform,
    account,
    campaign,
    country,
    device,
    spend,
    conversions,
    conversions * 100 as revenue,
    CASE 
      WHEN conversions > 0 THEN spend / conversions 
      ELSE NULL 
    END as cac,
    CASE 
      WHEN spend > 0 THEN (conversions * 100) / spend 
      ELSE NULL 
    END as roas
  FROM `single-cirrus-470623-c0.n8ntest.ads_spend`
)