/****** Object:  View [dbo].[v_company_account_campaign_combined_transactions]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_company_account_campaign_combined_transactions]
GO
/****** Object:  View [dbo].[v_company_account_campaign_combined_transactions]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_company_account_campaign_combined_transactions] (
		group_id,
		group_desc,
		detail_id,
		detail_desc,
		company_id,
		account_id,
		campaign_no,
		invoice_id,
		invoice_date,
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
as

select			1 as group_id, 
				'BILLING' as group_desc, 
				2 as detail_id, 
				'TOTAL' as detail_desc,
				case fc.branch_code 
					when 'Z' then ( case fc.business_unit_id 
										when 8 then 6 
										else 2 
									end) 
					else (			case fc.business_unit_id 
										when 6 then 3 
										when 7 then 4 
										when 9 then 5 
										else 1 
									end) 
				end as company_id, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				inv.invoice_date,
				null as tran_id1,
				null as tran_id2,
				SUM(ct1.gross_amount),
				ct1.entry_date,
				ct1.tran_date,
				null,
				null,
				ct1.tran_age,
				ct1.age_code,
				null,
				null,
				fc.campaign_status
from			campaign_transaction ct1
inner join 		film_campaign fc on ct1.campaign_no = fc.campaign_no
inner join 		invoice inv on ct1.invoice_id = inv.invoice_id
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
where			ct1.tran_category in ('B', 'Z')
and				ct1.invoice_id is not null
and				ct1.invoice_id > 0
and				ct1.tran_type <> 166
and				ct1.reversal = 'N'
and				left(isnull(ct1.tran_notes, ''), 7) <> 'Takeout'
and				(
					ct1.tran_type not in (164,165)
	and				(
					(inv.invoice_date between v_inv_per.start_period and v_inv_per.inv_plan_start_period
	and				inv.invoice_date <> v_inv_per.inv_plan_start_period)
	or				(inv.invoice_date between v_inv_per.inv_plan_end_period and v_inv_per.end_period
	and				inv.invoice_date <> v_inv_per.inv_plan_end_period)) --only include traditional invoices if they are before the start date of an invoicing plan
or				(ct1.tran_type in (164,165)
	and				(inv.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period))) --only include invoicing plan invoices if they are after the start date of an invoicing plan
group by		ct1.account_id,
				ct1.invoice_id,
				ct1.campaign_no,
				ct1.tran_age,
				ct1.age_code,
				ct1.entry_date,
				ct1.tran_date,
				fc.business_unit_id,
				fc.branch_code,
				fc.campaign_status,
				inv.invoice_date
union all 

select			1 as group_id, 
				'BILLING' as group_desc, 
				2 as detail_id, 
				'TOTAL' as detail_desc,
				case fc.branch_code 
					when 'Z' then ( case fc.business_unit_id 
										when 8 then 6 
										else 2 
									end) 
					else (			case fc.business_unit_id 
										when 6 then 3 
										when 7 then 4 
										when 9 then 5 
										else 1 
									end) 
				end as company_id, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				inv.invoice_date,
				null as tran_id1,
				null as tran_id2,
				SUM(ct1.gross_amount),
				ct1.entry_date,
				ct1.tran_date,
				null,
				null,
				ct1.tran_age,
				ct1.age_code,
				null,
				null,
				fc.campaign_status
from			campaign_transaction ct1
inner join 		film_campaign fc on ct1.campaign_no = fc.campaign_no
inner join 		invoice inv on ct1.invoice_id = inv.invoice_id
where			ct1.tran_category in ('M')
and				ct1.invoice_id is not null
and				ct1.invoice_id > 0
and				left(isnull(ct1.tran_notes, ''), 7) <> 'Takeout'
and				ct1.reversal = 'N'
group by		ct1.account_id,
				ct1.invoice_id,
				ct1.campaign_no,
				ct1.tran_age,
				ct1.age_code,
				ct1.entry_date,
				ct1.tran_date,
				fc.business_unit_id,
				fc.branch_code,
				fc.campaign_status,
				inv.invoice_date
			

union all 

select			3 as group_id, 
				'PAYMENT' as group_desc,  
				2 as detail_id, 
				ct1.tran_desc as detail_desc,
				case fc.branch_code 
					when 'Z' then ( case fc.business_unit_id 
										when 8 then 6 
										else 2 
									end) 
					else (			case fc.business_unit_id 
										when 6 then 3 
										when 7 then 4 
										when 9 then 5 
										else 1 
									end) 
				end as company_id, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.tran_id as invoice_id,
				ct1.tran_date as invoice_date,
				ct1.tran_id as tran_id1,
				null as tran_id2,
				ct1.gross_amount,
				ct1.entry_date,
				ct1.tran_date,
				ct1.tran_type,
				ct1.tran_category,
				ct1.tran_age,
				ct1.age_code,
				ct1.reversal,
				ct1.show_on_statement,
				fc.campaign_status
from			campaign_transaction ct1
inner join		film_campaign fc on ct1.campaign_no = fc.campaign_no
where			ct1.tran_category in ('C', 'D')

union all

select			4 as group_id, 
				'BILLING' as group_desc, 
				2 as detail_id, 
				'Reversal' as detail_desc,
				case fc.branch_code 
					when 'Z' then ( case fc.business_unit_id 
										when 8 then 6 
										else 2 
									end) 
					else (			case fc.business_unit_id 
										when 6 then 3 
										when 7 then 4 
										when 9 then 5 
										else 1 
									end) 
				end as company_id, 
				ct1.account_id,
				ct1.campaign_no,
				ct1.invoice_id,
				inv.invoice_date, 
				ct1.tran_id,
				ct1.tran_id,
				ct1.gross_amount,
				ct1.entry_date,
				ct1.tran_date,
				tt.trantype_id,
				ct1.tran_category,
				ct1.tran_age,
				ct1.age_code,
				ct1.reversal,
				ct1.show_on_statement,
				fc.campaign_status
from			campaign_transaction ct1
inner join		transaction_type tt on ct1.tran_type = tt.trantype_id
inner join		film_campaign fc on ct1.campaign_no = fc.campaign_no
inner join		invoice inv on ct1.invoice_id = inv.invoice_id
where			ct1.tran_type <> 166
and				ct1.invoice_id is not null
and				ct1.invoice_id > 0
and				ct1.reversal = 'Y'


GO
