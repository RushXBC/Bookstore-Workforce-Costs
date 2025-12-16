/*
QUESTION: Who are the top 5 longest-tenured employees and what is their total gross pay?

TABLES: dbo.Employees (e) LEFT JOIN dbo.Payroll (p)
JOIN TYPE: LEFT JOIN to include all employees for accurate tenure ranking.
LIMIT/RANK: Uses TOP 5 for selection and RANK() for tie-breaking and visualization.
*/

-- STEP 1: Aggregate payroll data and calculate tenure for every employee
SELECT TOP 5
	-- RANK: Assigns a rank based on tenure (longest tenure gets Rank 1).
	RANK() OVER (ORDER BY DATEDIFF(DAY,hire_date,GETDATE()) DESC) AS rank_by_tenure,
	
	e.employee_id,
	e.name AS employee_name,
	e.hire_date,

	-- TENURE: Calculates the number of days between hire date and the current date.
	DATEDIFF(DAY,hire_date,GETDATE()) AS tenure_in_days,

	-- AGGREGATION: Calculates total gross pay. COALESCE ensures 0 instead of NULL
	-- for employees who have never appeared in the payroll table (p).
	COALESCE(ROUND(SUM(p.gross_pay), 2), 0.00) AS total_gross_pay
FROM
	dbo.Employees AS e
LEFT JOIN
	dbo.Payroll AS p
	ON e.employee_id = p.employee_id
GROUP BY
	e.employee_id,
	e.name,
	e.hire_date
ORDER BY
	-- Orders the final result set by tenure to ensure the TOP 5 selected are the longest-tenured.
	DATEDIFF(DAY,hire_date,GETDATE()) DESC;