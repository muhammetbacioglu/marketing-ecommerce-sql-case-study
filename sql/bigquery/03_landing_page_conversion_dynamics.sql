-- Landing Page Conversion Dynamics (Google BigQuery GA4 - 2020)
-- Extracts URL path via REGEXP_EXTRACT, preserves session-level integrity via
-- has_session_start flag and COALESCE fallback, and ranks entry pages by conversion.

WITH session_ozet AS (
  SELECT
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    user_pseudo_id,

    MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS has_session_start,

    MAX(CASE WHEN event_name = 'session_start' THEN
      (REGEXP_EXTRACT((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), r'https?://[^/]+(/.*)'))
      END) AS landing_page,

    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchased

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2020*`
  WHERE event_name IN ('session_start', 'purchase')
  GROUP BY session_id, user_pseudo_id
)

SELECT
  COALESCE(landing_page, '(not set)') AS landing_page,
  count(*) AS user_sessions_count,
  SUM(has_purchased) AS purchase_count,
  SAFE_DIVIDE(SUM(has_purchased), count(*)) AS conversion_rate

FROM session_ozet
WHERE has_session_start = 1
GROUP BY landing_page
ORDER BY user_sessions_count DESC;
