SELECT
        customer_name AS customer,
        material_description AS sku,
        CAST(CAST(invoice_date AS DATE) AS VARCHAR) AS invoice_date,
        invoice_number,
        total_amount,
        invoice_quantity AS billing_qty,
        sales_unit,
        document_currency AS doc_currency,
        unit_price,
        payment_term_description AS payment_term_desc,
        material_group AS material_group_desc
    FROM manufacturing.analytics
    WHERE invoice_date >= '2015-01-01'