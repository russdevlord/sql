/****** Object:  StoredProcedure [dbo].[p_sun_integration_2_sales_invoice_agency]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_2_sales_invoice_agency]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_2_sales_invoice_agency]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[p_sun_integration_2_sales_invoice_agency]	@accounting_period datetime,
																	@country_code varchar(1)
as

select			convert(char(15),	case fc.business_unit_id 
										when 3 then '0617' 
										when 9 then '0617' 
										else (	case	tt.trantype_id 
													when 6 then '0617' 
													when 2 then '0616' 
													when 74 then '0618' 
													when 89 then '0619'
													when 171 then '0616'
													when 174 then '0616'
													when 176 then '0617'
													when 177 then '0617'
													when 181 then '0619'
													when 184 then '0619'
													when 186 then '0618'
													when 189 then '0618'
													else '0616' 
												end) 
									end) as account_name,
				dbo.f_sun_date (ap.benchmark_end) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date ,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.nett_amount))), '.', ''), 18) as amount,
				convert(char(1), case when ct.nett_amount < 0 then 'D' else 'C' end) as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVAAC' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				convert(char(14),'') as filler5,	
				convert(char(15),case fc.branch_code 
									when 'Z' then 
										case fc.business_unit_id 
											when 8 then 40 
											when 9 then 42 
											else 38 
										end 
									else 
										case fc.business_unit_id 
											when 6 then 61 
											when 7 then 63 
											when 9 then 64 
											else 66 
										end 
									end) as t0,
				convert(char(15),case 
									when fc.business_unit_id in (2,6,7,8) then 10 
									when fc.business_unit_id = 5 then 21 
									when business_unit_id = 11 then 
										case tt.trantype_id 
											when 171 then 35 
											when 174 then 35
											when 176 then 45
											when 179 then 45
											when 181 then 47
											when 184 then 47
											when 186 then 46
											when 189 then 46
								end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 2 then 'A/Comm Onscreen' 
									when 6 then 'A/Comm Onscreen' 
									when 74 then 'A/Comm Digilite' 
									when 89 then 'A/Comm-Cinemkg' 
									when 102 then 'A/Comm Retail' 
									when 41 then 'A/Comm CineAds' 
									when 165 then 'A/Comm INV Plan' 
									when 166 then 'Credit INV Plan'  
									when 36 then 'A/Comm TAP' 
									when 31 then 'A/Comm Generic' 
									when 171 then 'A/Comm Fandom' 
									when 174 then 'A/Comm Fandom' 
									when 176 then 'A/Comm The Latch' 
									when 179 then 'A/Comm The Latch' 
									when 181 then 'A/Comm Thrillist' 
									when 184 then 'A/Comm Thrillist' 
									when 186 then 'A/Comm Popsugar' 
									when 189 then 'A/Comm Popsugar' 
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15),'') as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15),'') as t6,
				convert(char(15),'') as t7,
				convert(char(15),'') as t8,
				convert(char(15),'') as t9,
				char(13) + char(10) as rowend
from			account 
left outer join	agency on account.agency_id = agency.agency_id 
left outer join	client on account.client_id = client.client_id 
inner join		campaign_transaction as ct 
inner join		transaction_type as tt on ct.tran_type = tt.trantype_id 
inner join		accounting_period as ap on ct.tran_date >= ap.benchmark_start and ct.tran_date <= ap.benchmark_end 
inner join		film_campaign as fc on ct.campaign_no = fc.campaign_no 
inner join		branch on fc.branch_code = branch.branch_code on account.account_id = ct.account_id 
inner join		invoice on ct.invoice_id = invoice.invoice_id
where			(ct.tran_category in ('Z')  
or				ct.tran_type in (31))
and				ct.tran_type <> 166
and				ap.benchmark_end = @accounting_period
and				(branch.country_code = @country_code 
or				@country_code = '')
and				fc.business_unit_id not in (6,7,8)
union all
select			convert(char(15), '8295') as account_name,
				dbo.f_sun_date (ap.benchmark_end) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date ,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gst_amount))), '.', ''), 18) as amount,
				convert(char(1), case when ct.gst_amount < 0 then 'D' else 'C' end) as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVAAC' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				convert(char(14),'') as filler5,
				convert(char(15),case fc.branch_code 
									when 'Z' then
										case fc.business_unit_id 
											when 8 then 40 
											when 9 then 42 
											else 38 
										end 
									else 
										case fc.business_unit_id 
											when 6 then 61 
											when 7 then 63 
											when 9 then 64 
											else 66 
										end 
								end) as t0,
				convert(char(15),case 
									when fc.business_unit_id in (2,6,7,8) then 10 
									when fc.business_unit_id = 5 then 21 
									when business_unit_id = 11 then 
										case tt.trantype_id 
											when 171 then 35 
											when 174 then 35
											when 176 then 45
											when 179 then 45
											when 181 then 47
											when 184 then 47
											when 186 then 46
											when 189 then 46
								end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 2 then 'A/Comm Onscreen' 
									when 6 then 'A/Comm Onscreen' 
									when 74 then 'A/Comm Digilite' 
									when 89 then 'A/Comm-Cinemkg' 
									when 102 then 'A/Comm Retail' 
									when 41 then 'A/Comm CineAds' 
									when 165 then 'A/Comm INV Plan' 
									when 166 then 'Credit INV Plan'  
									when 36 then 'A/Comm TAP' 
									when 31 then 'A/Comm Generic' 
									when 171 then 'A/Comm Fandom' 
									when 174 then 'A/Comm Fandom' 
									when 176 then 'A/Comm The Latch' 
									when 179 then 'A/Comm The Latch' 
									when 181 then 'A/Comm Thrillist' 
									when 184 then 'A/Comm Thrillist' 
									when 186 then 'A/Comm Popsugar' 
									when 189 then 'A/Comm Popsugar' 
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15),'') as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15),'') as t6,
				convert(char(15),'') as t7,
				convert(char(15),'') as t8,
				convert(char(15),'') as t9,
				char(13) + char(10) as rowend
from			account 
left outer join	agency on account.agency_id = agency.agency_id 
left outer join	client on account.client_id = client.client_id 
inner join		campaign_transaction as ct 
inner join		transaction_type as tt on ct.tran_type = tt.trantype_id 
inner join		accounting_period as ap on ct.tran_date >= ap.benchmark_start and ct.tran_date <= ap.benchmark_end 
inner join		film_campaign as fc on ct.campaign_no = fc.campaign_no 
inner join		branch on fc.branch_code = branch.branch_code on account.account_id = ct.account_id 
inner join		invoice on ct.invoice_id = invoice.invoice_id
where			(ct.tran_category in ('Z')  
or				ct.tran_type in (31))
and				ct.tran_type <> 166
and				ap.benchmark_end = @accounting_period
and				(branch.country_code = @country_code 
or				@country_code = '')
and				fc.business_unit_id not in (6,7,8)
union all
select			convert(char(15), '5110') as account_name,
				dbo.f_sun_date ( ap.benchmark_end) as accounting_period ,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gross_amount))), '.', ''), 18) as amount,
				convert(char(1), case when ct.gross_amount > 0 then 'D' else 'C' end ) as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVAAC' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				convert(char(14),'') as filler5,
				convert(char(15),case fc.branch_code 
									when 'Z' then 
										case fc.business_unit_id
											when 8 then 40 
											when 9 then 42 
											else 38
										end 
									else 
										case fc.business_unit_id 
											when 6 then 61 
											when 7 then 63 
											when 9 then 64 
											else 66 
										end
								end) as t0,
				convert(char(15),case 
									when fc.business_unit_id in (2,6,7,8) then 10 
									when fc.business_unit_id = 5 then 21 
									when business_unit_id = 11 then 
										case tt.trantype_id 
											when 171 then 35 
											when 174 then 35
											when 176 then 45
											when 179 then 45
											when 181 then 47
											when 184 then 47
											when 186 then 46
											when 189 then 46
								end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 2 then 'A/Comm Onscreen' 
									when 6 then 'A/Comm Onscreen' 
									when 74 then 'A/Comm Digilite' 
									when 89 then 'A/Comm-Cinemkg' 
									when 102 then 'A/Comm Retail' 
									when 41 then 'A/Comm CineAds' 
									when 165 then 'A/Comm INV Plan' 
									when 166 then 'Credit INV Plan'  
									when 36 then 'A/Comm TAP' 
									when 31 then 'A/Comm Generic' 
									when 171 then 'A/Comm Fandom' 
									when 174 then 'A/Comm Fandom' 
									when 176 then 'A/Comm The Latch' 
									when 179 then 'A/Comm The Latch' 
									when 181 then 'A/Comm Thrillist' 
									when 184 then 'A/Comm Thrillist' 
									when 186 then 'A/Comm Popsugar' 
									when 189 then 'A/Comm Popsugar' 
									else convert(char(3),tt.trantype_id) 
								end) as t2, 
				convert(char(15), branch.state_code) as t3,
				convert(char(15),'') as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15),'') as t6,
				convert(char(15),'') as t7,
				convert(char(15),'') as t8,
				convert(char(15),'') as t9,
				char(13) + char(10) as rowend
from			account 
left outer join	agency on account.agency_id = agency.agency_id 
left outer join	client on account.client_id = client.client_id 
inner join		campaign_transaction as ct 
inner join		transaction_type as tt on ct.tran_type = tt.trantype_id 
inner join		accounting_period as ap on ct.tran_date >= ap.benchmark_start and ct.tran_date <= ap.benchmark_end 
inner join		film_campaign as fc on ct.campaign_no = fc.campaign_no 
inner join		branch on fc.branch_code = branch.branch_code on account.account_id = ct.account_id 
inner join		invoice on ct.invoice_id = invoice.invoice_id
where			(ct.tran_category in ('Z')  
or				ct.tran_type in (31))
and				ct.tran_type <> 166
and				ap.benchmark_end = @accounting_period
and				(branch.country_code = @country_code 
or				@country_code = '')
and				fc.business_unit_id not in (6,7,8)
union all
select			convert(char(15),	case fc.business_unit_id 
										when 3 then '0617' 
										when 9 then '0617' 
										else (	case	tt.trantype_id 
													when 6 then '0617' 
													when 2 then '0616' 
													when 74 then '0618' 
													when 89 then '0619' 
													when 171 then '0616'
													when 174 then '0616'
													when 176 then '0617'
													when 177 then '0617'
													when 181 then '0619'
													when 184 then '0619'
													when 186 then '0618'
													when 189 then '0618'
													else '0616' 
												end) 
									end) as account_name,
				dbo.f_sun_date (ap.benchmark_end) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date ,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.nett_amount))), '.', ''), 18) as amount,
				convert(char(1), case when ct.nett_amount < 0 then 'C' else 'D' end) as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVAAC' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				convert(char(14),'') as filler5,	
				convert(char(15),case fc.branch_code 
									when 'Z' then 
										case fc.business_unit_id 
											when 8 then 40 
											when 9 then 42 
											else 38 
										end 
									else 
										case fc.business_unit_id 
											when 6 then 61 
											when 7 then 63 
											when 9 then 64 
											else 66 
										end 
									end) as t0,
				convert(char(15),case 
									when fc.business_unit_id in (2,6,7,8) then 10 
									when fc.business_unit_id = 5 then 21 
									when business_unit_id = 11 then 
										case tt.trantype_id 
											when 171 then 35 
											when 174 then 35
											when 176 then 45
											when 179 then 45
											when 181 then 47
											when 184 then 47
											when 186 then 46
											when 189 then 46
								end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 2 then 'A/Comm Onscreen' 
									when 6 then 'A/Comm Onscreen' 
									when 74 then 'A/Comm Digilite' 
									when 89 then 'A/Comm-Cinemkg' 
									when 102 then 'A/Comm Retail' 
									when 41 then 'A/Comm CineAds' 
									when 165 then 'A/Comm INV Plan' 
									when 166 then 'Credit INV Plan'  
									when 36 then 'A/Comm TAP' 
									when 31 then 'A/Comm Generic' 
									when 171 then 'A/Comm Fandom' 
									when 174 then 'A/Comm Fandom' 
									when 176 then 'A/Comm The Latch' 
									when 179 then 'A/Comm The Latch' 
									when 181 then 'A/Comm Thrillist' 
									when 184 then 'A/Comm Thrillist' 
									when 186 then 'A/Comm Popsugar' 
									when 189 then 'A/Comm Popsugar' 
									else convert(char(3),tt.trantype_id) 
								end) as t2, --credit
				convert(char(15), branch.state_code) as t3,
				convert(char(15),'') as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15),'') as t6,
				convert(char(15),'') as t7,
				convert(char(15),'') as t8,
				convert(char(15),'') as t9,
				char(13) + char(10) as rowend
from			account 
left outer join	agency on account.agency_id = agency.agency_id 
left outer join	client on account.client_id = client.client_id 
inner join		campaign_transaction as ct 
inner join		transaction_type as tt on ct.tran_type = tt.trantype_id 
inner join		accounting_period as ap on ct.tran_date >= ap.benchmark_start and ct.tran_date <= ap.benchmark_end 
inner join		film_campaign as fc on ct.campaign_no = fc.campaign_no 
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
inner join		branch on fc.branch_code = branch.branch_code on account.account_id = ct.account_id 
inner join		invoice on ct.invoice_id = invoice.invoice_id
where			ct.tran_category in ('Z')  
and				ct.tran_type not in (164,165, 166)
and				invoice.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period --only include invoicing plan invoices if they are after the start date of an invoicing plan
and				ap.benchmark_end = @accounting_period
and				(branch.country_code = @country_code 
or				@country_code = '')
and				fc.business_unit_id not in (6,7,8)
union all
select			convert(char(15), '8295') as account_name,
				dbo.f_sun_date (ap.benchmark_end) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date ,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gst_amount))), '.', ''), 18) as amount,
				convert(char(1), case when ct.gst_amount < 0 then 'C' else 'D' end) as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVAAC' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				convert(char(14),'') as filler5,
				convert(char(15),case fc.branch_code 
									when 'Z' then
										case fc.business_unit_id 
											when 8 then 40 
											when 9 then 42 
											else 38 
										end 
									else 
										case fc.business_unit_id 
											when 6 then 61 
											when 7 then 63 
											when 9 then 64 
											else 66 
										end 
								end) as t0,
				convert(char(15),case 
									when fc.business_unit_id in (2,6,7,8) then 10 
									when fc.business_unit_id = 5 then 21 
									when business_unit_id = 11 then 
										case tt.trantype_id 
											when 171 then 35 
											when 174 then 35
											when 176 then 45
											when 179 then 45
											when 181 then 47
											when 184 then 47
											when 186 then 46
											when 189 then 46
								end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 2 then 'A/Comm Onscreen' 
									when 6 then 'A/Comm Onscreen' 
									when 74 then 'A/Comm Digilite' 
									when 89 then 'A/Comm-Cinemkg' 
									when 102 then 'A/Comm Retail' 
									when 41 then 'A/Comm CineAds' 
									when 165 then 'A/Comm INV Plan' 
									when 166 then 'Credit INV Plan'  
									when 36 then 'A/Comm TAP' 
									when 31 then 'A/Comm Generic' 
									when 171 then 'A/Comm Fandom' 
									when 174 then 'A/Comm Fandom' 
									when 176 then 'A/Comm The Latch' 
									when 179 then 'A/Comm The Latch' 
									when 181 then 'A/Comm Thrillist' 
									when 184 then 'A/Comm Thrillist' 
									when 186 then 'A/Comm Popsugar' 
									when 189 then 'A/Comm Popsugar' 
									else convert(char(3),tt.trantype_id) 
								end) as t2, --credit
				convert(char(15), branch.state_code) as t3,
				convert(char(15),'') as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15),'') as t6,
				convert(char(15),'') as t7,
				convert(char(15),'') as t8,
				convert(char(15),'') as t9,
				char(13) + char(10) as rowend
from			account 
left outer join	agency on account.agency_id = agency.agency_id 
left outer join	client on account.client_id = client.client_id 
inner join		campaign_transaction as ct 
inner join		transaction_type as tt on ct.tran_type = tt.trantype_id 
inner join		accounting_period as ap on ct.tran_date >= ap.benchmark_start and ct.tran_date <= ap.benchmark_end 
inner join		film_campaign as fc on ct.campaign_no = fc.campaign_no 
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
inner join		branch on fc.branch_code = branch.branch_code on account.account_id = ct.account_id 
inner join		invoice on ct.invoice_id = invoice.invoice_id
where			ct.tran_category in ('Z')  
and				ct.tran_type not in (164,165, 166)
and				invoice.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period --only include invoicing plan invoices if they are after the start date of an invoicing plan
and				ap.benchmark_end = @accounting_period
and				(branch.country_code = @country_code 
or				@country_code = '')
and				fc.business_unit_id not in (6,7,8)
union all
select			convert(char(15), '5110') as account_name,
				dbo.f_sun_date ( ap.benchmark_end) as accounting_period ,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gross_amount))), '.', ''), 18) as amount,
				convert(char(1), case when ct.gross_amount > 0 then 'C' else 'D' end ) as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVAAC' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				convert(char(14),'') as filler5,
				convert(char(15),case fc.branch_code 
									when 'Z' then 
										case fc.business_unit_id
											when 8 then 40 
											when 9 then 42 
											else 38
										end 
									else 
										case fc.business_unit_id 
											when 6 then 61 
											when 7 then 63 
											when 9 then 64 
											else 66 
										end
								end) as t0,
				convert(char(15),case 
									when fc.business_unit_id in (2,6,7,8) then 10 
									when fc.business_unit_id = 5 then 21 
									when business_unit_id = 11 then 35 
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 2 then 'A/Comm Onscreen' 
									when 6 then 'A/Comm Onscreen' 
									when 74 then 'A/Comm Digilite' 
									when 89 then 'A/Comm-Cinemkg' 
									when 102 then 'A/Comm Retail'  
									when 41 then 'A/Comm CineAds' 
									when 165 then 'A/Comm INV Plan' 
									when 166 then 'Credit INV Plan' 
									when 36 then 'A/Comm TAP' 
									when 31 then 'A/Comm Generic' 
									when 171 then 'A/Comm Fandom' 
									else convert(char(3),tt.trantype_id) 
								end) as t2, --credit
				convert(char(15), branch.state_code) as t3,
				convert(char(15),'') as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15),'') as t6,
				convert(char(15),'') as t7,
				convert(char(15),'') as t8,
				convert(char(15),'') as t9,
				char(13) + char(10) as rowend
from			account 
left outer join	agency on account.agency_id = agency.agency_id 
left outer join	client on account.client_id = client.client_id 
inner join		campaign_transaction as ct 
inner join		transaction_type as tt on ct.tran_type = tt.trantype_id 
inner join		accounting_period as ap on ct.tran_date >= ap.benchmark_start and ct.tran_date <= ap.benchmark_end 
inner join		film_campaign as fc on ct.campaign_no = fc.campaign_no 
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
inner join		branch on fc.branch_code = branch.branch_code on account.account_id = ct.account_id 
inner join		invoice on ct.invoice_id = invoice.invoice_id
where			ct.tran_category in ('Z')  
and				ct.tran_type not in (164,165, 166)
and				invoice.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period --only include invoicing plan invoices if they are after the start date of an invoicing plan
and				ap.benchmark_end = @accounting_period
and				(branch.country_code = @country_code 
or				@country_code = '')
and				fc.business_unit_id not in (6,7,8)

order by		t5, 
				filler1, 
				account_name,
				accounting_period,
				transaction_date 
GO
