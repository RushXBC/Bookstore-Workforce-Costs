/* QUESTION: For each employee and location, calculate the total gross pay received so far.
   Include employees who have never appeared in payroll (show 0 for gross pay in that case). */

SELECT
    e.name,                                 -- Employee name
    e.location,                             -- Employee's current location (store or warehouse)
    e.role,                                 -- Employee's job role
    COALESCE(ROUND(SUM(p.gross_pay),2),0) AS gross_pay  -- Total gross pay per employee-location-role; 0 if no payroll exists
FROM dbo.Employees AS e
LEFT JOIN dbo.Payroll AS p                  -- LEFT JOIN ensures all employees are included, even if they have no payroll records
    ON e.employee_id = p.employee_id
GROUP BY
    e.name,                                 -- Group by employee name
    e.location,                             -- Group by location to see pay per store
    e.role                                  -- Group by role to see pay per job type
ORDER BY
    e.location,                             -- Sort results by location first
    e.name,                                 -- Then by employee name
    e.role;                                 -- Then by role
