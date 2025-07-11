<center>

## Pricing Summary for {params.customer}

</center>


```sql customer_kpi
select * from Clickhouse.kpi
where customer = '${params.customer}'
```


```sql sku_summary
SELECT
        customer_name AS customer,
        material_description AS sku,
        CAST(CAST(invoice_date AS DATE) AS VARCHAR) AS invoice_date,
        invoice_number,
        total_amount,
        sales_quantity AS billing_qty,
        sales_unit,
        document_currency AS doc_currency,
        unit_price,
        payment_term_description AS payment_term_desc,
        material_group AS material_group_desc
    FROM Clickhouse.manu
    WHERE sales_quantity > 0
  AND customer_name = '${params.customer}'
  AND material_description LIKE '${inputs.sku.value}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
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
        data={customer_kpi} 
        value=total_orders
        title="Total Orders"
        fmt=num0
    />
    <BigValue 
        data={customer_kpi} 
        value=total_quantity
        title="Total Quantity"
        fmt=num0
    />
    <BigValue 
        data={customer_kpi} 
        value=avg_order_quantity
        title="Average Order Quantity"
        fmt=num0
    />
</Grid>


<Grid cols=3>
    <BigValue 
        data={customer_kpi} 
        value=total_revenue
        title="Total Revenue"
        fmt=num0
    />
    <BigValue 
        data={customer_kpi} 
        value=first_order_date
        title="First Order Date"
    />
    <BigValue 
        data={customer_kpi} 
        value=last_order_date
        title="Last Order Date"
    />
</Grid>

<Grid cols=3>
    <BigValue 
        data={customer_kpi} 
        value=payment_delayed_orders
        title="Payment Delayed Orders"
        fmt=num0
    />

<BigValue 
        data={customer_kpi} 
        value=total_outstanding_amount
        title="Outstanding Payment"
        fmt=num0
    />

<BigValue 
        data={customer_kpi} 
        value=avg_payment_delay_days
        title="Average Payment Delay (Days)"
        fmt=num0
    />

</Grid>



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
    CAST(month AS DATE) AS month,
    avg_qty_per_order,customer_name
FROM Clickhouse.order_qty_time
where customer_name = '${params.customer}'
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


```sql price_comparison_table
SELECT
    CAST(invoice_date AS DATE) AS date,
    material_description AS sku,
    AVG(unit_price) AS unit_price
FROM manu
WHERE customer_name = '${params.customer}'
  AND material_description LIKE '${inputs.sku.value}'
  AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
  AND material_group LIKE '${inputs.material_group.value}'
  AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
GROUP BY invoice_date, material_description, unit_price
ORDER BY sku, date asc
```


### Customer SKU Pricing Over Time
<LineChart
data={price_comparison_table}
x=date
y=unit_price
sort=date
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
  '#000000',  // black
]}
/>


```sql scatter_plot
select * from Clickhouse.scatter_plot
where customer_name = '${params.customer}'
```


```sql avg_qty_per_sku
   
select CAST(month AS DATE) AS month,average_quantity from Clickhouse.order_qty_time
where customer_name = '${params.customer}'
order by month
```

<Grid cols=2>

<div>


### Avg SKU Quantity Over Time

<LineChart
data={avg_qty_per_sku}
x=month
y=average_quantity
chartAreaHeight=220
yAxisTitle="Avg Qty per SKU"
yFmt=num0k
/>


</div>

<div>

### Invoice Amount vs Payment Delay by Payment Status

<ScatterPlot 
    data={scatter_plot}
    x=delay_days
    y=invoice_amount
    chartAreaHeight=210
    series=payment_status
    colorPalette={[
'#81C784', // light green for early paid
'#FFB74D', // light orange for delayed paid  
'#EF5350', // light red for unpaid
]}
/>
</div>

</Grid>


### 📅 SKU Historical Pricing

<DataTable 
    data={sku_summary}
    rows={15}
    search={true}
    wrapTitles={true}
>
    <Column id="invoice_date" title="Date" align="center" />
    <Column id="invoice_number" title="Billing Document" fmt="id" align="center" />
    <Column id="sku" title="Material" align="center" />
    <Column id="sales_unit" title="Sales Unit" align="center" />
    <Column id="total_amount" title="Total Amount" fmt="num0K" align="center" />
    <Column id="doc_currency" title="Currency" align="center" />
    <Column id="unit_price" title="Unit Price" fmt="num2" align="center" />
    <Column id="billing_qty" title="Quantity" fmt="num" align="center" />
</DataTable>


```sql order_payment_details
WITH agg AS (
  SELECT
    invoice_number,
    MAX(CAST(invoice_date AS DATE)) AS billing_date,
    SUM(total_amount) AS invoice_amount,
    SUM(sales_quantity) AS sales_quantity,
    MAX(payment_term_description) AS payment_term_desc,
    MAX(customer_name) AS customer,
    MAX(amount_paid) AS paid_amount,
    MAX(payment_status) AS payment_status,

    -- keep original casting logic
    MAX(CAST(payment_date AS DATE)) AS clearing_date,
    MAX(CAST(baseline_date AS DATE)) AS baseline_date,

    CAST(MAX(payment_days) AS INTEGER) AS cash_discount_days_1,
    MAX(material_group) AS material_group,
    MAX(outstanding_amount) AS unpaid_amount
  FROM Clickhouse.manu
  WHERE 
    customer_name = '${params.customer}'
    AND material_description LIKE '${inputs.sku.value}'
    AND EXTRACT(YEAR FROM CAST(invoice_date AS DATE)) LIKE '${inputs.year.value}'
    AND material_group LIKE '${inputs.material_group.value}'
    AND payment_term_description LIKE '${inputs.payment_term_desc.value}'
  GROUP BY invoice_number
)

SELECT
  billing_date,
  invoice_number AS billing_document,
  invoice_amount,
  sales_quantity,
  payment_term_desc,
  customer,
  paid_amount,
  payment_status,

  -- ✅ Blank clearing_date for Open or 1970 cases
  CASE 
    WHEN payment_status = 'Open' THEN NULL
    WHEN CAST(clearing_date AS TEXT) = '1970-01-01' THEN NULL
    ELSE CAST(clearing_date AS TEXT)
  END AS clearing_date,

  -- ✅ Baseline date cleanup
  CASE 
    WHEN CAST(baseline_date AS TEXT) = '1970-01-01' THEN NULL
    ELSE CAST(baseline_date AS TEXT)
  END AS baseline_date,

  cash_discount_days_1,

  -- ✅ Due Date
  (baseline_date + cash_discount_days_1 * INTERVAL '1' DAY)::DATE AS due_date,

  -- ✅ Delay Days
  CASE 
    WHEN payment_status = 'Clear' THEN 
      DATE_DIFF('day', (baseline_date + cash_discount_days_1 * INTERVAL '1' DAY)::DATE, clearing_date)
    ELSE 
      DATE_DIFF('day', (baseline_date + cash_discount_days_1 * INTERVAL '1' DAY)::DATE, CURRENT_DATE)
  END AS delay_days,

  unpaid_amount

FROM agg
ORDER BY billing_date DESC;
```

### 📅 Order Payment Details

<DataTable
  data={order_payment_details}
  search={true}
  rows={15}
  wrapTitles={true}
>
  <Column id="billing_date" title="Date" align="center" />
  <Column id="billing_document" title="Billing Document" fmt="id" align="center" />
  <Column id="invoice_amount" title="Invoice Amount" fmt="num1k" align="center" />
  <Column id="sales_quantity" title="Qty" fmt="num" align="center" />
  <Column id="payment_term_desc" title="Payment Term" align="center" />
  <Column id="paid_amount" title="Paid Amount" fmt="num1k" align="center" />
  <Column id="payment_status" title="Payment Status" align="center" />
  <Column id="clearing_date" title="Clearing Date" align="center" />
  <Column id="baseline_date" title="Baseline Date" align="center" />
  <Column id="cash_discount_days_1" title="Credit Days" fmt="num" align="center" />
  <Column id="due_date" title="Due Date" align="center" />
  <Column id="delay_days" title="Delay Days" fmt="num" align="center" />
  <Column id="unpaid_amount" title="Unpaid Amount" fmt="num1k" align="center" />
</DataTable>


### Average Order Quantity Over Time

<LineChart
data={avg_qty_per_order_over_time}
x=month
y=avg_qty_per_order
yFmt=num0k
yAxisTitle="Avg Qty per Order"
/>  