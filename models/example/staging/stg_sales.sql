-- models/my_new_model.sql

{{ config(
    materialized='view'
) }}

SELECT
    order_id,
    product_name,
    amount,
    country,
    order_date,
    {{ dynamic_partition('order_date', 'month') }}
FROM
    `sales-analytics-468003.Sales_dataset.raw_sales`
