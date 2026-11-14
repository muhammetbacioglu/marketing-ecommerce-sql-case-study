# SQL Methodology & Data Engineering Notes

This document details the relational modeling patterns, BigQuery nested schema handling, and data integrity safeguards applied across both SQL engines in this case study.

---

## 1. PostgreSQL Paid Media Modeling (`sql/postgresql/`)

### Cross-Channel Schema Harmonization
- **Fact & Dimension Tables:** Combines `facebook_ads_basic_daily` and `google_ads_basic_daily` with supporting Meta dimension tables (`facebook_campaign`, `facebook_adset`).
- **Join Integrity:** Uses `LEFT JOIN` exclusively when enriching `facebook_ads_basic_daily` with campaign or adset metadata to prevent dropping spend/value records that lack complete dimension attributes.
- **Channel Unification:** Standardizes common schema columns (`ad_date`, `campaign_name` / `adset_name`, `spend`, `value`, `reach`) inside Common Table Expressions (`WITH ... UNION ALL`) before downstream aggregation.

### Window Functions & Analytical Techniques
- **Safe Ratio Division (`02_top_romi_days.sql`):**
  - `1.00 * COALESCE(SUM(value), 0) / NULLIF(SUM(spend), 0) AS romi`
  - Protects against integer division truncation (`1.00 *`) and zero-spend division errors (`NULLIF`).
- **Month-over-Month Growth (`04_monthly_reach_growth_mom.sql`):**
  - Truncates dates via `DATE_TRUNC('month', ad_date)::date` and uses `LAG(monthly_reach) OVER (PARTITION BY campaign_name ORDER BY ad_month)` to compute exact absolute MoM reach expansion (`+4,266,575` for *Hobbies* in April 2022).
- **Gaps-and-Islands Streak Detection (`05_longest_active_adset_streak.sql`):**
  1. Deduplicates multiple daily platform rows per adset (`GROUP BY ad_date, adset_name`).
  2. Assigns sequential row numbers per adset (`ROW_NUMBER() OVER (PARTITION BY adset_name ORDER BY ad_date)`).
  3. Subtracts `rn * interval '1 day'` from `ad_date` so consecutive active days collapse into a constant anchor date (`streak_group`).
  4. Aggregates per `streak_group` to surface `Narrow`'s uninterrupted `108`-day run (`2021-05-17` to `2021-09-01`).

---

## 2. Google BigQuery GA4 Event Analytics (`sql/bigquery/`)

### Flattening Nested `event_params` via `UNNEST()`
- Public GA4 datasets store custom parameters (`ga_session_id`, `page_location`, `session_engaged`, `engagement_time_msec`) as repeated nested key-value structs inside `event_params`.
- Scalar subqueries `(SELECT value.int_value FROM UNNEST(event_params) WHERE key = ...)` extract typed parameters cleanly at query time without exploding row counts across unrelated event parameters.

### Session Deduplication Across Users
- In GA4 public exports, `ga_session_id` (Unix timestamp of session start) is **not globally unique** across different visitors.
- Every funnel and session-level model explicitly pairs **`user_pseudo_id` + `session_id`** (via `CONCAT(...)` in `02_channel_conversion_funnel.sql` and composite `GROUP BY session_id, user_pseudo_id` in `03` and `04`) to avoid collapsing independent visitor sessions together.

### Preventing Silent Data Loss on Missing `session_start` & NULL Landing Pages
- Real-world GA4 event streams can contain sessions with `purchase` or page events where `session_start` failed to fire or `page_location` returned `NULL`.
- In `03_landing_page_conversion_dynamics.sql`, a session-summary CTE aggregates `MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS has_session_start` alongside `COALESCE(landing_page, '(not set)')`, filtering explicitly on `WHERE has_session_start = 1` instead of blind inner filtering.
- Note on GA4 Privacy Obfuscation: `"Data Deleted"` or `NULL` entries in `traffic_source` fields are expected properties of Google's anonymized public e-commerce sample rather than query errors.
