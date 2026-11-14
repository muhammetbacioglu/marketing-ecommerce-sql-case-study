-- Behavioral Engagement vs. Purchase Correlation (Google BigQuery GA4 - 2020)
-- Aggregates session_engaged flag and total engagement_time_msec per unique session,
-- computing Pearson correlation (CORR) against completed purchase events.

WITH session_ozet AS (
  SELECT
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    user_pseudo_id,

    COALESCE(MAX(CAST(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged')
    AS INT64 )), 0) AS is_engaged,

    COALESCE(SUM(
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')), 0) AS total_engagement_time,

    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchased

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2020*`
  GROUP BY session_id, user_pseudo_id
)
SELECT
  CORR(is_engaged, has_purchased) AS corr_engaged_vs_purchase,
  CORR(total_engagement_time, has_purchased) AS corr_duration_vs_purchase
FROM session_ozet;
