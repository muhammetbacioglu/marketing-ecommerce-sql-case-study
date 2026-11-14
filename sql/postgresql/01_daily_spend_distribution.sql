-- Daily Ad Spend Distribution by Channel (PostgreSQL)
-- Combines Facebook Ads and Google Ads daily records via UNION ALL
-- and summarizes average, peak, and minimum daily spend per media source.

WITH combined AS (
    SELECT ad_date, 'Facebook' AS media_source, spend
    FROM facebook_ads_basic_daily

    UNION ALL

    SELECT ad_date, 'Google' AS media_source, spend
    FROM google_ads_basic_daily
)
SELECT ad_date,
       media_source,
       AVG(spend) AS avg_spend,
       MAX(spend) AS max_spend,
       MIN(spend) AS min_spend
FROM combined
GROUP BY ad_date, media_source;
