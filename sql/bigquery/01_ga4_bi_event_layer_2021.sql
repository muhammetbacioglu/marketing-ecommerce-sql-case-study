-- Cleaned BI Analytical Layer for 2021 GA4 E-Commerce Events (Google BigQuery)
-- Filters raw GA4 nested logs to 7 core e-commerce funnel events, converts
-- microsecond epoch timestamps, and unnests ga_session_id for BI readiness.

SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
    event_name,
    geo.country,
    device.category,
    user_pseudo_id,
    traffic_source.source,
    traffic_source.medium,
    traffic_source.name,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
WHERE event_name IN (
    'session_start',
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'add_shipping_info',
    'add_payment_info',
    'purchase'
);
