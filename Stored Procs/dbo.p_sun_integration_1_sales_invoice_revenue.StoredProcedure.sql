/****** Object:  StoredProcedure [dbo].[p_sun_integration_1_sales_invoice_revenue]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_1_sales_invoice_revenue]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_1_sales_invoice_revenue]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[p_sun_integration_1_sales_invoice_revenue]	@accounting_period		datetime,
																	@country_code			varchar(1)
as
--VM Cinema
select			convert(char(15), '5110') as account_name,
				dbo.f_sun_date(@accounting_period) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gross_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (4, 7, 8, 103, 109) then 
						case 
							when ct.nett_amount < 0 then 'C' 
							else 'D' 
						end 
					else 
						case 
							when ct.nett_amount > 0 then 'D' 
							else 'C' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen' 
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'  
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15), (select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15), (select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id	
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			(ct.tran_category in ('B','D')
or				(ct.tran_category in ('M') 
and				ct.tran_type in (81,83,77,79,118,173,178,183,188)))
and				ct.gross_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id not in (6,7,8,11)
union all
select			convert(char(15), '8295') as account_name,
				dbo.f_sun_date ( @accounting_period ) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gst_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (4, 7, 8, 103, 109, 172, 177, 182, 187) then 
						case 
							when ct.nett_amount > 0 then 'C' 
							else 'D' 
						end 
					else 
						case	
							when ct.nett_amount < 0 then 'D' 
							else 'C' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen'
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15), (select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15), (select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			(ct.tran_category in ('B','D')
or				(ct.tran_category in ('M') 
and				ct.tran_type in (81,83,77,79,118,173,178,183,188)))
and				ct.gst_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id not in (6,7,8,11)


--VM DIGITAL
union all
select			convert(char(15), '5110') as account_name,
				dbo.f_sun_date(@accounting_period) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gross_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (172, 177, 182, 187) then 
						case 
							when ct.nett_amount < 0 then 'C' 
							else 'D' 
						end 
					else 
						case 
							when ct.nett_amount > 0 then 'D' 
							else 'C' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen' 
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'  
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15), (select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15), (select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		inclusion_tran_xref itx on ct.tran_id = itx.tran_id
inner join		inclusion inc on itx.inclusion_id = inc.inclusion_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id	
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			ct.tran_type in (170,172,173,175,177,178,180,182,183,185,187,188)
and				inclusion_type not in (38,45,52,59,40,47,54,61)
and				ct.gross_amount <> 0.0
and				ct.tran_id <> 10
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id in (11)
union all
select			convert(char(15), '8295') as account_name,
				dbo.f_sun_date ( @accounting_period ) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gst_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (172, 177, 182, 187) then
						case 
							when ct.nett_amount > 0 then 'C' 
							else 'D' 
						end 
					else 
						case	
							when ct.nett_amount < 0 then 'D' 
							else 'C' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
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
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen' 
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'  
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15), (select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15), (select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		inclusion_tran_xref itx on ct.tran_id = itx.tran_id
inner join		inclusion inc on itx.inclusion_id = inc.inclusion_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			ct.tran_type in (170,172,173,175,177,178,180,182,183,185,187,188)
and				inclusion_type not in (38,45,52,59,40,47,54,61)
and				ct.gst_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id in (11)
union all
select			convert(char(15),	case 
										when tt.trantype_id in (170,172,173) --FANDOM Billings
											then case 
													when inclusion_type in (38,45,52,59) then '0490' --other
													when inclusion_type in (40,47,54,61) then '0353' --production
													else '0350' end 
										when tt.trantype_id in (175,177,178) -- The Latch Billings
 											then case 
													when inclusion_type in (38,45,52,59) then '0490' --other
													when inclusion_type in (40,47,54,61) then '0353' --production
													else '0351' end
										when tt.trantype_id in (180,182,183) -- Thrillist Billings
											then case 
													when inclusion_type in (38,45,52,59) then '0490' --other 
													when inclusion_type in (40,47,54,61) then '0353' --production
													else '0359' end
										when tt.trantype_id in (185,187,188) -- Popsugar
											then case 
													when inclusion_type in (38,45,52,59) then '0490' --other 
													when inclusion_type in (40,47,54,61) then '0353' --production
													else '0357' end
									end) as account_name,
				dbo.f_sun_date(@accounting_period) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2), '') as filler1,
				'M' as record_type,
				convert(char(14), '') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.nett_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (4, 7, 8, 77, 90, 103, 104, 109, 110) then 
						case 
							when ct.nett_amount > 0 then 'C' 
							else 'D' 
						end 
					else 
						case 
							when ct.nett_amount < 0 then 'D' 
							else 'C' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				fc.business_unit_id as filler5,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen' 
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'  
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2,
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15),(select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15),(select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		inclusion_tran_xref itx on ct.tran_id = itx.tran_id
inner join		inclusion inc on itx.inclusion_id = inc.inclusion_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			ct.tran_type in (170,172,173,175,177,178,180,182,183,185,187,188)
and				inclusion_type not in (38,45,52,59,40,47,54,61)
and				ct.nett_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id in (11)

--Invoicing Plan Reversal
union all
select			convert(char(15), '5110') as account_name,
				dbo.f_sun_date(@accounting_period) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gross_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (4, 7, 8, 103, 109, 172, 177, 182, 187) then 
						case 
							when ct.nett_amount < 0 then 'D' 
							else 'C' 
						end 
					else 
						case 
							when ct.nett_amount > 0 then 'C' 
							else 'D' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen' 
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'  
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2, --credit
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15), (select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15), (select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id	
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			(ct.tran_category in ('B','D'))
and				ct.gross_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id not in (6, 7, 8, 11)
and				ct.tran_type not in (164,165)
and				invoice.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period --only include invoicing plan invoices if they are after the start date of an invoicing plan
union all
select			convert(char(15), '8295') as account_name,
				dbo.f_sun_date ( @accounting_period ) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2),'') as filler1,
				'M' as record_type,
				convert(char(14),'') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.gst_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (4, 7, 8, 103, 109, 172, 177, 182, 187) then 
						case 
							when ct.nett_amount > 0 then 'D' 
							else 'C' 
						end 
					else 
						case	
							when ct.nett_amount < 0 then 'C' 
							else 'D' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen'
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing' 
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out' 
									when 79 then 'Take Out'  
									when 118 then 'Sales Con' 
									when 40 then 'CineAdsbills' 
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'
									when 35 then 'TAP Billing' 
									when 4 then 'Contra' 
									when 81 then 'Digilite' 
									when 83 then 'Cinemarketing' 
									when 170 then 'Fandom' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2, --credit
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15), (select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15), (select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			(ct.tran_category in ('B','D'))
and				ct.gst_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id not in (6, 7, 8, 11)
and				ct.tran_type not in (164,165)
and				invoice.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period --only include invoicing plan invoices if they are after the start date of an invoicing plan
union all
select			convert(char(15), case 
									when tt.trantype_id in (73,74,75,80,81,93,95,96,116,161) then '0357' 
									when tt.trantype_id in (82,83,88,89,90,94,97,98,117,160) then '0359' 
									else	case 
												when fc.business_unit_id in (2,6,7,8,11) then '0350' 
												else '0351' 
											end 
								end) as account_name,
				dbo.f_sun_date(@accounting_period) as accounting_period,
				convert(char(8), ct.tran_date, 112) as transaction_date,
				convert(char(2), '') as filler1,
				'M' as record_type,
				convert(char(14), '') as filler2,
				right('000000000000000000' + replace(convert(varchar(18), convert(decimal(18,3), abs(ct.nett_amount))), '.', ''), 18) as amount,
				case 
					when tt.trantype_id in (4, 7, 8, 103, 109, 172, 177, 182, 187) then 
						case 
							when ct.nett_amount > 0 then 'D' 
							else 'C' 
						end 
					else 
						case 
							when ct.nett_amount < 0 then 'C' 
							else 'D' 
						end 
				end as debit_credit,
				convert(char(1),'') as allocation_marker,
				'CVREV' as journal_type,
				convert(char(5),'CV') as journal_source,
				'INV' + right('000000000000' + convert(varchar(12), ct.invoice_id), 12) as transaction_reference,
				convert(varchar(25), fc.product_desc) as description,
				convert(char(69),'') as filler3,
				convert(char(5),'') as conversion_code,
				convert(char(18),'') as filler4,
				convert(char(18), '') as other_curr_amount,
				fc.business_unit_id as filler5,
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
											when 170 then 35 
											when 172 then 35
											when 173 then 35 
											when 175 then 45
											when 177 then 45
											when 178 then 45
											when 180 then 47
											when 182 then 47
											when 183 then 47
											when 185 then 46
											when 187 then 46
											when 188 then 46
										end
									else 20 
								end) as t1,
				convert(char(15),case tt.trantype_id 
									when 1 then 'Onscreen' 
									when 5 then 'Onscreen' 
									when 7 then 'Onscreen' 
									when 8 then 'Onscreen' 
									when 75 then 'Digilite'
									when 73 then 'Digilite' 
									when 88 then 'Cinemarketing' 
									when 90 then 'Cinemarketing' 
									when 101 then 'Retail Billing'
									when 103 then 'Retail Billing' 
									when 77 then 'Take Out'
									when 79 then 'Take Out'
									when 118 then 'Sales Con'
									when 40 then 'CineAdsbills'
									when 164 then 'INV Plan' 
									when 166 then 'INV Plan credit'
									when 35 then 'TAP Billing'
									when 4 then 'Contra'
									when 81 then 'Digilite'
									when 83 then 'Cinemarketing'
									when 170 then 'Fandom' 
									when 170 then 'Fandom' 
									when 172 then 'Fandom' 
									when 173 then 'Fandom' 
									when 175 then 'The Latch'
									when 177 then 'The Latch'
									when 178 then 'The Latch'
									when 180 then 'Thrillist'
									when 182 then 'Thrillist'
									when 183 then 'Thrillist'
									when 185 then 'Popsugar'
									when 187 then 'Popsugar'
									when 188 then 'Popsugar'
									else convert(char(3),tt.trantype_id) 
								end) as t2, --credit
				convert(char(15), branch.state_code) as t3,
				convert(char(15), fc.agency_deal) as t4,
				convert(char(15), ct.campaign_no) as t5,
				convert(char(15), account.agency_id) as t6,
				convert(char(15),(select agency.agency_name from agency where agency.agency_id = account.agency_id)) as t7,
				convert(char(15), account.client_id) as t8,
				convert(char(15),(select client.client_name from client where client.client_id = account.client_id)) as t9,
				char(13) + char(10) as rowend
from			campaign_transaction ct
inner join		transaction_type tt on ct.tran_type = tt.trantype_id
inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
inner join		v_campaign_invoicing_periods v_inv_per on fc.campaign_no = v_inv_per.campaign_no
inner join		branch on fc.branch_code = branch.branch_code
inner join		account on ct.account_id = account.account_id
inner join		invoice on ct.invoice_id = invoice.invoice_id
inner join		statement stmt on stmt.statement_id  = ct.statement_id
where			(ct.tran_category in ('B','D'))
and				ct.nett_amount <> 0.0
and				(branch.country_code = @country_code 
or				@country_code = '')
and				stmt.accounting_period = @accounting_period
and				fc.business_unit_id not in (6, 7, 8, 11)
and				ct.tran_type not in (164,165)
and				invoice.invoice_date between v_inv_per.inv_plan_start_period and v_inv_per.end_period --only include invoicing plan invoices if they are after the start date of an invoicing plan
order by		t5,
				account_name
GO
