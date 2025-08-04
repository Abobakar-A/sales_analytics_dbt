SELECT
    country,
    product_name,
    COUNT(order_id) AS total_orders,
    SUM(amount) AS total_revenue,
    {{ dynamic_partition('order_date','month') }}
FROM
    {{ ref('stg_sales') }}
GROUP BY
    country,
    product_name,
    partition_group