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
),

date_ranges AS (
  SELECT 
    *,
    CASE 
      -- Last 30 days: June 1-30, 2025
      WHEN date >= '2025-06-01' AND date <= '2025-06-30' THEN 'last_30_days'
      -- Prior 30 days: May 2-31, 2025
      WHEN date >= '2025-05-02' AND date <= '2025-05-31' THEN 'prior_30_days'
      ELSE 'other'
    END as period
  FROM base_metrics
),

aggregated_metrics AS (
  SELECT 
    period,
    SUM(spend) as total_spend,
    SUM(conversions) as total_conversions,
    SUM(revenue) as total_revenue,
    CASE 
      WHEN SUM(conversions) > 0 THEN SUM(spend) / SUM(conversions)
      ELSE NULL 
    END as overall_cac,
    CASE 
      WHEN SUM(spend) > 0 THEN SUM(revenue) / SUM(spend)
      ELSE NULL 
    END as overall_roas
  FROM date_ranges
  WHERE period IN ('last_30_days', 'prior_30_days')
  GROUP BY period
)

SELECT 
  'CAC' as metric,
  ROUND(last.overall_cac, 2) as last_30_days,
  ROUND(prior.overall_cac, 2) as prior_30_days,
  ROUND(last.overall_cac - prior.overall_cac, 2) as absolute_change,
  ROUND((last.overall_cac - prior.overall_cac) / prior.overall_cac * 100, 2) as percent_change

FROM 
  (SELECT * FROM aggregated_metrics WHERE period = 'last_30_days') last
CROSS JOIN 
  (SELECT * FROM aggregated_metrics WHERE period = 'prior_30_days') prior

UNION ALL

SELECT 
  'ROAS' as metric,
  ROUND(last.overall_roas, 2) as last_30_days,
  ROUND(prior.overall_roas, 2) as prior_30_days,
  ROUND(last.overall_roas - prior.overall_roas, 2) as absolute_change,
  ROUND((last.overall_roas - prior.overall_roas) / prior.overall_roas * 100, 2) as percent_change

FROM 
  (SELECT * FROM aggregated_metrics WHERE period = 'last_30_days') last
CROSS JOIN 
  (SELECT * FROM aggregated_metrics WHERE period = 'prior_30_days') prior;