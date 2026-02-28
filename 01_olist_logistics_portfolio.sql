-- ======================================
-- Olist Logistics Delay Analysis (Portfolio Version)
-- Author: Vitória Ceccato
-- Goal: Identify structural drivers of delivery delays and prioritize route-level impact
-- Grain: 1 row per delivered order
-- Methods: IQR outliers, absolute impact, MAE validation
-- Engine: DuckDB
-- ======================================

-- ======================================
-- Sections (Executive View)
-- ======================================

-- 1) Data loading + grain validation
-- 2) Lead time metrics + outliers (IQR)
-- 3) Bottleneck decomposition (approval/dispatch/transport)
-- 4) Geographic + route impact (state/region, interstate vs intrastate)
-- 5) Top routes (absolute + excess vs global)
-- 6) MAE (origin vs destination vs route)

-- ======================================
-- 1) DATA LOADING + GRAIN / KEY VALIDATION
-- ======================================

CREATE OR REPLACE TABLE orders AS
SELECT *
FROM read_csv_auto('olist_orders_dataset.csv');
CREATE OR REPLACE TABLE order_items AS
SELECT *
FROM read_csv_auto('olist_order_items_dataset.csv');
CREATE OR REPLACE TABLE customers AS
SELECT *
FROM read_csv_auto('olist_customers_dataset.csv');
CREATE OR REPLACE TABLE sellers AS
SELECT *
FROM read_csv_auto('olist_sellers_dataset.csv');
-- Sanity check: 1 row per order (order_id unique)
SELECT COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS unique_orders
FROM orders;
-- order_items grain: composite key (order_id, order_item_id)
SELECT COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id || '-' || order_item_id) AS unique_order_items
FROM order_items;
-- Timestamp completeness (delivered orders subset used downstream)
SELECT COUNT(*) AS total_orders,
  COUNT(order_purchase_timestamp) AS has_purchase_ts,
  COUNT(order_delivered_customer_date) AS has_delivery_ts
FROM orders;
-- Optional sanity: not all orders appear in order_items
SELECT COUNT(*) AS total_items,
  COUNT(DISTINCT order_id) AS orders_with_items
FROM order_items;

-- ======================================
-- 2) DELIVERED BASE + LEAD TIME METRICS
-- ======================================

-- Output: 1 row per delivered order with lead_time_days (purchase -> delivery)
CREATE OR REPLACE TABLE base_orders_delivered AS
SELECT
  order_id,
  customer_id,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  DATEDIFF('day', order_purchase_timestamp, order_delivered_customer_date) AS lead_time_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL;
-- Sanity checks: grain + lead time boundaries
SELECT COUNT(*) AS rows,
  COUNT(DISTINCT order_id) AS unique_orders,
  MIN(lead_time_days) AS min_lead_time_days,
  MAX(lead_time_days) AS max_lead_time_days,
  AVG(lead_time_days) AS avg_lead_time_days
FROM base_orders_delivered;
-- Distribution summary
SELECT AVG(lead_time_days) AS mean_days,
  MEDIAN(lead_time_days) AS median_days,
  STDDEV(lead_time_days) AS stddev_days
FROM base_orders_delivered;

-- ======================================
-- 3) OUTLIERS (IQR METHOD) ON LEAD TIME
-- ======================================

-- Output: quartiles + IQR + upper fence + extreme delay rate
WITH q AS (
  SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (
      ORDER BY lead_time_days
    ) AS p25,
    MEDIAN(lead_time_days) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
      ORDER BY lead_time_days
    ) AS p75
  FROM base_orders_delivered
),
iqr AS (
  SELECT p25,
    p50,
    p75,
    (p75 - p25) AS iqr_days,
    (p75 + 1.5 * (p75 - p25)) AS upper_fence_days
  FROM q
),
extremes AS (
  SELECT COUNT(*) AS extreme_delay_orders
  FROM base_orders_delivered
  WHERE lead_time_days > (
      SELECT upper_fence_days
      FROM iqr
    )
)
SELECT iqr.*,
  e.extreme_delay_orders,
  1.0 * e.extreme_delay_orders / (
    SELECT COUNT(*)
    FROM base_orders_delivered
  ) AS extreme_delay_rate
FROM iqr
  CROSS JOIN extremes e;

-- ======================================
-- 4) PROCESS DECOMPOSITION (APPROVAL / DISPATCH / TRANSPORT)
-- ======================================

-- Output: stage durations + variability to identify bottleneck
CREATE OR REPLACE TABLE base_stages AS
SELECT
  order_id,
  DATEDIFF('day', order_purchase_timestamp, order_approved_at) AS approval_days,
  DATEDIFF('day', order_approved_at, order_delivered_carrier_date) AS dispatch_days,
  DATEDIFF('day', order_delivered_carrier_date, order_delivered_customer_date) AS transport_days,
  lead_time_days
FROM base_orders_delivered;

-- Stage variability
SELECT
  AVG(approval_days) AS avg_approval_days,
  STDDEV(approval_days) AS std_approval_days,
  AVG(dispatch_days) AS avg_dispatch_days,
  STDDEV(dispatch_days) AS std_dispatch_days,
  AVG(transport_days) AS avg_transport_days,
  STDDEV(transport_days) AS std_transport_days
FROM base_stages;

-- ======================================
-- EXECUTIVE VALIDATION: STAGE CONTRIBUTION
-- ======================================

SELECT
  ROUND(AVG(lead_time_days), 2) AS avg_total_lead_time,
  ROUND(AVG(approval_days), 2)  AS avg_approval_days,
  ROUND(AVG(dispatch_days), 2)  AS avg_dispatch_days,
  ROUND(AVG(transport_days), 2) AS avg_transport_days,
  ROUND(100.0 * AVG(approval_days)  / AVG(lead_time_days), 2) AS approval_share_pct,
  ROUND(100.0 * AVG(dispatch_days)  / AVG(lead_time_days), 2) AS dispatch_share_pct,
  ROUND(100.0 * AVG(transport_days) / AVG(lead_time_days), 2) AS transport_share_pct
FROM base_stages;

-- ======================================
-- 5) DIMENSIONS PREP (AVOID ROW EXPLOSION)
-- ======================================

CREATE OR REPLACE TABLE items_per_order AS
SELECT order_id,
  COUNT(*) AS item_count
FROM order_items
GROUP BY order_id;
-- Sanity: 1 row per order
SELECT COUNT(*) AS rows,
  COUNT(DISTINCT order_id) AS unique_orders
FROM items_per_order;

-- ======================================
-- 6) ITEM COUNT IMPACT TEST
-- ======================================

SELECT i.item_count,
  COUNT(*) AS order_volume,
  AVG(b.transport_days) AS avg_transport_days
FROM base_stages b
  LEFT JOIN items_per_order i ON b.order_id = i.order_id
GROUP BY i.item_count
ORDER BY i.item_count;

-- ======================================
-- 7) STATE-LEVEL ANALYSIS (CUSTOMER SIDE)
-- ======================================

SELECT c.customer_state,
  COUNT(*) AS order_volume,
  AVG(b.transport_days) AS avg_transport_days
FROM base_stages b
  LEFT JOIN orders o ON b.order_id = o.order_id
  LEFT JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_transport_days DESC;
SELECT c.customer_state,
  COUNT(*) AS order_volume,
  SUM(
    CASE
      WHEN b.transport_days > 30 THEN 1
      ELSE 0
    END
  ) AS delayed_orders,
  1.0 * SUM(
    CASE
      WHEN b.transport_days > 30 THEN 1
      ELSE 0
    END
  ) / COUNT(*) AS delay_rate
FROM base_stages b
  LEFT JOIN orders o ON b.order_id = o.order_id
  LEFT JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY delay_rate DESC;

-- ======================================
-- 8) REGION MAPPING (CUSTOMER SIDE)
-- ======================================

CREATE OR REPLACE TABLE dim_customers AS
SELECT customer_id,
  customer_state,
  CASE
    WHEN customer_state IN ('AM', 'PA', 'RO', 'RR', 'AC', 'AP', 'TO') THEN 'North'
    WHEN customer_state IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Northeast'
    WHEN customer_state IN ('DF', 'GO', 'MT', 'MS') THEN 'Center-West'
    WHEN customer_state IN ('ES', 'MG', 'RJ', 'SP') THEN 'Southeast'
    WHEN customer_state IN ('PR', 'RS', 'SC') THEN 'South'
    ELSE 'Other'
  END AS customer_region
FROM customers;
SELECT dc.customer_region,
  COUNT(*) AS order_volume,
  SUM(
    CASE
      WHEN b.transport_days > 30 THEN 1
      ELSE 0
    END
  ) AS delayed_orders,
  100.0 * SUM(
    CASE
      WHEN b.transport_days > 30 THEN 1
      ELSE 0
    END
  ) / COUNT(*) AS delay_rate_pct
FROM base_stages b
  LEFT JOIN orders o ON b.order_id = o.order_id
  LEFT JOIN dim_customers dc ON o.customer_id = dc.customer_id
GROUP BY dc.customer_region
ORDER BY delay_rate_pct DESC;

-- ======================================
-- 9) MAIN SELLER STATE PER ORDER (1 ROW / ORDER)
-- ======================================

CREATE OR REPLACE TABLE main_seller_per_order AS
SELECT oi.order_id,
  MIN(s.seller_state) AS seller_state
FROM order_items oi
  LEFT JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY oi.order_id;
SELECT COUNT(*) AS rows,
  COUNT(DISTINCT order_id) AS unique_orders
FROM main_seller_per_order;

-- ======================================
-- 10) INTERSTATE VS INTRASTATE + RELATIVE RISK
-- ======================================

WITH route_type AS (
  SELECT
    b.transport_days,
    dc.customer_state,
    ms.seller_state,
    CASE
      WHEN dc.customer_state = ms.seller_state THEN 'Same state'
      ELSE 'Different state'
    END AS route_type
  FROM base_stages b
  LEFT JOIN orders o ON b.order_id = o.order_id
  LEFT JOIN dim_customers dc ON o.customer_id = dc.customer_id
  LEFT JOIN main_seller_per_order ms ON b.order_id = ms.order_id
  WHERE ms.seller_state IS NOT NULL
),

summary AS (
  SELECT
    route_type,
    COUNT(*) AS order_volume,
    AVG(transport_days) AS avg_transport_days,
    SUM(CASE WHEN transport_days > 30 THEN 1 ELSE 0 END) AS delayed_orders,
    1.0 * SUM(CASE WHEN transport_days > 30 THEN 1 ELSE 0 END) / COUNT(*) AS delay_rate
  FROM route_type
  GROUP BY route_type
)

-- Cleaner relative risk calculation
SELECT
  MAX(CASE WHEN route_type = 'Different state' THEN delay_rate END)
  /
  MAX(CASE WHEN route_type = 'Same state' THEN delay_rate END)
  AS relative_risk
FROM summary;

-- ======================================
-- 11) ROUTE BASE (STATE -> STATE) + DELAY FLAG
-- ======================================

CREATE OR REPLACE TABLE route_base AS
SELECT b.order_id,
  b.transport_days,
  CASE
    WHEN b.transport_days > 30 THEN 1
    ELSE 0
  END AS is_delayed,
  c.customer_state,
  ms.seller_state
FROM base_stages b
  LEFT JOIN orders o ON b.order_id = o.order_id
  LEFT JOIN customers c ON o.customer_id = c.customer_id
  LEFT JOIN main_seller_per_order ms ON b.order_id = ms.order_id
WHERE ms.seller_state IS NOT NULL
  AND c.customer_state IS NOT NULL;
-- Top routes by absolute delayed orders
SELECT seller_state,
  customer_state,
  COUNT(*) AS order_volume,
  SUM(is_delayed) AS delayed_orders
FROM route_base
GROUP BY seller_state,
  customer_state
ORDER BY delayed_orders DESC
LIMIT 10;

-- ======================================
-- 12) TOP ROUTES BY EXCESS DELAYS VS GLOBAL BENCHMARK
-- ======================================

WITH global_rate AS (
  SELECT AVG(is_delayed) AS global_delay_rate
  FROM route_base
),
routes AS (
  SELECT seller_state,
    customer_state,
    COUNT(*) AS order_volume,
    SUM(is_delayed) AS observed_delays,
    AVG(is_delayed) AS route_delay_rate
  FROM route_base
  GROUP BY seller_state,
    customer_state
  HAVING COUNT(*) >= 100
)
SELECT r.seller_state,
  r.customer_state,
  r.order_volume,
  r.observed_delays,
  ROUND(100 * r.route_delay_rate, 2) AS route_delay_rate_pct,
  ROUND(r.order_volume * g.global_delay_rate, 2) AS expected_delays,
  ROUND(
    r.observed_delays - (r.order_volume * g.global_delay_rate),
    2
  ) AS excess_delays,
  ROUND(r.route_delay_rate / g.global_delay_rate, 2) AS lift_vs_global
FROM routes r
  CROSS JOIN global_rate g
ORDER BY excess_delays DESC
LIMIT 5;

-- ======================================
-- 13) MAE: ORIGIN vs DESTINATION vs ROUTE
-- ======================================

CREATE OR REPLACE TABLE p_delay_by_origin AS
SELECT seller_state,
  AVG(is_delayed) AS p_delay
FROM route_base
GROUP BY seller_state;
CREATE OR REPLACE TABLE p_delay_by_destination AS
SELECT customer_state,
  AVG(is_delayed) AS p_delay
FROM route_base
GROUP BY customer_state;
CREATE OR REPLACE TABLE p_delay_by_route AS
SELECT seller_state,
  customer_state,
  AVG(is_delayed) AS p_delay
FROM route_base
GROUP BY seller_state,
  customer_state
HAVING COUNT(*) >= 100;
WITH pred_origin AS (
  SELECT ABS(rb.is_delayed - po.p_delay) AS abs_error
  FROM route_base rb
    LEFT JOIN p_delay_by_origin po ON rb.seller_state = po.seller_state
),
pred_destination AS (
  SELECT ABS(rb.is_delayed - pd.p_delay) AS abs_error
  FROM route_base rb
    LEFT JOIN p_delay_by_destination pd ON rb.customer_state = pd.customer_state
),
pred_route AS (
  SELECT ABS(rb.is_delayed - pr.p_delay) AS abs_error
  FROM route_base rb
    JOIN p_delay_by_route pr ON rb.seller_state = pr.seller_state
    AND rb.customer_state = pr.customer_state
)
SELECT 'route (origin+destination)' AS model,
  ROUND(AVG(abs_error), 4) AS mae
FROM pred_route
UNION ALL
SELECT 'destination only' AS model,
  ROUND(AVG(abs_error), 4) AS mae
FROM pred_destination
UNION ALL
SELECT 'origin only' AS model,
  ROUND(AVG(abs_error), 4) AS mae
FROM pred_origin
ORDER BY mae ASC;
