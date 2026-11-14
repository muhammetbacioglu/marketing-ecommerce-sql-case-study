-- Highest Weekly Conversion Value Campaign (PostgreSQL)
-- Enriches Facebook Ads facts with campaign metadata via LEFT JOIN,
-- unions with Google Ads, and identifies the top campaign-week by total value.

WITH combined_3 AS (
    SELECT f.ad_date, c.campaign_name, f.value
    FROM facebook_ads_basic_daily f
    LEFT JOIN facebook_campaign c ON f.campaign_id = c.campaign_id

    UNION ALL

    SELECT ad_date, campaign_name, value
    FROM google_ads_basic_daily
)
SELECT
    DATE_TRUNC('week', ad_date)::date AS week_start,
    campaign_name,
    SUM(value) AS weekly_value
FROM combined_3
GROUP BY week_start, campaign_name
ORDER BY weekly_value DESC NULLS LAST
LIMIT 1;
