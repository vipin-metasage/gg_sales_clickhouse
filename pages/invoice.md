---
title: Invoice Insights Dashboard
---


<center>
   
<Dropdown data={year} name=year value=year title="Year" defaultValue="%">
    <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={material_group} name=material_group value=material_group defaultValue='%' title="Material Group">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={payment_term_description} name=payment_term_description value=payment_term_description defaultValue='%' title="Payment Term">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={sku} name=sku value=material_description defaultValue='%' title="SKU">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={customer} name=customer value=customer_name defaultValue='%' title="Customer">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

</center>


```sql year
WITH max_date AS (
    SELECT MAX(CAST(invoice_date AS TIMESTAMP)) AS max_billing_date
    FROM manu
)
SELECT
    CAST(EXTRACT(YEAR FROM CAST(invoice_date AS TIMESTAMP)) AS VARCHAR) AS year
FROM manu
WHERE sales_quantity > 0
  AND CAST(EXTRACT(YEAR FROM CAST(invoice_date AS TIMESTAMP)) AS VARCHAR) LIKE '${inputs.year.value}'
  AND invoice_date >= (
      SELECT max_billing_date - INTERVAL '3 months'
      FROM max_date
  )
GROUP BY year
ORDER BY year DESC;
```

```sql material_group
WITH max_date AS (
    SELECT MAX(CAST(invoice_date AS TIMESTAMP)) AS max_billing_date
    FROM manu
)
SELECT material_group
FROM manu
WHERE material_group IS NOT NULL
  AND invoice_date >= (
      SELECT max_billing_date - INTERVAL '3 months'
      FROM max_date
  )
GROUP BY material_group
ORDER BY material_group;
```

```sql payment_term_description            
WITH max_date AS (
    SELECT MAX(CAST(invoice_date AS TIMESTAMP)) AS max_billing_date
    FROM manu
)
SELECT payment_term_description
FROM manu
WHERE invoice_date >= (
      SELECT max_billing_date - INTERVAL '3 months'
      FROM max_date
  )
GROUP BY payment_term_description
ORDER BY payment_term_description;
```



```sql sku
WITH max_date AS (
    SELECT MAX(CAST(invoice_date AS TIMESTAMP)) AS max_billing_date
    FROM manu
)
SELECT material_description
FROM manu
WHERE invoice_date >= (
      SELECT max_billing_date - INTERVAL '3 months'
      FROM max_date
  )
GROUP BY material_description
ORDER BY material_description;
``` 

```sql customer
WITH max_date AS (
    SELECT MAX(CAST(invoice_date AS TIMESTAMP)) AS max_billing_date
    FROM manu
)
SELECT customer_name
FROM manu
WHERE invoice_date >= (
      SELECT max_billing_date - INTERVAL '3 months'
      FROM max_date
  )
GROUP BY customer_name
ORDER BY customer_name;
``` 


```sql customer_level
WITH base AS (
    SELECT
        customer_name AS customer,
        country_name AS country,
        material_number AS sku_id,
        CAST(invoice_date AS TIMESTAMP) AS billing_date,
        invoice_number AS billing_document,
        total_amount,
        sales_quantity AS billing_qty,
        document_currency AS currency,
        EXTRACT(YEAR FROM CAST(invoice_date AS TIMESTAMP))::VARCHAR AS billing_year,
        unit_price,
        shipping_term AS incoterms_part1,
        material_group AS material_group_desc
    FROM manu
    WHERE 
        sales_quantity > 0
        AND material_group LIKE '${inputs.material_group.value}'
        AND payment_term_description LIKE '${inputs.payment_term_description.value}'
        AND material_description LIKE '${inputs.sku.value}'
        AND customer_name LIKE '${inputs.customer.value}'
        AND EXTRACT(YEAR FROM CAST(invoice_date AS TIMESTAMP))::VARCHAR LIKE '${inputs.year.value}'
),
metadata AS (
    SELECT 
        MAX(EXTRACT(YEAR FROM billing_date)::VARCHAR) AS latest_year,
        MAX(billing_date) AS max_billing_date
    FROM base
),
aggregated AS (
    SELECT
        b.customer,
        MIN(b.billing_date) AS first_invoice_date,
        MAX(b.billing_date) AS latest_invoice_date,
        b.currency,
        COUNT(DISTINCT CASE WHEN b.billing_year = m.latest_year THEN b.billing_document END) AS invoice_ytd,
        SUM(CASE WHEN b.billing_year = m.latest_year THEN b.billing_qty ELSE 0 END) AS sku_quantity_ytd,
        SUM(CASE WHEN b.billing_year = m.latest_year THEN b.total_amount ELSE 0 END) AS revenue_ytd,
        COUNT(DISTINCT b.billing_document) AS total_invoices,
        SUM(b.billing_qty) AS sku_quantity,
        SUM(b.total_amount) AS total_revenue
    FROM base b
    CROSS JOIN metadata m
    WHERE b.customer IN (
        SELECT customer
        FROM base
        WHERE billing_date >= m.max_billing_date - INTERVAL '3 months'
    )
    GROUP BY b.customer, b.currency, m.latest_year
)
SELECT
    customer,
    CAST(first_invoice_date AS DATE)::VARCHAR AS first_invoice_date,
    CAST(latest_invoice_date AS DATE)::VARCHAR AS latest_invoice_date,
    currency,
    invoice_ytd,
    sku_quantity_ytd,
    revenue_ytd,
    total_invoices,
    sku_quantity,
    total_revenue,
    '/pricing/details/' || customer AS detail_link
FROM aggregated
ORDER BY revenue_ytd DESC;
```

<DataTable 
    data={customer_level}
    subtitle="Only customers invoiced in the last 3 months are included"
    rows=15
    link=detail_link
    wrapTitles=true
>
    <Column id="customer" title="Customer" align="left" />
    <Column id="first_invoice_date" title="First Invoice" align="center" />
    <Column id="latest_invoice_date" title="Latest Invoice" align="center" />
    <Column id="currency" title="Currency" align="center" />
    <Column id="invoice_ytd" title="Invoices" align="center" colGroup="YTD"/>
    <Column id="sku_quantity_ytd" title="SKU Quantity" align="center" colGroup="YTD"/>
    <Column id="revenue_ytd" title="Revenue" fmt="num0K" align="center" colGroup="YTD"/>
    <Column id="total_invoices" title="Invoices" align="center" colGroup="Total"/>
    <Column id="sku_quantity" title="SKU Quantity" align="center" colGroup="Total"/>
    <Column id="total_revenue" title="Revenue" fmt="num0K" align="center" colGroup="Total"/>
</DataTable>
