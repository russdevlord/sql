/****** Object:  View [dbo].[v_aaacompany_invoicing_plan_transactions]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_aaacompany_invoicing_plan_transactions]
GO
/****** Object:  View [dbo].[v_aaacompany_invoicing_plan_transactions]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO









CREATE VIEW [dbo].[v_aaacompany_invoicing_plan_transactions] (
				group_id,
				group_desc,
				detail_id,
				detail_desc,
				company_id,
				account_id,
				campaign_no,
				invoice_id,
				tran_id1,
				tran_id2,
				gross_amount,
				entry_date,
				tran_date,
				tran_type,
				tran_category,
				tran_age,
				age_code,
				reversal,
				show_on_statement,
				campaign_status)
AS
SELECT			1, 
				'BILLING', 
				2, 
				'TOTAL',
				CASE fc.branch_code When 'Z' Then ( CASE fc.business_unit_id When 8 Then 6 when 9 then 7 Else 2 End) Else ( CASE fc.business_unit_id When 6 Then 3 when 7 then 4 when 9 then 5 Else 1 End) End, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				NULL AS tran_id1,
				NULL AS tran_id2,
				SUM(TEMP.gross_amount),
				TEMP.entry_date,
				ct1.tran_date,
				NULL,
				NULL,
				ct1.tran_age,
				ct1.age_code,
				NULL,
				NULL,
				fc.campaign_status
FROM			campaign_transaction ct1,
				(SELECT			ta.to_tran_id AS tran_id, 
								ta.gross_amount AS gross_amount, 
								ta.entry_date AS entry_date
				FROM			transaction_allocation ta
				WHERE			TO_tran_id IN (	SELECT			ct1.tran_id 
												FROM			campaign_transaction ct1  
												WHERE			(ct1.tran_category = 'M'
												or				(ct1.tran_category = 'B'
												and				ct1.tran_type = 164)
												or				(ct1.tran_category = 'Z'
												and				ct1.tran_type = 165))
												and				ct1.invoice_id IS NOT NULL
												and				ct1.invoice_id > 0 )
				AND				FROM_tran_id IS NULL
				UNION ALL
				SELECT			from_tran_id  AS tran_id,
								-1 * gross_amount AS gross_amount, 
								entry_date AS entry_date
				FROM			transaction_allocation ta
				WHERE			FROM_tran_id IN (SELECT			ct1.tran_id 
												FROM			campaign_transaction ct1  
												WHERE			(ct1.tran_category = 'M'
												or				(ct1.tran_category = 'B'
												and				ct1.tran_type = 164)
												or				(ct1.tran_category = 'Z'
												and				ct1.tran_type = 165))
												and				ct1.invoice_id IS NOT NULL
												and				ct1.invoice_id > 0 )
				AND				TO_tran_id IS NULL ) AS TEMP,
				film_campaign fc
WHERE			ct1.campaign_no = fc.campaign_no
AND				ct1.tran_id = TEMP.tran_id
AND				(ct1.tran_category = 'M'
or				(ct1.tran_category = 'B'
and				ct1.tran_type = 164)
or				(ct1.tran_category = 'Z'
and				ct1.tran_type = 165))
and				ct1.campaign_no in (select campaign_no from inclusion where inclusion_type = 28 and start_date <= ct1.tran_date)
and				ct1.invoice_id IS NOT NULL
and				ct1.invoice_id > 0
GROUP BY		ct1.account_id,
				ct1.invoice_id,
				ct1.campaign_no,
				ct1.tran_age,
				ct1.age_code,
				TEMP.entry_date,
				ct1.tran_date,
				fc.business_unit_id,
				fc.branch_code,
				fc.campaign_status	
UNION ALL
SELECT	3, 
				'PAYMENT 1', 
				1, 
				'Allocation',
				CASE fc.branch_code When 'Z' Then ( CASE fc.business_unit_id When 8 Then 6 when 9 then 7 Else 2 End) Else ( CASE fc.business_unit_id When 6 Then 3 when 6 then 4 when 9 then 5 Else 1 End) End, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				ct2.tran_id,
				ct1.tran_id,
				ta.gross_amount,
				ta.entry_date,
				ct2.tran_date,
				tt.trantype_id,
				ct2.tran_category,
				ct2.tran_age,
				ct2.age_code,
				ct2.reversal,
				ct2.show_on_statement,
				fc.campaign_status
FROM			campaign_transaction ct1,
				transaction_allocation ta,
				campaign_transaction ct2,
				transaction_type tt,
				film_campaign fc
WHERE			ct1.campaign_no = fc.campaign_no
AND				ct1.tran_id = ta.to_tran_id
and				ta.from_tran_id  = ct2.tran_id
and				ta.TO_TRAN_ID IS NOT NULL
and				ct2.tran_category IN ('C'/*, 'D'*/)
and				ct1.tran_category = 'M'
and				ct1.campaign_no in (select campaign_no from inclusion where inclusion_type = 28 and start_date <= ct1.tran_date)
and				ta.gross_amount <> 0
and				ct1.invoice_id IS NOT NULL
and				ct1.invoice_id > 0
and				ct2.tran_type = tt.trantype_id
and				left (isnull(ct1.tran_notes,''), 7) != 'Takeout'
UNION ALL
SELECT			3, 
				'PAYMENT 2', 
				1, 
				'Allocation',
				CASE fc.branch_code When 'Z' Then ( CASE fc.business_unit_id When 8 Then 6 when 9 then 7 Else 2 End) Else ( CASE fc.business_unit_id When 6 Then 3 when 7 then 4 when 9 then 5 Else 1 End) End, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				ct1.tran_id,
				ct1.tran_id,
				(select -1 * sum(gross_amount) from transaction_allocation where to_tran_id = ct1.tran_id and (from_tran_id not in (select tran_id from campaign_transaction where tran_type = 166) or from_tran_id is null)),
				tpc.confimation_date,
				tpc.confimation_date,
				tt.trantype_id,
				ct1.tran_category,
				ct1.tran_age,
				ct1.age_code,
				ct1.reversal, 
				ct1.show_on_statement,
				fc.campaign_status
FROM			campaign_transaction ct1,
				transaction_type tt,
				film_campaign fc,
				transaction_payment_confirmation tpc
WHERE			ct1.campaign_no = fc.campaign_no
and				ct1.tran_id = tpc.tran_id
and				ct1.tran_category = 'B'
and				ct1.tran_type = 164
and				ct1.campaign_no in (select campaign_no from inclusion where inclusion_type = 28 and start_date <= ct1.tran_id)
and				ct1.invoice_id IS NOT NULL
and				ct1.invoice_id > 0
and				ct1.tran_type = tt.trantype_id
and				left (isnull(ct1.tran_notes,''), 7) != 'Takeout'
group by 		fc.branch_code ,
				fc.business_unit_id,
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				ct1.tran_id,
				tpc.confimation_date,
				tt.trantype_id,
				ct1.tran_category, 
				ct1.tran_age,
				ct1.age_code,
				ct1.reversal, 
				ct1.show_on_statement,
				fc.campaign_status
UNION ALL
SELECT			4, 
				'Reversal', 
				1, 
				'Allocation From',
				CASE fc.branch_code When 'Z' Then ( CASE fc.business_unit_id When 8 Then 6 when 9 then 7 Else 2 End) Else ( CASE fc.business_unit_id When 6 Then 3 when 7 then 4 when 9 then 5 Else 1 End) End, 
				ct1.account_id,
				ct1.campaign_no,
		--		ct2.invoice_id,
				ct1.invoice_id,
				ct2.tran_id,
				ct1.tran_id,
				ta.gross_amount,
				ta.entry_date,
				ct2.tran_date,
				tt.trantype_id,
				ct1.tran_category,
				ct1.tran_age,
				ct1.age_code,
				ct1.reversal,
				ct1.show_on_statement,
				fc.campaign_status
FROM	campaign_transaction ct1,
		transaction_allocation ta,
		campaign_transaction ct2,
		transaction_type tt,
		film_campaign fc
WHERE	ct1.campaign_no = fc.campaign_no
AND		ct1.tran_id = ta.to_tran_id
and		ta.from_tran_id  = ct2.tran_id
and		ta.FROM_TRAN_ID IS NOT NULL
and		(ct2.tran_category = 'M'
or			(ct2.tran_category = 'B'
and		ct2.tran_type = 164)
or			(ct2.tran_category = 'Z'
and		ct2.tran_type = 165))
and		ta.gross_amount <> 0
and				ct1.campaign_no in (select campaign_no from inclusion where inclusion_type = 28 and start_date <= ct2.tran_date)
and		ct1.invoice_id IS NOT NULL
and		ct1.invoice_id > 0
AND		ct2.tran_type = tt.trantype_id
AND		ct1.reversal = 'Y'
AND		ct2.reversal = 'Y'
UNION ALL
SELECT	4, 'Reversal', 2, 'Allocation To',
		CASE fc.branch_code When 'Z' Then ( CASE fc.business_unit_id When 8 Then 6 when 9 then 7 Else 2 End) Else ( CASE fc.business_unit_id When 6 Then 3 when 7 then 4 when 9 then 5 Else 1 End) End, 
		ct1.account_id,
		ct1.campaign_no,
		ct1.invoice_id,
		ct2.tran_id,
		ct1.tran_id,
		-1 * ta.gross_amount,
		ta.entry_date,
		ct2.tran_date,
		tt.trantype_id,
		ct1.tran_category,
		ct1.tran_age,
		ct1.age_code,
		ct1.reversal,
		ct1.show_on_statement,
		fc.campaign_status
FROM	campaign_transaction ct1,
		transaction_allocation ta,
		campaign_transaction ct2,
		transaction_type tt,
		film_campaign fc
WHERE	ct1.campaign_no = fc.campaign_no
AND		ct1.tran_id = ta.from_tran_id
and		ta.to_tran_id  = ct2.tran_id
and		ta.TO_TRAN_ID IS NOT NULL
and		(ct1.tran_category = 'M'
or			(ct1.tran_category = 'B'
and		ct1.tran_type = 164)
or			(ct1.tran_category = 'Z'
and		ct1.tran_type = 165))
and		ta.gross_amount <> 0
and		ct2.invoice_id IS NOT NULL
and		ct2.invoice_id > 0
AND		ct2.tran_type = tt.trantype_id
AND		ct1.reversal = 'Y'
AND		ct2.reversal = 'Y'
/*UNION ALL
SELECT			3, 'ACTUAL PAYMENT', 1, 'Allocation',
						CASE fc.branch_code When 'Z' Then ( CASE fc.business_unit_id When 8 Then 6 when 9 then 7 Else 2 End) Else ( CASE fc.business_unit_id When 6 Then 3 when 7 then 4 when 9 then 5 Else 1 End) End, 
						ct1.account_id,
						ct1.campaign_no,
						ct1.invoice_id,
						ct1.tran_id,
						ct1.tran_id,
						(select -1 * sum(gross_amount) from transaction_allocation where to_tran_id = ct1.tran_id and (from_tran_id not in (select tran_id from campaign_transaction where tran_type = 166) or from_tran_id is null)),
						ct1.tran_date,
						ct1.tran_date,
						tt.trantype_id,
						ct1.tran_category,
						ct1.tran_age,
						ct1.age_code,
						ct1.reversal, 
						ct1.show_on_statement,
						fc.campaign_status
FROM				campaign_transaction ct1,
						transaction_type tt,
						film_campaign fc
WHERE			ct1.campaign_no = fc.campaign_no
and					ct1.tran_type = 3
and					ct1.campaign_no in (select campaign_no from inclusion where inclusion_type = 28)
and					ct1.tran_type = tt.trantype_id
group by 		fc.branch_code ,
						fc.business_unit_id,
						ct1.account_id,
						ct1.campaign_no,
						ct1.invoice_id,
						ct1.tran_id,
						ct1.tran_date,
						tt.trantype_id,
						ct1.tran_category, 
						ct1.tran_age,
						ct1.age_code,
						ct1.reversal, 
						ct1.show_on_statement,
						fc.campaign_status*/




GO
