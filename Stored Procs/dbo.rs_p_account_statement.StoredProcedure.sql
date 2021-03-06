/****** Object:  StoredProcedure [dbo].[rs_p_account_statement]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_account_statement]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_account_statement]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[rs_p_account_statement]		@account_id INT, 
											@accounting_period	datetime,
											@company_id	INT
AS

/*==============================================================*
 * DESC:- retrieves data required to display a statement        *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   5-Mar-2008 DH  Initial Build                            *
 *	2	16-Mar-2011 DYI	Changed to All Oustanding Invoices		*
 *	3	24-Mar-2011 DYI	Changed to accountID/accounting period	*
 *	3	29-Mar-2011 DYI	Added Credits							*
 *	4	17-May-2011 DYI	Added Fully Paid invoices				*
 *	5	19-May-2011 DYI	Changed allocated Payments				*
 *	6	23-May-2011 DYI	Added Reversals							*
 *	7	27-May-2011 DYI	Added dummy line if nothing 			*
 *	8	27-May-2011 DYI	Use process period, not tran_date		*
 *  9   08-Jun-2011 DYI Added view								*
 *==============================================================*/
 
 CREATE TABLE #transaction_period(
		id					INT			NOT NULL,
		invoice_id			INT			NULL,
		campaign_no			INT			NULL,
		tran_id				INT			NULL,
		tran_date			datetime	NULL,
		age_code			INT			NULL,
		gross_amount		MONEY		NULL DEFAULT 0.00,
		process_period		datetime	NULL,
		company_id			INT			NULL,
		reversal			VARCHAR(1)	NULL,
)

CREATE TABLE #invoice_campaign(
		invoice_id			INT			NOT NULL,
		campaign_no			INT			NULL,
		invoice_total		MONEY		NULL,
		tran_date			DATETIME	NULL,
		balance_current		MONEY	NULL DEFAULT 0.00,
		balance_30			MONEY	NULL DEFAULT 0.00,
		balance_60			MONEY	NULL DEFAULT 0.00,
		balance_90			MONEY	NULL DEFAULT 0.00,
		balance_120			MONEY	NULL DEFAULT 0.00,
		balance_total		MONEY	NULL DEFAULT 0.00,
		allocated_current	MONEY	NULL DEFAULT 0.00,
		allocated_30		MONEY	NULL DEFAULT 0.00,
		allocated_60		MONEY	NULL DEFAULT 0.00,
		allocated_90		MONEY	NULL DEFAULT 0.00,
		allocated_120		MONEY	NULL DEFAULT 0.00,
		allocated_total		MONEY	NULL DEFAULT 0.00,
		balance_period		MONEY	NULL DEFAULT 0.00,
		balance_prev		MONEY	NULL DEFAULT 0.00,
		allocated_period	MONEY	NULL DEFAULT 0.00,
		allocated_prev		MONEY	NULL DEFAULT 0.00,
		reversal_period		MONEY	NULL DEFAULT 0.00,
		reversal_prev		MONEY	NULL DEFAULT 0.00,
		outstanding_amount	MONEY	NULL DEFAULT 0.00,
		company_id			INT		NULL,
		account_id			INT		NULL,
		)

INSERT INTO #transaction_period
SELECT	id,
		invoice_id,
		campaign_no,
		tran_id,
		tran_date,
		age_code,
		gross_amount,
		process_period,
		company_id,
		reversal
FROM	v_transaction_periods
where	account_id = @account_id
and		company_id = @company_id
and		process_period <= @accounting_period
--AND		campaign_status IN ('P','L','X','F') --F-Expired,L-Live,P-Proposal,X-Closed
--AND		closed_date >= ap.benchmark_start
--AND		expired_date >= ap.benchmark_start

-- 1, 2 - Billing and Debit Reversal
-- 3, 4 - Credit Reversal and Payment
-- 2, 3 - Reversals ( for display purpusoes only)

INSERT INTO #invoice_campaign ( invoice_id, campaign_no, invoice_total, tran_date, 
		balance_current, balance_30, balance_60, balance_90, balance_120,
		balance_total, balance_period, balance_prev,
		allocated_current,allocated_30, allocated_60, allocated_90, allocated_120,
		allocated_total, allocated_period, allocated_prev,
		reversal_period, reversal_prev,
		company_id, account_id)
SELECT	temp.invoice_id,
		temp.campaign_no,
		inv.invoice_total,
		inv.invoice_date,
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 0 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 1 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 2 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 3 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 4 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period <= ap.benchmark_end Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period = ap.benchmark_end Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (1, 2) AND temp.process_period < ap.benchmark_start Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 0 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 1 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 2 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 3 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period <= ap.benchmark_end AND temp.age_code = 4 Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period <= ap.benchmark_end Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period = ap.benchmark_end Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (3, 4) AND temp.process_period < ap.benchmark_start Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (2, 3) AND temp.process_period = ap.benchmark_end Then temp.gross_amount else 0 end),
		SUM( CASE WHEN temp.id IN (2, 3) AND temp.process_period < ap.benchmark_start Then temp.gross_amount else 0 end),
		@company_id,
		@account_id
FROM	invoice inv,
		#transaction_period temp,
		accounting_period ap
WHERE	inv.invoice_id = temp.invoice_id
AND		temp.process_period <= ap.benchmark_end
AND		ap.benchmark_end = @accounting_period
GROUP BY temp.invoice_id,
		temp.campaign_no,
		inv.invoice_total,
		inv.invoice_date

-- Calc outstanding amounts
UPDATE	#invoice_campaign
SET		outstanding_amount = balance_total + allocated_period + allocated_prev

---- Delete fully paid invoices or with no current period payments
DELETE 
FROM	#invoice_campaign
WHERE	outstanding_amount = 0 AND allocated_period = 0

-- In case no outstanding or paid invoices i.e. nothing to display insert a dummy row 
IF (SELECT COUNT(*) FROM #invoice_campaign) = 0
	BEGIN
		INSERT  #invoice_campaign (invoice_id, company_id, account_id)
		VALUES(-100, @company_id, @account_id )
	END
	
SET FMTONLY OFF
	
-- Result set
SELECT 	temp.invoice_id,
		temp.campaign_no,
		temp.invoice_total,
		temp.tran_date,
		temp.outstanding_amount,
		temp.balance_period,
		temp.balance_prev,
		temp.balance_total,
		temp.allocated_period,
		temp.allocated_prev,
		temp.allocated_total,
		temp.reversal_period,
		temp.reversal_prev,
		reversal_total = temp.reversal_period + temp.reversal_prev,
		outstanding_current = temp.balance_current + temp.allocated_current,
		outstanding_30 = temp.balance_30 + temp.allocated_30,
		outstanding_60 = temp.balance_60 + temp.allocated_60,
		outstanding_90 = temp.balance_90 + temp.allocated_90,
		outstanding_120 = temp.balance_120 + temp.allocated_120,
		ac.account_name AS statement_name,
		ac.address_1,
		ac.address_2,
		ac.town_suburb,
		ac.state_code,
		ac.postcode,
		product_desc = CASE When temp.campaign_no IS NULL Then 'No Transactions' Else fc.product_desc End,
		cp.address_1 AS ba_address_1,
		cp.address_2 AS ba_address_2,
		cp.address_3 AS ba_address_3,
		cp.address_4 AS ba_address_4,
		cp.address_5 AS ba_address_5,
		cp.company_id,
		cp.company_desc,
		cp.division_desc,
		cp.abn,
		cp.bsb,
		cp.bank_account,
		ac.account_id,
		ac.country_code,
		fc.agency_deal,
		ac.account_type,
		accounting_period = @accounting_period
FROM	account AS ac CROSS JOIN
		company AS cp CROSS JOIN
		film_campaign AS fc CROSS JOIN
		#invoice_campaign AS temp
WHERE	(temp.account_id = ac.account_id) 
AND		(temp.campaign_no = fc.campaign_no) 
AND		(temp.company_id = cp.company_id)
ORDER BY cp.company_id, 
		temp.campaign_no, 
		temp.tran_date ASC
		
SET FMTONLY OFF

---- DEBUG - for checking totals
--SELECT	invoice_id = -100,
--		campaign_no = 0,
--		invoice_total = SUM(invoice_total),
--		accounting_period = @accounting_period,
--		balance_current = SUM(balance_current) + SUM(allocated_current),
--		balance_30 = SUM(balance_30) + SUM(allocated_30),
--		balance_60 = SUM(balance_60) + SUM(allocated_60),
--		balance_90 = SUM(balance_90) + SUM(allocated_90),
--		balance_120 = SUM(balance_120) + SUM(allocated_120),
--		paid_current = SUM(allocated_period),
--		balance_outstanding = SUM(outstanding_amount),
--		balance_forward = SUM(outstanding_amount) - SUM(balance_period) - SUM(allocated_period),
--		overdue = SUM(balance_60 + balance_90 + balance_120) + SUM(allocated_60) + SUM(allocated_90) + SUM(allocated_120)
--FROM	#invoice_campaign

--DROP TABLE  #invoice_campaign
GO
