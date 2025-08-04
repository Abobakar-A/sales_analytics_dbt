Sales Analytics Project Documentation
Project Overview
This project aims to create a sales data analysis pipeline using Google BigQuery and dbt (data build tool). The process begins by generating synthetic sales data, which is then processed using a dbt macro to partition it into 'recent' and 'historical' groups. The data is aggregated to create a final analytics table, which is then validated using data tests to ensure quality and integrity.

Phase 1: Creating Synthetic Data in BigQuery
The first step was to create a large volume of synthetic sales data (1 million rows) in BigQuery. The following SQL query was used to create a table named raw_sales.

Goal: To create a source table with random data to serve as the foundation for the analysis.

Code:

CREATE OR REPLACE TABLE sales-analytics-468003.Sales_dataset.raw_sales AS
WITH raw_data AS (
  SELECT
    GENERATE_UUID() AS order_id,
    ARRAY<STRING>['Laptop', 'Phone', 'Tablet', 'Headphones', 'Monitor'][OFFSET(CAST(FLOOR(RAND() * 5) AS INT64))] AS product_name,
    CAST(FLOOR(RAND() * 7000 + 100) AS INT64) AS amount,
    ARRAY<STRING>['USA', 'UK', 'Canada', 'Germany', 'France'][OFFSET(CAST(FLOOR(RAND() * 5) AS INT64))] AS country,
    DATE_ADD(DATE '2024-01-01', INTERVAL CAST(FLOOR(RAND() * 365) AS INT64) DAY) AS order_date,
    CAST(FLOOR(RAND() * 100) AS INT64) AS discount
  FROM UNNEST(GENERATE_ARRAY(1, 1000000))  -- Generates 1 Million Rows
)
SELECT * FROM raw_data;

Phase 2: Creating a dbt Macro for Dynamic Partitioning
A dbt macro named dynamic_partition was created to categorize orders into "recent" or "historical". The categorization is based on the difference between the order date and the current date.

Goal: To create a reusable function to partition data based on a date column, making it easy to analyze different time periods.

Code:

{% macro dynamic_partition(column, interval) %}

    {# 
        This macro partitions the data into two groups: 'recent' and 'historical'.
        'recent': Data that falls within a specified time interval from the current date.
        'historical': All other data.
        
        - column: The name of the date column to use for partitioning.
        - interval: The type of time interval (e.g., 'day', 'month', 'year').
    #}

    CASE
        {# Check if the column's date is within the specified interval #}
        WHEN date({{ column }}) >= date_sub(current_date(), interval 3 {{ interval }}) 
        THEN 'recent'

        {# If not within the interval, it is considered historical #}
        ELSE 'historical'
    END AS partition_group

{% endmacro %}

Phase 3: Building a Staging View Model
The dynamic_partition macro was used in a dbt model to create a view named stg_sales. This view adds a new column called partition_group to the raw data.

Goal: To prepare the raw data for the final analysis step by adding the partitioning column created by the macro.

Code:

-- models/stg_sales.sql

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

Phase 4: Creating the Final Analytics Table
Using the stg_sales view, a final table was created that aggregates data based on country, product, and partition group. This table provides valuable insights into total orders and total revenue.

Goal: To aggregate data from stg_sales to create a summarized analytics table, ready for reporting and dashboards.

Code:

SELECT
    country,
    product_name,
    COUNT(order_id) AS total_orders,
    SUM(amount) AS total_revenue,
    partition_group
FROM
    {{ ref('stg_sales') }}
GROUP BY
    country,
    product_name,
    partition_group

Phase 5: Data Testing with dbt
Finally, dbt tests were defined to ensure the quality and integrity of the final sales_final model. These tests automatically validate the data after each run.

Goal: To prevent data quality issues by automatically checking for common problems like null values and unexpected data.

Code:

version: 2

models:
  - name: sales_final
    description: 'Final sales model with aggregated revenue.'
    columns:
      - name: country
        tests:
          - not_null
      - name: total_orders
        tests:
          - not_null
      - name: partition_group
        description: 'The partition group for the sales data (recent or historical).'
        tests:
          - not_null
          - accepted_values:
              values: ['recent', 'historical']

Test Explanations:

not_null: Ensures that the country, total_orders, and partition_group columns never contain any NULL values.

accepted_values: Confirms that the partition_group column only contains the values 'recent' or 'historical', preventing unexpected categories from appearing.
