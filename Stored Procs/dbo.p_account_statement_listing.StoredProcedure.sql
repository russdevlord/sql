/****** Object:  StoredProcedure [dbo].[p_account_statement_listing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_statement_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_account_statement_listing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_account_statement_listing]		@account_id		int
as

/*==============================================================*
 * DESC:- retrieves data required to display a statement        *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   24-Mar-2011 DYI  Initial Build                          *
 *  2   06-Jun-2011 DYI  Onlt LIVE and Proposal Campaigns		*
 *==============================================================*/
 
CREATE TABLE #transaction_period(
		id					INT		NOT NULL,
		invoice_id			INT		NOT NULL,
		campaign_no			INT		NOT NULL,
		tran_id				INT		NOT NULL,
		tran_date			datetime	NOT NULL,
		age_code			INT		NOT NULL,
		gross_amount		MONEY	NULL DEFAULT 0.00,
		process_period		datetime	NULL,
		company_id			INT		NOT NULL
)

CREATE TABLE #process_period(
		id					INT		IDENTITY PRIMARY KEY CLUSTERED,
		account_id			INT		NOT NULL,
		company_id			INT		NOT NULL,
		accounting_period	datetime	NULL,
		outstanding_period	MONEY	NULL DEFAULT 0.00,
		billing_period		MONEY	NULL DEFAULT 0.00,
		payment_period		MONEY	NULL DEFAULT 0.00,
		reversal_period		MONEY	NULL DEFAULT 0.00,
		balance_current		MONEY	NULL DEFAULT 0.00,
		balance_30			MONEY	NULL DEFAULT 0.00,
		balance_60			MONEY	NULL DEFAULT 0.00,
		balance_90			MONEY	NULL DEFAULT 0.00,
		balance_120			MONEY	NULL DEFAULT 0.00
)

INSERT INTO #transaction_period
SELECT	1, --'BILLING',
		ct.invoice_id,
		ct.campaign_no,
		ct.tran_id,
		ct.tran_date,
		ct.age_code,
		ta.gross_amount,
		ta.process_period,
		case fc.branch_code When 'Z' Then 2 Else ( case fc.business_unit_id When 6 Then 3 Else 1 End) End
FROM	transaction_allocation ta, 
		campaign_transaction ct,
		film_campaign fc
where	ct.account_id = @account_id
AND		ct.tran_id = ISNULL(ta.from_tran_id, ta.to_tran_id) 
and		ct.campaign_no = fc.campaign_no
and		ct.gross_amount <> 0
and		ct.invoice_id IS NOT NULL
and		ct.invoice_id > 0
and		ct.tran_category NOT IN ('C','D')
and		ta.to_tran_id IS NOT NULL
AND		fc.campaign_status IN ('F','L')

INSERT INTO #transaction_period
SELECT	2, --'PAYMENT', 
		ct1.invoice_id,
		ct2.campaign_no,
		ct1.tran_id,
		ct2.tran_date,
		ct2.age_code,
		ta.gross_amount,
		ta.process_period,
		case fc.branch_code When 'Z' Then 2 Else ( case fc.business_unit_id When 6 Then 3 Else 1 End) End
FROM	campaign_transaction ct1,
		transaction_allocation ta,
		campaign_transaction ct2,
		film_campaign fc
WHERE	(( ct2.tran_category = 'C' AND ct2.tran_type IN (3))
OR		( ct2.tran_category = 'B' AND ct2.tran_type IN (75))
--OR		( ct2.tran_category = 'M' AND ct2.tran_type IN (21, 24, 25, 77, 82))
--OR		( ct2.tran_category = 'Z' AND ct2.tran_type IN (74, 89))
OR		( ct2.tran_category = 'D' AND ct2.tran_type IN (10)))
and		isnull(ct2.account_id, @account_id) = @account_id
and		ct2.reversal = 'N'
and		ct1.tran_id = ta.to_tran_id 
and		ct1.campaign_no = fc.campaign_no
and		ta.from_tran_id  = ct2.tran_id
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ct2.age_code >= 0
AND		fc.campaign_status IN ('F','L')

INSERT INTO #transaction_period
SELECT	3, --'REVERSAL',
		ct1.invoice_id,
		ct1.campaign_no,
		ta1.to_tran_id,
		ct1.tran_date,
		ct1.age_code,
		-1 * ct1.gross_amount,
		ta1.process_period,
		case fc.branch_code When 'Z' Then 2 Else ( case fc.business_unit_id When 6 Then 3 Else 1 End) End
FROM	campaign_transaction ct1,
		transaction_allocation ta1,
		film_campaign fc
WHERE	(( ct1.tran_id = ta1.to_tran_id and ta1.from_tran_id IS NOT NULL ) 
--OR	( ct1.tran_id = ta1.from_tran_id and ta1.to_tran_id IS NOT NULL )
)
and		isnull(ct1.account_id, @account_id) = @account_id
AND		ct1.reversal = 'Y'
and		ct1.campaign_no = fc.campaign_no
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ta1.gross_amount <> 0
and		ta1.from_tran_id IS NOT NULL
AND		fc.campaign_status IN ('F','L')

INSERT INTO #process_period
SELECT	@account_id,
		temp.company_id,
		temp.process_period,
		outstanding_period = SUM( temp.gross_amount),
		billing_period = SUM( case WHEN temp.id = 1 Then temp.gross_amount else 0 end),
		payment_period = SUM( case WHEN temp.id = 2 Then temp.gross_amount else 0 end),
		reversal_period = SUM( case WHEN temp.id = 3 Then temp.gross_amount else 0 end),
		balance_current = SUM( case WHEN age_code = 0 Then temp.gross_amount else 0 end),
		balance_30 = SUM( case WHEN age_code = 1 Then temp.gross_amount else 0 end),
		balance_60 = SUM( case WHEN age_code = 2 Then temp.gross_amount else 0 end),
		balance_90 = SUM( case WHEN age_code = 3 Then temp.gross_amount else 0 end),
		balance_120 = SUM( case WHEN age_code = 4 Then temp.gross_amount else 0 end)
FROM	#transaction_period temp
GROUP BY temp.process_period,
		temp.company_id
ORDER BY temp.company_id,
		temp.process_period
		
--DEBUG
--SELECT	id, 
--		invoice_id,
--		campaign_no,
--		tran_id,
--		tran_date,
--		age_code,
--		gross_amount,
--		process_period,
--		company_id
--FROM	#transaction_period
--ORDER BY 	campaign_no,
--			invoice_id,
--			process_period,
--			company_id

--SELECT *
--FROM	#process_period pp
--ORDER BY pp.company_id,
--		pp.accounting_period
--END DEBUG
		
SELECT	pp.accounting_period,
		--previous = SUM( case When pp1.id < pp.id  Then pp1.outstanding_period Else 0 End ),
		--curr_period = SUM( case When pp1.id = pp.id  Then pp1.outstanding_period Else 0 End ),
		balance_outstanding = SUM( case When pp1.id <= pp.id Then pp1.outstanding_period Else 0 End ),
		--previous_current = SUM( case When pp1.id < pp.id  Then pp1.balance_current Else 0 End ),
		--previous_30		= SUM( case When pp1.id < pp.id  Then pp1.balance_30 Else 0 End ),
		--previous_60		= SUM( case When pp1.id < pp.id  Then pp1.balance_60 Else 0 End ),
		--previous_90		= SUM( case When pp1.id < pp.id  Then pp1.balance_90 Else 0 End ),
		--previous_120	= SUM( case When pp1.id < pp.id  Then pp1.balance_120 Else 0 End ),
		--balance_current = SUM( case When pp1.id = pp.id  Then pp1.balance_current Else 0 End ),
		--balance_30		= SUM( case When pp1.id = pp.id  Then pp1.balance_30 Else 0 End ),
		--balance_60		= SUM( case When pp1.id = pp.id  Then pp1.balance_60 Else 0 End ),
		--balance_90		= SUM( case When pp1.id = pp.id  Then pp1.balance_90 Else 0 End ),
		--balance_120		= SUM( case When pp1.id = pp.id  Then pp1.balance_120 Else 0 End ),
		balance_current = SUM( case When pp1.id <= pp.id  Then pp1.balance_current Else 0 End ),
		balance_30		= SUM( case When pp1.id <= pp.id  Then pp1.balance_30 Else 0 End ),
		balance_60		= SUM( case When pp1.id <= pp.id  Then pp1.balance_60 Else 0 End ),
		balance_90		= SUM( case When pp1.id <= pp.id  Then pp1.balance_90 Else 0 End ),
		balance_120		= SUM( case When pp1.id <= pp.id  Then pp1.balance_120 Else 0 End ),
		balance_credit = ISNULL(CONVERT(MONEY, NULL), 0.0),
		pp.company_id
FROM	#process_period pp,
		#process_period pp1
where	pp.company_id = pp1.company_id
--AND		pp.company_id = 1
--AND		pp1.company_id = 1
group by pp.accounting_period,
		pp.company_id
ORDER BY pp.company_id,
		pp.accounting_period
		
DROP TABLE #transaction_period	
DROP TABLE #process_period

return 0
GO
