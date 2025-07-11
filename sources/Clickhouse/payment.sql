WITH base AS (
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
)

SELECT
  toDate(raw_billing_date) AS billing_date,
  invoice_number AS billing_document,
  invoice_amount,
  sales_quantity,
  payment_term_desc,
  customer,
  paid_amount,
  payment_status,

  -- ✅ Clean clearing_date (avoid 1970-01-01 for open/unpaid)
  CASE 
    WHEN payment_status = 'Open' THEN NULL
    WHEN toString(toDate(raw_clearing_date)) = '1970-01-01' THEN NULL
    ELSE toString(toDate(raw_clearing_date))
  END AS clearing_date,

  -- ✅ Clean baseline_date
  CASE 
    WHEN toString(toDate(raw_baseline_date)) = '1970-01-01' THEN NULL
    ELSE toString(toDate(raw_baseline_date))
  END AS baseline_date,

  toInt32(raw_payment_days) AS cash_discount_days_1,

  -- ✅ Due date (type-safe)
  addDays(toDate(raw_baseline_date), toInt32(raw_payment_days)) AS due_date,

  -- ✅ Delay days (numeric, safe for charting)
  CASE 
    WHEN payment_status = 'Clear' THEN dateDiff('day', addDays(toDate(raw_baseline_date), toInt32(raw_payment_days)), toDate(raw_clearing_date))
    ELSE dateDiff('day', addDays(toDate(raw_baseline_date), toInt32(raw_payment_days)), today())
  END AS delay_days,

  unpaid_amount

FROM base
ORDER BY billing_date DESC;
