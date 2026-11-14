-- Top 5 Peak Daily ROMI Dates Across Channels (PostgreSQL)
-- Aggregates combined spend and conversion value across Facebook and Google Ads
-- with safe division (NULLIF) and zero-null handling (COALESCE).

WITH combined_2 AS (
    SELECT ad_date, spend, value
    FROM facebook_ads_basic_daily

    UNION ALL

    SELECT ad_date, spend, value
    FROM google_ads_basic_daily
)
SELECT ad_date,
       1.00 * COALESCE(SUM(value), 0) / NULLIF(SUM(spend), 0) AS romi
FROM combined_2
GROUP BY ad_date
ORDER BY romi DESC NULLS LAST
LIMIT 5;
