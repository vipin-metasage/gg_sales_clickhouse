WITH agg AS (
  SELECT
    invoice_number,
    any(customer_name) AS customer_name,
    max(toDate(invoice_date)) AS purchase_invoice_date,
    sum(total_amount) AS invoice_amount,
    max(toDate(baseline_date)) AS baseline_date,
    max(toDate(payment_date)) AS clearing_date,
    max(toInt32(payment_days)) AS payment_days,
    max(payment_status) AS raw_status,
    max(amount_paid) AS paid_amount
  FROM manufacturing.analytics
  WHERE toDate(invoice_date) > toDate('2015-01-01')
  GROUP BY invoice_number
),

with_delay AS (
  SELECT
    *,
    (baseline_date + payment_days) AS due_date,
    CAST(
      CASE 
        WHEN raw_status = 'Clear' THEN 
          dateDiff('day', baseline_date + payment_days, clearing_date)
        ELSE 
          dateDiff('day', baseline_date + payment_days, today())
      END AS Int32
    ) AS delay_days
  FROM agg
)

SELECT
  customer_name,
  invoice_number AS billing_document,
  purchase_invoice_date,
  invoice_amount,
  delay_days,  -- now guaranteed to be Int32
  CASE 
    WHEN paid_amount > 0 AND raw_status = 'Open' THEN 'Open'
    WHEN raw_status = 'Clear' AND delay_days <= 0 THEN 'Early Paid'
    WHEN raw_status = 'Clear' AND delay_days > 0 THEN 'Delay Paid'
    WHEN paid_amount = 0 AND raw_status != 'Clear' THEN 'Unpaid'
    ELSE 'Unknown'
  END AS payment_status
FROM with_delay
ORDER BY purchase_invoice_date;
