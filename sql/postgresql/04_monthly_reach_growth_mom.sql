-- Largest Month-over-Month Campaign Reach Expansion (PostgreSQL)
-- Aggregates monthly reach per campaign across channels and applies LAG()
-- window partitioning to isolate the single steepest MoM growth spike.

WITH combined_4 AS (
    SELECT f.ad_date, c.campaign_name, f.reach
    FROM facebook_ads_basic_daily f
    LEFT JOIN facebook_campaign c ON f.campaign_id = c.campaign_id

    UNION ALL

    SELECT ad_date, campaign_name, reach
    FROM google_ads_basic_daily
), monthly AS (
    SELECT
        DATE_TRUNC('month', ad_date)::date AS ad_month,
        campaign_name,
        SUM(reach) AS monthly_reach
    FROM combined_4
    GROUP BY DATE_TRUNC('month', ad_date)::date, campaign_name
)
SELECT
    ad_month,
    campaign_name,
    monthly_reach,
    monthly_reach - LAG(monthly_reach) OVER (PARTITION BY campaign_name ORDER BY ad_month) AS monthly_growth
FROM monthly
ORDER BY monthly_growth DESC NULLS LAST
LIMIT 1;
