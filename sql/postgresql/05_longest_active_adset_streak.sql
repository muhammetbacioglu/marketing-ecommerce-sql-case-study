-- Longest Continuous Active Adset Streak (PostgreSQL)
-- Solves the classic Gaps-and-Islands problem across Facebook & Google Ads
-- using daily deduplication, ROW_NUMBER(), and date-offset grouping.

WITH combined_5 AS (
    SELECT f.ad_date, a.adset_name
    FROM facebook_ads_basic_daily f
    LEFT JOIN facebook_adset a ON f.adset_id = a.adset_id

    UNION ALL

    SELECT ad_date, adset_name
    FROM google_ads_basic_daily
),
daily AS (
    SELECT ad_date, adset_name
    FROM combined_5
    GROUP BY ad_date, adset_name
),
numbered AS (
    SELECT
        ad_date,
        adset_name,
        ROW_NUMBER() OVER (PARTITION BY adset_name ORDER BY ad_date) AS rn
    FROM daily
),
streak_groups AS (
    SELECT
        ad_date,
        adset_name,
        ad_date - (rn * interval '1 day') AS streak_group
    FROM numbered
)
SELECT
    adset_name,
    MIN(ad_date) AS streak_start,
    MAX(ad_date) AS streak_end,
    COUNT(*) AS streak_length
FROM streak_groups
GROUP BY adset_name, streak_group
ORDER BY streak_length DESC
LIMIT 1;
