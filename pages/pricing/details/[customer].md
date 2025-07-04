<center>

## Pricing Summary for {params.customer}

</center>


```sql customer_metrics
WITH base AS (
    SELECT
        customer_name AS customer,
        invoice_number,
        CAST(CAST(invoice_date AS DATE) AS VARCHAR) AS invoice_date,
        sales_quantity,
        total_amount,
        payment_due_date,
        payment_date,
        payment_days,
        outstanding_amount,
        payment_status,
        CASE
            WHEN payment_status = 'Clear' AND payment_date IS NOT NULL THEN
                DATE_DIFF('day', CAST(payment_due_date AS DATE), CAST(payment_date AS DATE))
            WHEN payment_status = 'Open' THEN
                DATE_DIFF('day', CAST(payment_due_date AS DATE), CURRENT_DATE)
            ELSE NULL
        END AS delay_days
    FROM Clickhouse.manu
    WHERE sales_quantity > 0
    AND customer_name = '${params.customer}'
    AND material_description LIKE '${inputs.sku.value}'
    AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
    AND material_group LIKE '${inputs.material_group.value}'
    AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
),
customer_summary AS (
    SELECT
        customer,
        -- Total Orders (count distinct invoice numbers)
        COUNT(DISTINCT invoice_number) AS total_orders,
        
        -- Total quantity
        SUM(sales_quantity) AS total_quantity,
        
        -- Average order quantity
        SUM(sales_quantity) * 1.0 / COUNT(DISTINCT invoice_number) AS avg_order_quantity,
        
        -- Total Revenue
        SUM(total_amount) AS total_revenue,
        
        -- First order date
        MIN(invoice_date) AS first_order_date,
        
        -- Last order date
        MAX(invoice_date) AS last_order_date,
        
        -- Payment delayed orders (orders with positive delay days)
        COUNT(CASE WHEN delay_days > 0 THEN 1 END) AS payment_delayed_orders,
        
        -- Outstanding amount
        SUM(outstanding_amount) AS total_outstanding_amount,
        
        -- Average payment delay (only for orders with delay)
        AVG(CASE WHEN delay_days > 0 THEN delay_days END) AS avg_payment_delay_days
        
    FROM base
    GROUP BY customer
)
SELECT 
    customer,
    total_orders,
    total_quantity,
    ROUND(avg_order_quantity, 2) AS avg_order_quantity,
    ROUND(total_revenue, 2) AS total_revenue,
    CAST(CAST(first_order_date AS DATE) AS VARCHAR) AS first_order_date,
    CAST(CAST(last_order_date AS DATE) AS VARCHAR) AS last_order_date,
    payment_delayed_orders,
    ROUND(total_outstanding_amount, 2) AS total_outstanding_amount,
    ROUND(avg_payment_delay_days, 2) AS avg_payment_delay_days
FROM customer_summary
ORDER BY total_revenue DESC;
```



```sql sku_summary
WITH filtered_data AS (
    SELECT
        customer_name AS customer,
        destination_country AS country,
        material_description AS sku,
        invoice_date,
        invoice_number,
        total_amount,
        sales_quantity AS billing_qty,
        sales_unit,
        document_currency AS doc_currency,
        total_amount / NULLIF(sales_quantity, 0) AS unit_price,
        invoice_type AS billing_type,
        shipping_term AS incoterms_part1,
        payment_term_description AS payment_term_desc,
        material_group AS material_group_desc
    FROM Clickhouse.manu
    WHERE sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND material_description LIKE '${inputs.sku.value}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
)
SELECT * FROM filtered_data;
```

<center>

<Dropdown data={year} name=year value=year defaultValue='%' title="Year" >
<DropdownOption value="%" valueLabel="All Years"/>
</Dropdown>

<Dropdown data={material_group} name=material_group value=material_group defaultValue='%' title="Material Group">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={payment_term_desc} name=payment_term_desc value=payment_term_desc defaultValue='%' title="Payment Term">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>


<Dropdown data={sku} name=sku value=sku defaultValue='{params.sku}' title="SKU">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={customer} name=customer value=customer defaultValue='{params.customer}' title="Customer">
</Dropdown>

</center>

<Grid cols=3>
    <BigValue 
        data={customer_metrics} 
        value=total_orders
        title="Total Orders"
        fmt=num0
    />
    <BigValue 
        data={customer_metrics} 
        value=total_quantity
        title="Total Quantity"
        fmt=num0
    />
    <BigValue 
        data={customer_metrics} 
        value=avg_order_quantity
        title="Average Order Quantity"
        fmt=num0
    />
</Grid>


<Grid cols=3>
    <BigValue 
        data={customer_metrics} 
        value=total_revenue
        title="Total Revenue"
        fmt=num0
    />
    <BigValue 
        data={customer_metrics} 
        value=first_order_date
        title="First Order Date"
    />
    <BigValue 
        data={customer_metrics} 
        value=last_order_date
        title="Last Order Date"
    />
</Grid>

<Grid cols=3>
    <BigValue 
        data={customer_metrics} 
        value=payment_delayed_orders
        title="Payment Delayed Orders"
        fmt=num0
    />

<BigValue 
        data={customer_metrics} 
        value=total_outstanding_amount
        title="Outstanding Payment"
        fmt=num0
    />

<BigValue 
        data={customer_metrics} 
        value=avg_payment_delay_days
        title="Average Payment Delay (Days)"
        fmt=num0
    />

</Grid>



```sql sku_vs_payment_terms
SELECT
    material_description AS sku,
    payment_term_description AS payment_terms,
    SUM(sales_quantity) AS quantity_sold
FROM Clickhouse.manu
WHERE sales_quantity > 0
    AND customer_name = '${params.customer}'
GROUP BY material_description, payment_term_description
ORDER BY payment_term_description, material_description;
```

```sql material_group
SELECT
    material_group
FROM Clickhouse.manu
WHERE customer_name = '${params.customer}'
    AND sales_quantity > 0
GROUP BY material_group
ORDER BY material_group
```

```sql payment_term_desc
SELECT
    payment_term_description as payment_term_desc
FROM Clickhouse.manu
WHERE customer_name = '${params.customer}'
    AND sales_quantity > 0
GROUP BY payment_term_desc
ORDER BY payment_term_desc
```

```sql sku  
  select
      material_description as sku
  from Clickhouse.manu
  where customer_name = '${params.customer}'
    AND sales_quantity > 0
  group by material_description
```

```sql customer
  select
      customer_name as customer
  from Clickhouse.manu
  where customer_name = '${params.customer}'
    AND sales_quantity > 0
  group by customer_name
```


```sql year
SELECT
  EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) AS year
FROM Clickhouse.manu
WHERE customer_name = '${params.customer}'
  AND sales_quantity > 0
GROUP BY year
ORDER BY year DESC;
```


```sql avg_qty_per_order_over_time
SELECT
    DATE_TRUNC('month', CAST(invoice_date AS TIMESTAMP)) AS month,
    SUM(sales_quantity) * 1.0 / COUNT(DISTINCT invoice_number) AS avg_qty_per_order
FROM manu
WHERE sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
GROUP BY month
ORDER BY month;

```

```sql payment_kpi
SELECT
  ROUND(AVG(CASE WHEN payment_status != 'Unpaid' AND payment_days > 0 THEN payment_days END), 2) AS average_positive_delay_days_for_paid,
  SUM(CASE WHEN payment_status = 'Unpaid' THEN outstanding_amount ELSE 0 END) AS total_not_paid_amount,
  ROUND(100.0 * SUM(CASE WHEN payment_status = 'Delay Paid' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN payment_status != 'Unpaid' THEN 1 ELSE 0 END), 0), 2) AS delay_rate_percent,
  SUM(CASE WHEN payment_status = 'Delay Paid' THEN 1 ELSE 0 END) AS total_delay_orders,
  SUM(CASE WHEN payment_status != 'Unpaid' THEN 1 ELSE 0 END) AS total_paid_orders
FROM manu
WHERE sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
```

```sql revenue_and_quantity_over_time
SELECT
    DATE_TRUNC('month', CAST(invoice_date AS TIMESTAMP)) AS month,
    SUM(total_amount) AS revenue,
    SUM(sales_quantity) AS quantity
FROM manu
WHERE sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
GROUP BY month
ORDER BY month
```


```sql price_comparison_table
SELECT
    CAST(CAST(invoice_date AS DATE) AS VARCHAR) AS date,
    document_currency AS currency,
    material_description AS sku,
    AVG(total_amount / NULLIF(sales_quantity, 0)) AS unit_price
FROM manu
WHERE sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND material_description LIKE '${inputs.sku.value}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
GROUP BY invoice_date, document_currency, material_description
ORDER BY sku, date DESC, currency
```

<LineChart
data={price_comparison_table}
x=date
y=unit_price
chartAreaHeight=250
handleMissing=connect
yAxisTitle="Unit Price"
step=true
series=sku
colorPalette={[
  '#E4572E', // fiery orange-red
  '#17BEBB', // bright teal
  '#FFC914', // vivid yellow
  '#2E86AB', // strong blue
  '#F45B69',  // punchy pink
  '#8B6914',  // dark gold
  '#F4511E',  // 
]}
/>


```sql scatter_plot
SELECT
  invoice_number AS billing_document,
  invoice_date AS purchase_invoice_date,
  total_amount AS invoice_amount,

  -- Payment status label
  CASE 
    WHEN payment_status = 'Clear' THEN 'Full Paid'
    WHEN payment_status = 'Open' THEN 'Partial Paid'
    ELSE 'Unpaid'
  END AS payment_status,

  -- Actual due date (final payment deadline)
  payment_due_date AS due_date,

  -- Clearing date (payment realization)
  payment_date AS clearing_date,

  -- Delay days calculation
  CASE
    WHEN payment_status = 'Clear' AND payment_date IS NOT NULL THEN
      DATE_DIFF('day', CAST(payment_due_date AS DATE), CAST(payment_date AS DATE))
    WHEN payment_status = 'Open' THEN
      DATE_DIFF('day', CAST(payment_due_date AS DATE), CURRENT_DATE)
    ELSE NULL
  END AS delay_days

FROM manu

WHERE
  sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND material_description LIKE '${inputs.sku.value}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'

ORDER BY invoice_date;
```

<Grid cols=2>

<div>

### SKU Quantity Over Time

<LineChart
data={avg_qty_per_order_over_time}
x=month
y=avg_qty_per_order
yFmt=num0k
yAxisTitle="Average Quantity"
/>  
</div>

<div>

### Invoice Amount vs Payment Delay by Payment Status

<ScatterPlot 
    data={scatter_plot}
    x=delay_days
    y=invoice_amount
    series=payment_status
    colorPalette={[
'#81C784', // light green for early paid
'#FFB74D', // light orange for delayed paid  
'#EF5350', // light red for unpaid
]}
/>
</div>

</Grid>

<DataTable data={sku_summary} />

