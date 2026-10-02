USE freshmart_uae;

-- Q1 Sales Analysis
-- Identify the top 10 product categories by revenue from delivered orders.
-- Compare revenue, order count, quantity sold, and average selling price by category.
select p.category, sum(oi.line_total) as total_revenue,
count( distinct oi.order_id) as total_orders,
sum(oi.quantity) as total_quantity_sold,
round(avg(p.selling_price),2) as average_selling_price 
from order_items oi 
inner join orders o on oi.order_id = o.order_id
inner join products p on oi.product_id = p.product_id
where o.order_status = 'Delivered'
group by p.category
order by sum(oi.line_total) desc
limit 10;

-- Q2 Store Return Analysis
-- Identify the top 10 stores by return rate.
-- Compare returned orders with total delivered and returned orders by store.
select s.store_id, s.store_name, sum(case when o.order_status = 'Returned' then 1 else 0 end ) as total_return_orders,
sum(case when o.order_status in ('Delivered','Returned') then 1 else 0 end ) as total_orders, 
round( sum(case when o.order_status = 'Returned' then 1 else 0 end )*100/ sum(case when o.order_status in ('delivered','Returned') then 1 else 0 end ),2) as Return_rate
from orders o 
inner join stores s on o.store_id = s.store_id
group by s.store_id, s.store_name
order by return_rate desc
limit 10;


-- Q3 June 2026 Category Sales Analysis
-- Compare delivered category performance by revenue, order count, and average selling price.
select p.category, 
sum(line_total) as total_revenue, 
count( distinct oi.order_id) as total_orders,
round(avg(selling_price),2) as average_selling_price
from order_items oi
inner join orders o on oi.order_id = o.order_id 
inner join products p on oi.product_id = p.product_id 
where YEAR(STR_TO_DATE(o.order_date, '%Y-%m-%d')) = 2026
  AND MONTH(STR_TO_DATE(o.order_date, '%Y-%m-%d')) = 6 and o.order_status = 'Delivered'
group by p.category
order by total_orders desc
limit 5;

-- Q4 June 2026 Promotion Analysis
-- Identify the top 5 promotions by average order value from delivered orders.
-- Compare revenue and order volume across promotions.
select pr.promotion_name, sum(oi.line_total) as total_revenue, 
count( distinct oi.order_id) as total_orders,
round(sum(oi.line_total)/count( distinct oi.order_id),2) as average_order_value
from order_items oi 
inner join orders o on oi.order_id=o.order_id
inner join products p on oi.product_id= p.product_id
inner join promotions pr on p.product_id=pr.product_id 
where o.order_status = 'Delivered' and STR_TO_DATE(o.order_date, '%Y-%m-%d') BETWEEN '2026-06-01' AND '2026-06-30'
group by pr.promotion_name
order by average_order_value desc
limit 5;


-- Q5 Customer Segmentation Analysis
-- Segment delivered-order customers by total revenue contribution.
-- Compare customer count, segment revenue, average customer revenue, and revenue share.
WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(o.order_total) AS total_revenue,
        CASE
            WHEN SUM(o.order_total) >= 1800 THEN 'Platinum'
            WHEN SUM(o.order_total) BETWEEN 1400 AND 1799 THEN 'Gold'
            WHEN SUM(o.order_total) BETWEEN 800 AND 1399 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_segment
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_date BETWEEN '2024-07-31' AND '2026-01-01'
      AND o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
)

SELECT
    customer_segment,
    COUNT(customer_id) AS total_customers,
    SUM(total_revenue) AS segment_revenue,
    ROUND(AVG(total_revenue), 2) AS avg_customer_revenue,
    ROUND(
        SUM(total_revenue) * 100.0 /
        SUM(SUM(total_revenue)) OVER (),
        2
    ) AS revenue_contribution_pct
FROM customer_summary
GROUP BY customer_segment;


-- Q6 Product Return Analysis
-- Identify the top 10 products by return rate.
-- Compare sold quantity, returned quantity, return rate, and revenue lost.
WITH return_quantity AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS total_return_quantity,
        SUM(line_total) AS total_revenue_lost
    FROM order_items oi
    INNER JOIN products p
        ON oi.product_id = p.product_id
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Returned'
    -- AND o.order_date IN (2026-07-01, 2026-07-31)
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

sold_quantity AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS total_sold_quantity
    FROM order_items oi
    INNER JOIN products p
        ON oi.product_id = p.product_id
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'Returned')
    -- AND o.order_date IN (2026-07-01, 2026-07-31)
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)

SELECT
    sq.product_name,
    sq.category,
    COALESCE(SUM(sq.total_sold_quantity), 0) AS sold_quantity,
    COALESCE(SUM(rq.total_return_quantity), 0) AS return_quantity,
    SUM(rq.total_revenue_lost) AS lost_revenue,
    ROUND(
        SUM(rq.total_return_quantity) * 100
        / SUM(sq.total_sold_quantity),
        2
    ) AS return_rate
FROM sold_quantity sq
LEFT JOIN return_quantity rq
    ON sq.product_id = rq.product_id
GROUP BY
    sq.product_name,
    sq.category
ORDER BY return_rate DESC
LIMIT 10;


-- Q7 Inventory Stock Analysis
-- Analyze June 2026 sales against current stock and reorder levels.
-- Identify stock status, critical-stock categories, and top products for reorder.
WITH sold_quantity AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_sold_quantity,
        SUM(line_total) AS total_revenue_generated
    FROM order_items oi
    INNER JOIN products p
        ON oi.product_id = p.product_id
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
        AND STR_TO_DATE(o.order_date, '%Y-%m-%d')
            BETWEEN '2026-06-01' AND '2026-06-30'
    GROUP BY
        p.product_id,
        p.product_name
),

restock_intentory AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        i.current_stock,
        i.reorder_level,
        CASE
            WHEN i.current_stock < i.reorder_level THEN 'Critical_Stock'
            WHEN i.current_stock = i.reorder_level THEN 'Low_Stock'
            WHEN i.current_stock > i.reorder_level THEN 'Healthy_Stock'
        END AS inventory_status
    FROM inventory i
    INNER JOIN products p
        ON i.product_id = p.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        current_stock,
        reorder_level
)

SELECT
    ri.product_name,
    ri.category,
    MAX(ri.current_stock) AS current_stock,
    MAX(ri.reorder_level) AS re_order_level,
    MAX(sq.total_sold_quantity) AS sold_quantity,
    ri.inventory_status
FROM restock_intentory ri
INNER JOIN sold_quantity sq
    ON ri.product_id = sq.product_id
GROUP BY
    ri.product_name,
    ri.category,
    ri.inventory_status
ORDER BY
    CASE
        WHEN ri.inventory_status = 'Critical_Stock' THEN 3
        WHEN ri.inventory_status = 'Low_Stock' THEN 2
        WHEN ri.inventory_status = 'Healthy_Stock' THEN 1
        ELSE 0
    END DESC,
    sold_quantity DESC;


-- Q8 Critical Stock by Category
-- Identify categories with the highest number of critical-stock products.
SELECT
    category,
    COUNT(product_id) AS total_products
FROM restock_intentory
WHERE inventory_status = 'Critical_Stock'
GROUP BY category
ORDER BY total_products DESC;

-- Q9 Reorder Priority
-- Identify the top 5 critical-stock products based on June 2026 sales volume and revenue.
SELECT
    ri.product_name,
    MAX(sq.total_sold_quantity) AS Total_qnt_sold,
    MAX(total_revenue_generated) AS revenue_generated
FROM restock_intentory ri
INNER JOIN sold_quantity sq
    ON ri.product_id = sq.product_id
WHERE inventory_status = 'Critical_Stock'
GROUP BY ri.product_name
ORDER BY
    Total_qnt_sold DESC,
    revenue_generated DESC
LIMIT 5;


-- Q10 Promotion Discount Analysis
-- Analyze June 2026 delivered promotion performance using revenue, orders, AOV, and total discount.
-- Compare discount value and discount share of revenue across promotions.
WITH promotion_orders AS (
    SELECT DISTINCT
        pr.promotion_name,
        oi.order_id
    FROM promotions pr
    INNER JOIN products p
        ON pr.product_id = p.product_id
    INNER JOIN order_items oi
        ON oi.product_id = p.product_id
),

promotions_revenue AS (
    SELECT
        po.promotion_name,
        COUNT(po.order_id) AS total_orders,
        SUM(o.order_total) AS total_revenue,
        ROUND(
            SUM(o.order_total) / COUNT(po.order_id),
            2
        ) AS average_order_value
    FROM orders o
    INNER JOIN promotion_orders po
        ON o.order_id = po.order_id
    WHERE o.order_status = 'Delivered'
        AND STR_TO_DATE(o.delivery_date, '%Y-%m-%d')
            BETWEEN '2026-06-01' AND '2026-06-30'
    GROUP BY po.promotion_name
),

promotion_discount AS (
    SELECT
        pr.promotion_name,
        SUM(oi.discount_amount) AS total_discount
    FROM order_items oi
    INNER JOIN products p
        ON oi.product_id = p.product_id
    INNER JOIN promotions pr
        ON p.product_id = pr.product_id
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
        AND STR_TO_DATE(o.delivery_date, '%Y-%m-%d')
            BETWEEN '2026-06-01' AND '2026-06-30'
    GROUP BY pr.promotion_name
)

SELECT
    pr.promotion_name,
    pr.total_orders,
    pr.total_revenue,
    pr.average_order_value,
    pd.total_discount,
    ROUND(
        (pd.total_discount * 100 / pr.total_revenue),
        2
    ) AS discount_percent_of_revenue
FROM promotions_revenue pr
INNER JOIN promotion_discount pd
    ON pr.promotion_name = pd.promotion_name
ORDER BY pr.total_revenue DESC;


-- Q11 Discount Performance Analysis
-- Compare discounted and non-discounted products in June 2026 delivered orders.
-- Analyze quantity sold, revenue, average selling price, and average discount percentage.

WITH discount_summary AS (
    SELECT
        oi.order_item_id,
        oi.quantity,
        oi.discount_percent,
        oi.discount_amount,
        oi.line_total,
        CASE
            WHEN oi.discount_amount > 0 THEN 'discounted_product'
            ELSE 'non_discounted_product'
        END AS discount_status,
        oi.final_unit_price
    FROM order_items oi
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
        AND STR_TO_DATE(o.delivery_date, '%Y-%m-%d')
            BETWEEN '2026-06-01' AND '2026-06-30'
)

SELECT
    discount_status,
    SUM(quantity) AS total_quantity_sold,
    SUM(line_total) AS total_revenue,
    ROUND(AVG(final_unit_price), 2) AS average_selling_price,
    ROUND(AVG(discount_percent), 2) AS average_discount_percentage
FROM discount_summary
GROUP BY discount_status;


-- Q12 Category Discount Dependency Analysis
-- Measure the share of category sales volume generated by discounted products in June 2026.
-- Compare discount dependency, average discount percentage, and total revenue by category.

WITH discount_summary AS (
    SELECT
        oi.order_item_id,
        p.category,
        oi.quantity,
        oi.discount_percent,
        oi.discount_amount,
        oi.line_total,
        CASE
            WHEN oi.discount_amount > 0 THEN 'Discounted'
            ELSE 'Non-Discounted'
        END AS discount_status
    FROM order_items oi
    INNER JOIN orders o
        ON oi.order_id = o.order_id
    INNER JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
        AND STR_TO_DATE(o.delivery_date, '%Y-%m-%d')
            BETWEEN '2026-06-01' AND '2026-06-30'
),

category_summary AS (
    SELECT
        category,
        SUM(quantity) AS total_quantity_sold,
        SUM(
            CASE
                WHEN discount_status = 'Discounted'
                    THEN quantity
                ELSE 0
            END
        ) AS discounted_quantity,
        AVG(
            CASE
                WHEN discount_status = 'Discounted'
                    THEN discount_percent
            END
        ) AS average_discount_percentage,
        SUM(line_total) AS total_revenue
    FROM discount_summary
    GROUP BY category
)

SELECT
    category,
    total_quantity_sold,
    discounted_quantity,
    ROUND(
        discounted_quantity * 100.0 / total_quantity_sold,
        2
    ) AS discount_dependency_percentage,
    ROUND(
        average_discount_percentage,
        2
    ) AS average_discount_percentage,
    ROUND(
        total_revenue,
        2
    ) AS total_revenue
FROM category_summary
ORDER BY discount_dependency_percentage DESC;


-- Q13 June 2026 Return Analysis
-- Compare category-level returned quantity, return rate, and revenue lost.
WITH return_summary AS (
    SELECT 
        r.return_id,
        r.order_id,
        r.return_reason
    FROM returns r
    WHERE STR_TO_DATE(r.return_date, '%Y-%m-%d')
          BETWEEN '2026-06-01' AND '2026-06-30'
),

delivery_summary AS (
    SELECT
        o.order_id,
        o.order_date,
        o.delivery_date
    FROM orders o
    WHERE o.delivery_date IS NOT NULL
),

-- Total quantity sold for each category
eligible_delivered AS (
    SELECT 
        p.category,
        SUM(oi.quantity) AS total_quantity_sold
    FROM order_items oi
    INNER JOIN products p
        ON oi.product_id = p.product_id
    INNER JOIN delivery_summary ds
        ON oi.order_id = ds.order_id
    GROUP BY p.category
),

-- Quantity and revenue associated with June returns
return_category_summary AS (
    SELECT
        p.category,
        SUM(oi.quantity) AS total_returned_quantity,
        SUM(oi.line_total) AS returned_revenue
    FROM order_items oi
    INNER JOIN products p
        ON oi.product_id = p.product_id
    INNER JOIN return_summary rs
        ON oi.order_id = rs.order_id
    INNER JOIN delivery_summary ds
        ON oi.order_id = ds.order_id
    GROUP BY p.category
)

SELECT
    rc.category,
    rc.total_returned_quantity,
    ed.total_quantity_sold,
    ROUND(
        rc.total_returned_quantity * 100.0
        / ed.total_quantity_sold,
        2
    ) AS return_rate,
    ROUND(rc.returned_revenue, 2) AS revenue_lost
FROM return_category_summary rc
INNER JOIN eligible_delivered ed
    ON rc.category = ed.category
ORDER BY return_rate DESC;