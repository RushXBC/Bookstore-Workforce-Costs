/* QUESTION: Which employees are currently ACTIVE or TERMINATED, 
   and for those who are TERMINATED, what was the date of their last payroll entry? */

-- STEP 1: Compute employee status
-- - Use a CTE to label employees as 'ACTIVE' if term_date is NULL, else 'TERMINATED'

WITH employee_status AS
(
	SELECT
		employee_id,                             -- Unique employee identifier
		name,                                    -- Employee name
		CASE
			WHEN term_date IS NULL THEN 'ACTIVE' -- Label as ACTIVE if no termination date
			ELSE 'TERMINATED'					 -- Otherwise, label as TERMINATED
		END AS employment_status                 -- Computed employment status
	FROM dbo.Employees
)

-- STEP 2: Join with Payroll to get last payroll entry for terminated employees
-- - LEFT JOIN ensures all employees are included, even if they have no payroll records
-- - Use MAX to get the most recent payroll date

SELECT
	e.employee_id,                               -- Employee ID
	e.name as employee_name,                                      -- Employee name
	e.employment_status,                         -- ACTIVE or TERMINATED
	CASE
		WHEN employment_status = 'TERMINATED' THEN MAX(p.pay_period_start) 
            -- Only show last payroll date for terminated employees
	END AS last_payroll_entry_if_terminated
FROM employee_status AS e
LEFT JOIN dbo.Payroll AS p						 -- Join payroll data to employee
	ON e.employee_id = p.employee_id
GROUP BY
	e.employee_id,                               -- Group by employee ID
	e.name,                                      -- Group by employee name
	e.employment_status                          -- Group by computed status
