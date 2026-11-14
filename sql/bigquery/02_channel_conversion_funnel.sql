-- Traffic Channel & Daily Conversion Funnel (Google BigQuery GA4)
-- Deduplicates sessions using composite key (ga_session_id + user_pseudo_id)
-- and tracks conversion rates from session_start to cart, checkout, and purchase.

SELECT
  event_date,
  traffic_source.source AS source,
  traffic_source.medium AS medium,
  traffic_source.name AS campaign,

  COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN CONCAT(
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
    user_pseudo_id
  ) END) AS user_sessions_count,

  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN CONCAT(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      user_pseudo_id
    ) END),
    COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN CONCAT(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      user_pseudo_id
    ) END)
  ) AS visit_to_cart,

  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN CONCAT(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      user_pseudo_id
    ) END),
    COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN CONCAT(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      user_pseudo_id
    ) END)
  ) AS visit_to_checkout,

  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN CONCAT(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      user_pseudo_id
    ) END),
    COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN CONCAT(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      user_pseudo_id
    ) END)
  ) AS visit_to_purchase
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
WHERE event_name IN ('session_start', 'add_to_cart', 'begin_checkout', 'purchase')
GROUP BY event_date, source, medium, campaign;
