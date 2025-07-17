SELECT
    toDate(raw_billing_date) AS billing_date,
    invoice_number AS billing_document,
    invoice_amount,
    sales_quantity,
    payment_term_desc,
    customer,
    paid_amount,
    payment_status,

    -- ✅ Clean clearing_date
    IF(
        payment_status = 'Open' OR toDate(raw_clearing_date) = toDate('1970-01-01'),
        NULL,
        toDate(raw_clearing_date)
    ) AS clearing_date,

    -- ✅ Clean baseline_date
    NULLIF(toDate(raw_baseline_date), toDate('1970-01-01')) AS baseline_date,

    toInt32(raw_payment_days) AS cash_discount_days_1,

    -- ✅ due_date calculation
    addDays(toDate(raw_baseline_date), toInt32(raw_payment_days)) AS due_date,

    -- ✅ delay_days calculation with inline today()
    IF(
        payment_status = 'Clear',
        dateDiff(
            'day',
            addDays(toDate(raw_baseline_date), toInt32(raw_payment_days)),
            toDate(raw_clearing_date)
        ),
        dateDiff(
            'day',
            addDays(toDate(raw_baseline_date), toInt32(raw_payment_days)),
            today()
        )
    ) AS delay_days,

    unpaid_amount

FROM (
    SELECT
        invoice_number,
        MAX(invoice_date) AS raw_billing_date,
        SUM(total_amount) AS invoice_amount,
        SUM(invoice_quantity) AS sales_quantity,
        MAX(payment_term_description) AS payment_term_desc,
        MAX(customer_name) AS customer,
        MAX(amount_paid) AS paid_amount,
        MAX(payment_status) AS payment_status,
        MAX(payment_date) AS raw_clearing_date,
        MAX(baseline_date) AS raw_baseline_date,
        MAX(payment_days) AS raw_payment_days,
        MAX(material_group) AS material_group,
        MAX(outstanding_amount) AS unpaid_amount
    FROM manufacturing.analytics
    WHERE invoice_date >= '2015-01-01'
    GROUP BY invoice_number
) AS base
ORDER BY billing_date DESC;
