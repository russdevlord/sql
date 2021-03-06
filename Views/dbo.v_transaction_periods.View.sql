/****** Object:  View [dbo].[v_transaction_periods]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_transaction_periods]
GO
/****** Object:  View [dbo].[v_transaction_periods]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_transaction_periods] (
		id,
		account_id,
		invoice_id,
		campaign_no,
		tran_id,
		tran_type,
		tran_date,
		age_code,
		gross_amount,
		process_period,
		company_id,
		reversal,
		show_on_statement)
AS

SELECT	1, -- Billing Part 1 
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct1.tran_id,
		tt.trantype_id,
		ct1.tran_date,
		ct1.age_code,
		ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		campaign_transaction ct2,
		transaction_allocation ta,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
AND		ct1.tran_id = ta.TO_tran_id
and		isnull(ta.FROM_tran_id, ct1.tran_id) = ct2.tran_id
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ta.gross_amount <> 0
AND		ta.FROM_tran_id IS NULL
and		ct1.tran_category NOT IN ('C', 'D')
AND		ct1.tran_type = tt.trantype_id
and		ct1.show_on_statement = 'Y'
AND		ct1.reversal = 'N'
UNION ALL
SELECT	1, -- Billing Part 2
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct1.tran_id,
		tt.trantype_id,
		ct1.tran_date,
		ct1.age_code,
		-1 * ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		campaign_transaction ct2,
		transaction_allocation ta,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
AND		ct1.tran_id = ta.FROM_tran_id
AND		isnull(ta.TO_tran_id, ct1.tran_id) = ct2.tran_id
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ta.gross_amount <> 0
AND		ta.TO_tran_id IS NULL
and		ct1.tran_category NOT IN ('C', 'D')
AND		ct1.tran_type = tt.trantype_id
and		ct2.show_on_statement = 'Y'
AND		ct2.reversal = 'N'
UNION ALL
SELECT	2, -- Reversal Part 1 (Debit step)
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct1.tran_id,
		tt.trantype_id,
		ct1.tran_date,
		ct1.age_code,
		ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		campaign_transaction ct2,
		transaction_allocation ta,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
AND		ct1.tran_id = ta.FROM_tran_id
AND		ta.TO_tran_id = ct2.tran_id
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ta.gross_amount <> 0
and		ct1.tran_category NOT IN ('C', 'D')
AND		ta.FROM_tran_id IS NOT NULL
AND		ta.TO_tran_id IS NOT NULL
AND		ct1.reversal = 'Y'
AND		ct1.tran_type = tt.trantype_id
UNION ALL
SELECT	3, -- Reversal Part 2 (Credit step)
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct1.tran_id,
		tt.trantype_id,
		ct1.tran_date,
		ct1.age_code,
		-1  * ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		campaign_transaction ct2,
		transaction_allocation ta,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
AND		ct1.tran_id = ta.TO_tran_id
AND		ta.FROM_tran_id = ct2.tran_id
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ta.gross_amount <> 0
and		ct1.tran_category NOT IN ('C', 'D')
AND		ta.FROM_tran_id IS NOT NULL
AND		ta.TO_tran_id IS NOT NULL
AND		ct1.reversal = 'Y'
AND		ct1.tran_type = tt.trantype_id
UNION ALL
SELECT	4, -- Payment Allocation
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct2.tran_id,
		tt.trantype_id,
		ct2.tran_date,
		ct1.age_code,
		ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		transaction_allocation ta,
		campaign_transaction ct2,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
and		ct1.tran_id = ta.to_tran_id
and		ta.from_tran_id  = ct2.tran_id
and		ct2.tran_category IN ('C', 'D')
and		ta.gross_amount <> 0
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
--and		ct1.show_on_statement = 'Y'
--and		ct2.show_on_statement = 'Y'
and		ct1.reversal = 'N'
AND		ct2.tran_type = tt.trantype_id
UNION ALL 
SELECT	5, -- Misc Allocation (Part 2)
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct2.tran_id,
		tt.trantype_id,
		ct2.tran_date,
		ct1.age_code,
		ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		transaction_allocation ta,
		campaign_transaction ct2,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
and		ct2.tran_category NOT IN ( 'C', 'D')
and		ta.gross_amount <> 0
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ct2.show_on_statement = 'Y'
and		ct1.reversal = 'N'
AND		ct2.tran_type = tt.trantype_id
AND		ct1.tran_category = ct2.tran_category
AND		ct1.tran_id = ta.TO_tran_id 
AND		ta.FROM_tran_id = ct2.tran_id
UNION ALL
SELECT	6, -- Misc Allocation (Part 3) 
		ct1.account_id,
		ct1.invoice_id,
		ct1.campaign_no,
		ct2.tran_id,
		tt.trantype_id,
		ct2.tran_date,
		ct1.age_code,
		-1 * ta.gross_amount,
		ta.process_period,
		CASE fc.branch_code When 'Z' Then 2 Else ( CASE fc.business_unit_id When 6 Then 3 Else 1 End) End,
		ct1.reversal,
		ct1.show_on_statement
FROM	campaign_transaction ct1,
		transaction_allocation ta,
		campaign_transaction ct2,
		film_campaign fc,
		transaction_type tt
WHERE	ct1.campaign_no = fc.campaign_no
and		ct2.tran_category NOT IN ( 'C', 'D')
and		ta.gross_amount <> 0
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
and		ct2.show_on_statement = 'Y'
and		ct1.reversal = 'N'
AND		ct1.tran_type = tt.trantype_id
AND		ct1.tran_category = ct2.tran_category
AND		ct1.tran_id = ta.FROM_tran_id 
AND		ta.TO_tran_id = ct2.tran_id
GO
