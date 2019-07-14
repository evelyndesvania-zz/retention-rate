WITH first_transaction AS
(
	SELECT customer_id, min(transaction_date) AS first_transaction_date
	FROM all_transaction_history
	GROUP BY 1
)

, all_transactions AS
(
	SELECT a.*, b.first_transaction_date, date_diff(transaction_date, b.first_transaction_date, month) AS  month_difference
	FROM all_transaction_history a
	LEFT JOIN first_transaction b ON a.customer_id=b.customer_id
)

, monthly_breakdown AS
(
	SELECT 
	first_transaction_date
	--   , date_diff(transaction_date, first_transaction_date, month)+ active_month AS active_month
	, active_month
	, customer_id
	FROM
	(
		SELECT *, generate_array(0, month_difference) AS sequence_month
		FROM all_transactions
	) AS details, unnest(sequence_month) AS active_month
	WHERE 1=1
)

, cohort AS
(
	SELECT date_trunc(first_transaction_date, month) AS first_transaction_month, active_month, COUNT(DISTINCT customer_id) AS count_distinct_user
	FROM monthly_breakdown
	WHERE true
	GROUP BY 1,2
	ORDER BY 1,2
)

, cohort_zero AS
(
	SELECT *
	FROM cohort
	WHERE active_week=0
)

SELECT a.first_transaction_month, a.active_month, a.count_distinct_user/b.count_distinct_user AS retention_rate
FROM cohort a
JOIN cohort_zero b ON a.first_transaction_month=b.first_transaction_month