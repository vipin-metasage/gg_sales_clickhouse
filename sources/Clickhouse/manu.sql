SELECT
    invoice_number,
    invoice_item_number,
    invoice_date,
 arrayStringConcat(
    arrayMap(
        x -> concat(upperUTF8(left(x, 1)), substring(x, 2)),
        splitByChar(' ', lowerUTF8(customer_name))
    ),
    ' '
) AS customer_name
,
    country_name,
    document_currency,
    freight_charges,
    invoice_type,
    invoice_quantity AS sales_quantity,
    sales_unit,
    unit,
    units_per_sales_unit,
    invoice_quantity,
    requested_quantity,
    net_value,
    unit_price,
    tax_amount,
    total_amount,
    shipping_term,
    shipping_term_details,
    shipping_conditions,
    material_number,
    material_description,
    sd_item_category,
    gross_weight,
    weight_unit,
    payment_term_description,
    baseline_date,
    payment_date,
    payment_days,
    amount_paid,
    outstanding_amount,
    payment_status,
    material_group,
    dateDiff('day', baseline_date, payment_date) AS delay_days
FROM manufacturing.analytics
where invoice_date >= '2015-01-01'
  AND shipping_term NOT IN ('EXW');
