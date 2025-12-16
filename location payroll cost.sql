/* QUESTION: For each store location, how many employees actually worked hours 
   (exclude employees with zero hours) and what is the total gross payroll cost for those employees? */

-- STEP 1: Join employees with payroll
-- - Use INNER JOIN to include only employees with payroll entries
-- - This excludes employees without hours worked

SELECT
    e.location AS store_id,                              -- Store identifier
    COUNT(DISTINCT e.employee_id) AS number_of_employees, -- Number of employees per store
    ROUND(SUM(p.gross_pay),2) AS total_payroll_cost       -- Total gross payroll per store
FROM dbo.Employees AS e
INNER JOIN dbo.Payroll AS p
    ON e.employee_id = p.employee_id
WHERE p.hours_biweekly > 0                                -- Include only employees who worked hours
GROUP BY
    e.location                                            -- Aggregate results by store
ORDER BY
    e.location;                                           -- Optional: sort results by store
