/* QUESTION: For each pay period, what was the total payroll liability (Gross & Net Pay)
   and the total bank withdrawal amount recorded with the specific 'Payroll' description
   within the 14 days leading up to the pay period start?

   ANALYSIS GOAL: Flag pay periods where the required Net Pay is greater than the
   'withdrawn' amount, indicating a data labeling discrepancy in the bank ledger. */

-- STEP 1: Aggregate payroll data
-- - Calculate the total Gross Pay and Net Pay (company's liability) for each pay period.

WITH payroll_out AS
(
	SELECT
		pay_period_start,
		SUM(gross_pay) AS total_gross_pay, -- Total amount earned by employees before deductions
		SUM(net_pay) AS total_net_pay      -- Total money paid out to employees
	FROM dbo.Payroll
	GROUP BY
		pay_period_start
)

-- STEP 2: Calculate the corresponding bank withdrawal and analyze the discrepancy
SELECT
	p.pay_period_start,
	COALESCE(ROUND(p.total_gross_pay,2),0) AS total_gross_pay,
	COALESCE(ROUND(p.total_net_pay,2),0) AS total_net_pay,

    -- Calculate the filtered withdrawal amount (currently only description='Payroll')
	COALESCE(ROUND(SUM(CASE
		-- CONDITION 1: Only count transactions explicitly labeled 'Payroll'
		WHEN c.description = 'Payroll'
			-- CONDITION 2: Withdrawal must occur BEFORE the pay period starts
			AND c.date < p.pay_period_start
			-- CONDITION 3: Withdrawal must occur within 14 days BEFORE the pay period starts
			AND c.date >= DATEADD(DAY,-14,p.pay_period_start)
			THEN c.withdrawal
			END),2),0) AS withdrawn,

    -- ANALYSIS: Calculate the difference between what was owed and what was tracked
    COALESCE(ROUND(p.total_net_pay,2),0) - COALESCE(ROUND(SUM(CASE
        WHEN c.description = 'Payroll'
            AND c.date < p.pay_period_start
            AND c.date >= DATEADD(DAY,-14,p.pay_period_start)
            THEN c.withdrawal
        END),2),0) AS withdrawal_shortfall,

    -- ANALYSIS: Add a flag or text to highlight the issue
    CASE
        WHEN COALESCE(ROUND(p.total_net_pay,2),0) > COALESCE(ROUND(SUM(CASE
                WHEN c.description = 'Payroll'
                    AND c.date < p.pay_period_start
                    AND c.date >= DATEADD(DAY,-14,p.pay_period_start)
                    THEN c.withdrawal
                END),2),0)
            THEN 'DISCREPANCY: Net Pay exceeds withdrawn amount (DATA MISLABELING LIKELY).'
        ELSE 'RECONCILED (or withdrawn >= Net Pay)'
    END AS reconciliation_status

FROM payroll_out AS p
/*LEFT JOIN on 1=1 is used to effectively cross-join all payroll periods
    to all checking transactions for date range filtering. */
LEFT JOIN dbo.[Checking Balanced Dataset] AS c
	ON 1 = 1
GROUP BY
	p.pay_period_start,
	p.total_gross_pay,
	p.total_net_pay
ORDER BY
    p.pay_period_start;


/*
--- REPORT ANALYSIS AND NEXT STEPS ---

The 'withdrawal_shortfall' column indicates the amount of Net Pay liability NOT covered
by transactions explicitly labeled 'Payroll' in the checking dataset.

SUGGESTION FOR RESOLUTION:
1.  Check Missing Categories: Double-check the 'Checking Balanced Dataset' for the dates with the largest shortfalls. The main direct deposit batch is likely labeled as:
    * 'Misc operating expense' (The most likely culprit based on the available descriptions).
    * Another generic description (e.g., ACH Transfer, Bank Debit, etc.) that the system incorrectly categorized.
2.  Verify and Update the Query: If 'Misc operating expense' is confirmed to hold the main payroll funds, the 'withdrawn' calculation in the SQL query should be updated to include it:
    * Change: WHEN c.description = 'Payroll'
    * To: WHEN c.description IN ('Payroll', 'Misc operating expense')
3.  Long-Term Fix: Implement a data governance rule to ensure the primary payroll funding withdrawal is consistently labeled, preventing future discrepancies.
*/