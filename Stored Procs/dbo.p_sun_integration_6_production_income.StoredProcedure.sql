/****** Object:  StoredProcedure [dbo].[p_sun_integration_6_production_income]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_6_production_income]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_6_production_income]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p_sun_integration_6_production_income] @accounting_period datetime,
																	@country_code varchar(1)
AS

select			account_name = CONVERT(CHAR(15), 
				CASE When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (1,2,3,19) Then '0353'
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (1,2,3,19) Then '0355'
				When inc.inclusion_type IN (4) Then '0354' 
				When inc.inclusion_type IN (6) Then '0362'
				When inc.inclusion_type IN (7) Then '0360' 
				When inc.inclusion_type IN (8) Then '0356'
				When inc.inclusion_type IN (22) Then '0361' ELSE '' End ),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ct.nett_amount))), '.', ''), 18),
				debit_credit = 'C',
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), ct.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),(SELECT tt.trantype_desc FROM transaction_type tt WHERE ct.tran_type = tt.trantype_id)),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), ct.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
		--		inclusion_type inct,
		--		inclusion_type_group intg,
		--		inclusion_category incc,
		--		media_product,
				accounting_period ap,
				campaign_transaction ct,
				film_campaign fc,
				branch
where 			inc.inclusion_type IN (1,2,3,4,6,7,8,19,22)
--and			inct.inclusion_type_group IN ( 'P' , 'M')
--AND			inc.inclusion_type = inct.inclusion_type
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
--and			inct.media_product_id = media_product.media_product_id
--and			inct.inclusion_type_group = intg.inclusion_type_group
--and			inc.inclusion_category = incc.inclusion_category
and				inc.tran_id = ct.tran_id
and				inc.campaign_no = fc.campaign_no
and				fc.branch_code = branch.branch_code
and				fc.business_unit_id not in (6,7,8)
AND				( branch.country_code = @country_code or @country_code = '')
UNION
SELECT			account_name = CONVERT(CHAR(15), '8295'),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ct.gst_amount))), '.', ''), 18),
				debit_credit = 'C',
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), ct.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),(SELECT tt.trantype_desc FROM transaction_type tt WHERE ct.tran_type = tt.trantype_id)),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), ct.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
				accounting_period ap,
				campaign_transaction ct,
				film_campaign fc,
				branch
where 			inc.inclusion_type IN (1,2,3,4,6,7,8,19,22)
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
and					inc.tran_id = ct.tran_id
and				inc.campaign_no = fc.campaign_no
and				fc.branch_code = branch.branch_code
and				fc.business_unit_id not in (6,7,8)
AND				(branch.country_code = @country_code 
or				@country_code = '')
UNION
SELECT			account_name = CONVERT(CHAR(15), '5110'),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ct.gross_amount))), '.', ''), 18),
				debit_credit = 'D',
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), ct.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),(SELECT tt.trantype_desc FROM transaction_type tt WHERE ct.tran_type = tt.trantype_id)),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), ct.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
				accounting_period ap,
				campaign_transaction ct,
				film_campaign fc,
				branch
where 			inc.inclusion_type IN (1,2,3,4,6,7,8,19,22)
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
and				inc.tran_id = ct.tran_id
and				inc.campaign_no = fc.campaign_no
and				fc.branch_code = branch.branch_code
and				fc.business_unit_id not in (6,7,8)
AND				(branch.country_code = @country_code 
or				@country_code = '')
UNION
SELECT			account_name = CONVERT(CHAR(15), 
				CASE When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (2,19) Then '0622'
				When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (3) Then '0623'
				When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (1) Then '0624'	
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (2,19) Then '0626'
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (3) Then '0627'
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (1) Then '0628'
				When inc.inclusion_type IN (4) Then '0629'
				When inc.inclusion_type IN (6) Then '0630' ELSE '' End ),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(inc.vm_cost_amount))), '.', ''), 18),
				debit_credit = 'D',
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), ct.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),(SELECT tt.trantype_desc FROM transaction_type tt WHERE ct.tran_type = tt.trantype_id)),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), ct.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
				accounting_period ap,
				campaign_transaction ct,
				film_campaign fc,
				branch
where 			inc.inclusion_type IN (1,2,3,4,6,7,8,19,22)
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
and				inc.tran_id = ct.tran_id
and				inc.campaign_no = fc.campaign_no
and				ISNULL(inc.vm_cost_amount, 0) <> 0
and				fc.branch_code = branch.branch_code
and				fc.business_unit_id not in (6,7,8)
and				(branch.country_code = @country_code 
or				@country_code = '')
UNION
SELECT			account_name = CONVERT(CHAR(15),'8215' ),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(inc.vm_cost_amount))), '.', ''), 18),
				debit_credit = 'C',
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), ct.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),(SELECT tt.trantype_desc FROM transaction_type tt WHERE ct.tran_type = tt.trantype_id)),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), ct.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
				accounting_period ap,
				campaign_transaction ct,
				film_campaign fc,
				branch
where 			inc.inclusion_type IN (1,2,3,4,6,7,8,19,22)
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
and				inc.tran_id = ct.tran_id
and				inc.campaign_no = fc.campaign_no
and				ISNULL(inc.vm_cost_amount, 0) <> 0
and				fc.branch_code = branch.branch_code
and				fc.business_unit_id not in (6,7,8)
and				( branch.country_code = @country_code or @country_code = '')
UNION
SELECT			account_name = CONVERT(CHAR(15), 
				CASE When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (2,19) Then '0622'
				When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (3) Then '0623'
				When fc.business_unit_id IN (2,6) AND inc.inclusion_type IN (1) Then '0624'	
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (2,19) Then '0626'
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (3) Then '0627'
				When fc.business_unit_id IN (3,5) AND inc.inclusion_type IN (1) Then '0628'
				When inc.inclusion_type IN (4) Then '0629'
				When inc.inclusion_type IN (6) Then '0630' ELSE '' End ),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), inc.inclusion_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
		--		nett_amount = ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ),
		--		vm_cost_amount = ISNULL(inc.vm_cost_amount, 0),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ) - ISNULL(inc.vm_cost_amount, 0)))), '.', ''), 18),
				debit_credit = CASE When ISNULL(inc.vm_cost_amount, 0) > ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ) Then 'C' Else 'D' End,
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), inc.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),''),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), inc.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
				accounting_period ap,
				film_campaign fc,
				branch
where 			inc.inclusion_type IN (1,2,3,4,6,19) --,7,8,22
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
and				inc.campaign_no = fc.campaign_no
AND				ABS(ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ) - ISNULL(inc.vm_cost_amount, 0)) <> 0
and				fc.branch_code = branch.branch_code
AND				( branch.country_code = @country_code or @country_code = '')
and				fc.business_unit_id not in (6,7,8)
UNION
SELECT			account_name = CONVERT(CHAR(15), '8215' ),
				accounting_period = dbo.f_sun_date ( ap.benchmark_end),
				transaction_date = CONVERT(CHAR(8), inc.inclusion_date, 112),
				filler1 = CONVERT(CHAR(2),''),
				record_type = 'M',
				filler2 = CONVERT(CHAR(14),''),
		--		nett_amount = ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ),
		--		vm_cost_amount = ISNULL(inc.vm_cost_amount, 0),
				amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ) - ISNULL(inc.vm_cost_amount, 0)))), '.', ''), 18),
				debit_credit = CASE When ISNULL(inc.vm_cost_amount, 0) > ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ) Then 'D' Else 'C' End,
				allocation_marker = CONVERT(CHAR(1),''),
				journal_type = 'CVPRO',
				journal_source = CONVERT(CHAR(5),'CV'),
				transaction_reference = CONVERT(CHAR(15), inc.campaign_no),
				description = CONVERT(CHAR(25),(SUBSTRING(ISNULL(vm_inclusion_desc, ''), CASE When PATINDEX('%PO#%', vm_inclusion_desc) > 0 Then PATINDEX('%PO#%', vm_inclusion_desc) + 3 Else 1 End, 20))),
				filler3 = CONVERT(CHAR(69),''),
				conversion_code = CONVERT(CHAR(5),''),
				filler4 = CONVERT(CHAR(18),''),
				other_curr_amount = CONVERT(CHAR(18), ''),
				filler5 = CONVERT(CHAR(14),''),
				t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then 38 Else ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
				t1 = CONVERT(CHAR(15),(CASE fc.agency_deal When 'Y' Then 10 Else 20 End)),
				t2 = CONVERT(CHAR(15),''),
				t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
				t4 = CONVERT(CHAR(15),''),
				t5 = CONVERT(CHAR(15), inc.campaign_no),
				t6 = CONVERT(CHAR(15),''),
				t7 = CONVERT(CHAR(15),''),
				t8 = CONVERT(CHAR(15),''),
				t9 = CONVERT(CHAR(15),''),
				rowend = char(13) + char(10)
from			inclusion inc,
				accounting_period ap,
				film_campaign fc,
				branch
where			inc.inclusion_type IN (1,2,3,4,6,19) --,7,8,22
and				inc.inclusion_date >= ap.benchmark_start
and				inc.inclusion_date <= ap.benchmark_end
and				ap.benchmark_end = @accounting_period
and				inc.campaign_no = fc.campaign_no
and				ABS(ISNULL(( SELECT ct.nett_amount FROM campaign_transaction ct WHERE inc.tran_id = ct.tran_id ), 0 ) - ISNULL(inc.vm_cost_amount, 0)) <> 0
and				fc.branch_code = branch.branch_code
and				fc.business_unit_id not in (6,7,8)
and				( branch.country_code = @country_code 
or				@country_code = '')
GO
