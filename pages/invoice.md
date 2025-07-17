---
title: Invoice Insights Dashboard
---


<center>
   
<Dropdown data={year} name=year value=year title="Year" defaultValue="%">
    <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={payment_term_desc} name=payment_term_desc value=payment_term_desc defaultValue='%' title="Payment Term">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

<Dropdown data={customer} name=customer value=customer defaultValue='%' title="Customer">
  <DropdownOption value="%" valueLabel="All"/>
</Dropdown>

</center>


```sql year
SELECT
  EXTRACT(YEAR FROM CAST(first_invoice_date AS TIMESTAMP)) AS year
FROM Clickhouse.invoice
GROUP BY year
ORDER BY year DESC;
```

```sql payment_term_desc            
SELECT payment_term_desc
FROM Clickhouse.payment
GROUP BY payment_term_desc
ORDER BY payment_term_desc;
```

```sql customer
SELECT customer
FROM Clickhouse.invoice
GROUP BY customer
ORDER BY customer;
```


```sql customer_level
SELECT * from Clickhouse.invoice
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
