SELECT *
FROM subscriptions
LIMIT 100;

SELECT segment
FROM subscriptions
GROUP BY segment;

SELECT MIN(subscription_start) AS first_day_operating,
  MAX(subscription_end) AS last_day_operating
FROM subscriptions;

WITH months AS (
  SELECT
    '2017-01-01' as first_day,
    '2017-01-31' as last_day
  UNION
  SELECT
    '2017-02-01' as first_day,
    '2017-02-28' as last_day
  UNION
  SELECT
    '2017-03-01' as first_day,
    '2017-03-31' as last_day
),

cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),

status AS (
  SELECT id,
    first_day as month,
    CASE
      WHEN (segment = '87') AND 
        (subscription_start < first_day) AND
        (subscription_end >= first_day OR subscription_end IS NULL)
        THEN 1
      ELSE 0
    END as is_active_87,
    CASE
      WHEN (segment = '87') AND 
        (subscription_start < first_day) AND
        (subscription_end >= first_day AND subscription_end <= last_day)
        THEN 1
      ELSE 0
    END as is_canceled_87,
    CASE
      WHEN (segment = '30') AND 
        (subscription_start < first_day) AND
        (subscription_end >= first_day OR subscription_end IS NULL)
        THEN 1
      ELSE 0
    END as is_active_30,
    CASE
      WHEN (segment = '30') AND 
        (subscription_start < first_day) AND
        (subscription_end >= first_day AND subscription_end <= last_day)
        THEN 1
      ELSE 0
    END as is_canceled_30
  FROM cross_join
),
status_aggregate as (
  SELECT month,
    SUM(is_active_87) as sum_active_87,
    SUM(is_active_30) as sum_active_30,
    SUM(is_canceled_87) as sum_canceled_87,
    SUM(is_canceled_30) as sum_canceled_30
  FROM status
  GROUP BY month
)
SELECT month,
  1.0 * sum_canceled_87 / sum_active_87 AS churn_rate_87,
  1.0 * sum_canceled_30 / sum_active_30 AS churn_rate_30
FROM status_aggregate;

-- Bonus question
WITH months AS (
  SELECT
    '2017-01-01' as first_day,
    '2017-01-31' as last_day
  UNION
  SELECT
    '2017-02-01' as first_day,
    '2017-02-28' as last_day
  UNION
  SELECT
    '2017-03-01' as first_day,
    '2017-03-31' as last_day
),

cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),

status AS (
  SELECT id,
    first_day as month,
  	segment,
    CASE
      WHEN (subscription_start < first_day) AND
        (subscription_end >= first_day OR subscription_end IS NULL)
        THEN 1
      ELSE 0
    END as is_active,
    CASE
      WHEN (subscription_start < first_day) AND
        (subscription_end BETWEEN first_day AND last_day)
        THEN 1
      ELSE 0
    END as is_canceled
  FROM cross_join
),

status_aggregate AS (
	SELECT month,
  	segment,
		SUM(is_active) AS sum_active,
  	SUM(is_canceled) AS sum_canceled
  FROM status
  GROUP BY month, segment
)
SELECT month,
	segment,
  1.0 * sum_canceled / sum_active
FROM status_aggregate
ORDER BY 2;
