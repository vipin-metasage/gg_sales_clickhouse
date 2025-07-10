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


```sql customer_level
    SELECT
        customer_name AS customer,
        material_number AS sku_id,
        invoice_date AS billing_date,
        invoice_number AS billing_document,
        total_amount,
        sales_quantity AS billing_qty,
        document_currency AS currency,
        CAST(EXTRACT(YEAR FROM CAST(invoice_date AS TIMESTAMP)) AS VARCHAR) AS billing_year,
        unit_price,
        shipping_term AS incoterms_part1,
        material_group AS material_group_desc
    FROM manu
    limit 100
```



<DataTable 
    data={customer_level}
    subtitle="Only customers invoiced in the last 3 months are included"
    rows=15
    wrapTitles=true
/>
