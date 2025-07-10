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
SELECT
    CAST(EXTRACT(YEAR FROM CAST(invoice_date AS TIMESTAMP)) AS VARCHAR) AS year
FROM manu
GROUP BY year
ORDER BY year DESC;
```

```sql material_group
SELECT material_group
FROM manu
GROUP BY material_group
ORDER BY material_group;
```

```sql payment_term_description            
SELECT payment_term_description
FROM manu
GROUP BY payment_term_description
ORDER BY payment_term_description;
```



```sql sku
SELECT material_description
FROM manu
GROUP BY material_description
ORDER BY material_description;
``` 

```sql customer
SELECT customer_name
FROM manu
GROUP BY customer_name
ORDER BY customer_name;
``` 

```sql price_comparison_table
SELECT * from Clickhouse.test2
```


```sql customer_level
SELECT * from Clickhouse.test3
```
<DataTable 
    data={customer_level}
    subtitle="Onl customers invoiced in the last 3 months are included"
    link=detail_link
    rows={20}
    wrapTitles={true}
>
    <Column id="customer" title="Customer" align="left" />
    <Column id="first_invoice_date" title="First Invoice" align="center" />
    <Column id="latest_invoice_date" title="Latest Invoice" align="center" />
    <Column id="currency" title="Currency" align="center" />
    <Column id="invoice_ytd" title="Invoices" align="center" colGroup="YTD" />
    <Column id="sku_quantity_ytd" title="SKU Quantity" align="center" colGroup="YTD" />
    <Column id="revenue_ytd" title="Revenue" fmt="num0K" align="center" colGroup="YTD" />
    <Column id="total_invoices" title="Invoices" align="center" colGroup="Total" />
    <Column id="total_invoice_quantity" title="SKU Quantity" align="center" colGroup="Total" />
    <Column id="total_revenue" title="Revenue" fmt="num0K" align="center" colGroup="Total" />
</DataTable>
