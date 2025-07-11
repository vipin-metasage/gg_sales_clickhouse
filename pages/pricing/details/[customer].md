<center>

## Pricing Summary for {params.customer}

</center>

```sql kpi
SELECT
  customer,
  COUNT(DISTINCT billing_document) AS total_orders,
  SUM(invoice_amount) AS total_revenue,
  SUM(sales_quantity) AS total_quantity,
  ROUND(AVG(sales_quantity)) AS avg_order_quantity,
  MIN(CAST(billing_date AS DATE)) AS first_order_date,
  MAX(CAST(billing_date AS DATE)) AS last_order_date,
  COUNT(billing_document) FILTER (WHERE CAST(delay_days AS INT) > 0) AS payment_delayed_orders,
  SUM(unpaid_amount) AS outstanding_payment,
  ROUND(AVG(CASE 
    WHEN payment_status IN ('Clear', 'Open') AND CAST(delay_days AS INT) > 0 
    THEN CAST(delay_days AS INT) 
  END), 2) AS avg_payment_delay_days
FROM payment
WHERE customer = '${params.customer}'
GROUP BY customer;
```

```sql sku_summary
SELECT *
    FROM Clickhouse.sku
```

<center>

<Dropdown data={year} name=year value=year defaultValue='%' title="Year" >
<DropdownOption value="%" valueLabel="All Years"/>
</Dropdown>

<Dropdown data={material_group_desc} name=material_group_desc value=material_group_desc defaultValue='%' title="Material Group">
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
        data={kpi} 
        value=total_orders
        title="Total Orders"
        fmt=num0
    />
    <BigValue 
        data={kpi} 
        value=total_quantity
        title="Total Quantity"
        fmt=num0
    />
    <BigValue 
        data={kpi} 
        value=avg_order_quantity
        title="Average Order Quantity"
        fmt=num0
    />
</Grid>


<Grid cols=3>
    <BigValue 
        data={kpi} 
        value=total_revenue
        title="Total Revenue"
        fmt=num0
    />
    <BigValue 
        data={kpi} 
        value=first_order_date
        title="First Order Date"
    />
    <BigValue 
        data={kpi} 
        value=last_order_date
        title="Last Order Date"
    />
</Grid>

<Grid cols=3>
    <BigValue 
        data={kpi} 
        value=payment_delayed_orders
        title="Payment Delayed Orders"
        fmt=num0
    />

<BigValue 
        data={kpi} 
        value=outstanding_payment
        title="Outstanding Payment"
        fmt=num0
    />

<BigValue 
        data={kpi} 
        value=avg_payment_delay_days
        title="Average Payment Delay (Days)"
        fmt=num0
    />

</Grid>



```sql material_group
SELECT
    material_group_desc
FROM Clickhouse.sku
WHERE customer = '${params.customer}'
GROUP BY material_group_desc
ORDER BY materialmaterial_group_desc_group
```

```sql payment_term_desc
SELECT
    payment_term_desc
FROM Clickhouse.payment
WHERE customer = '${params.customer}'  
GROUP BY payment_term_desc
ORDER BY payment_term_desc
```

```sql sku  
  select
      sku
  from Clickhouse.sku
  where customer = '${params.customer}'
  group by sku
```

```sql customer
  select
       customer
  from Clickhouse.invoice
  where customer = '${params.customer}'
  group by customer
```

```sql year
SELECT
  CAST(EXTRACT(YEAR FROM CAST(first_invoice_date AS DATE)) AS TEXT) AS year
FROM Clickhouse.invoice
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

```sql price_comparison_table
SELECT
    CAST(invoice_date AS DATE) AS date,
    sku ,
    AVG(unit_price) AS unit_price
FROM Clickhouse.sku
WHERE customer = '${params.customer}'
GROUP BY invoice_date, sku, unit_price
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



```sql payment_details
select * from Clickhouse.payment
where customer = '${params.customer}'
```

### 📅 Order Payment Details

<DataTable
  data={payment_details}
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