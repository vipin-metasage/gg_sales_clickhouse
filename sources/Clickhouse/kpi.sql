WITH base AS (
    SELECT
        customer_name AS customer,
        invoice_number,
        CAST(invoice_date AS DATE) AS invoice_date,
        invoice_quantity,
        total_amount,
        outstanding_amount,
        payment_status,
        CAST(baseline_date AS DATE) AS baseline_date,
        CAST(payment_date AS DATE) AS clearing_date,
        CAST(payment_days AS INT) AS payment_days,

        -- ✅ Due Date using direct addition
        baseline_date + payment_days AS due_date,

        -- ✅ Delay Days using multiIf and correct date arithmetic
        multiIf(
            payment_status = 'Clear', dateDiff('day', baseline_date + payment_days, payment_date),
            payment_status = 'Open', dateDiff('day', baseline_date + payment_days, today()),
            NULL
        ) AS delay_days

    FROM manufacturing.analytics
)

-- ✅ Final output 
SELECT
    customer,
    COUNT(DISTINCT invoice_number) AS total_orders,
    SUM(invoice_quantity) AS total_quantity,
    ROUND(SUM(invoice_quantity) * 1.0 / NULLIF(COUNT(DISTINCT invoice_number), 0), 2) AS avg_order_quantity,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    formatDateTime(MIN(invoice_date), '%Y-%m-%d') AS first_order_date,
    formatDateTime(MAX(invoice_date), '%Y-%m-%d') AS last_order_date,

    COUNT(DISTINCT CASE 
        WHEN payment_status IN ('Clear', 'Open') AND delay_days > 0 
        THEN invoice_number 
    END) AS payment_delayed_orders,

    ROUND(AVG(CASE 
        WHEN payment_status IN ('Clear', 'Open') AND delay_days > 0 
        THEN delay_days 
    END), 2) AS avg_payment_delay_days,

    ROUND(SUM(outstanding_amount), 2) AS total_outstanding_amount

FROM base
GROUP BY customer
ORDER BY total_revenue DESC;
