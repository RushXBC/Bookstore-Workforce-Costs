/* QUESTION: Is the company’s revenue growth outpacing its debt obligations? 

PURPOSE: Calculate the total quarterly interest accrued across all loans and determine 
what percentage of the total company net revenue is being consumed by that interest 
each quarter to identify potential liquidity risks. */

-- STEP 1: Aggregate daily sales into quarterly buckets
WITH quarterly_revenue AS
(
	SELECT
		DATEPART(QUARTER, date) AS quarter,
		YEAR(date) AS year,
		SUM(net_revenue) AS quarterly_total_net_revenue
	FROM dbo.Sales
	GROUP BY
		DATEPART(QUARTER, date),
		YEAR(date)
),

-- STEP 2: Aggregate loan interest by quarter
quarterly_loan_interest AS
(
	SELECT
		DATEPART(QUARTER, quarter_end) AS quarter,
		YEAR(quarter_end) AS year,
		SUM(interest_accrued) AS total_interest
	FROM dbo.Loans
	GROUP BY
		DATEPART(QUARTER, quarter_end),
		YEAR(quarter_end)
)

-- STEP 3: Join the summaries and calculate the debt-to-revenue burden
SELECT
	r.year,
	r.quarter,

	-- REVENUE: Total net revenue for the period.
	COALESCE(ROUND(r.quarterly_total_net_revenue, 2), 0) AS quarterly_total_net_revenue,

	-- DEBT: Total interest accrued. COALESCE handles quarters with no active loans.
	COALESCE(ROUND(l.total_interest, 2), 0) AS total_interest_from_loans,

	-- RATIO: Calculates the percentage of revenue consumed by interest. 
	COALESCE(ROUND((l.total_interest / r.quarterly_total_net_revenue) * 100.0, 2), 0) AS interest_to_revenue_ratio
FROM 
	quarterly_revenue AS r
LEFT JOIN 
	quarterly_loan_interest AS l
	/* DUAL-KEY JOIN: Matches both Quarter and Year so we don't 
	   accidentally mix up different years (e.g., 2023 Q1 vs 2024 Q1). */
	ON r.quarter = l.quarter
	AND r.year = l.year
ORDER BY
	r.year,
	r.quarter;