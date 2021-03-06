/****** Object:  StoredProcedure [dbo].[p_sun_integration_5_receipts_agency]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_5_receipts_agency]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_5_receipts_agency]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[p_sun_integration_5_receipts_agency] @accounting_period datetime,
															@country_code varchar(1)
AS

SELECT	account_name = CONVERT(CHAR(15), (CASE fc.business_unit_id When 6 Then '5026' when 7 then '5031' when 9 then '5024' when 8 then '5026' Else '5023' End )),
		accounting_period = dbo.f_sun_date ( ap.benchmark_end),
		transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ct.gross_amount))), '.', ''), 18),
		debit_credit = case when ct.gross_amount < 0 then 'D' else 'C' end,
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVREC',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(VARCHAR(15), ISNULL(agency.agency_name, client.client_name)),
		description = CONVERT(CHAR(25),fc.product_desc),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then case  fc.business_unit_id When 8 Then 40 when 9 then 42 else 38 end Else  ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
		t1 = CONVERT(CHAR(15),(CASE When fc.business_unit_id in (2,6,7,8) Then 10 when fc.business_unit_id = 5 then 21 when business_unit_id = 11 then 35 Else 20 End)),
		t2 = CONVERT(CHAR(15), tt.trantype_desc),
		t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
		t4 = CONVERT(CHAR(15),''),
		t5 = CONVERT(CHAR(15),ct.campaign_no),
		t6 = CONVERT(CHAR(15),''),
		t7 = CONVERT(CHAR(15),''),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)
FROM	campaign_transaction ct
		INNER JOIN	account ON account.account_id = ct.account_id 
		INNER JOIN	transaction_type AS tt ON ct.tran_type = tt.trantype_id 
		INNER JOIN	accounting_period AS ap ON ct.tran_date >= ap.benchmark_start AND ct.tran_date <= ap.benchmark_end 
		INNER JOIN	film_campaign AS fc ON ct.campaign_no = fc.campaign_no  
		INNER JOIN	branch AS branch ON fc.branch_code = branch.branch_code 
		LEFT OUTER JOIN	agency ON account.agency_id = agency.agency_id 
		LEFT OUTER JOIN	client ON account.client_id = client.client_id 
WHERE	(ct.tran_category IN ('C')) 
AND		(ap.benchmark_end = @accounting_period) 
AND		(branch.country_code = @country_code OR @country_code = '')	
and		fc.business_unit_id not in (6,7,8)
UNION all
SELECT	account_name = CONVERT(CHAR(15), '5110'),
		accounting_period = dbo.f_sun_date ( ap.benchmark_end),
		transaction_date = CONVERT(CHAR(8), ct.tran_date, 112),
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), ABS(ct.gross_amount))), '.', ''), 18),
		debit_credit = case when ct.gross_amount < 0 then 'C' else 'D' end,
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVREC',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(VARCHAR(15), ISNULL(agency.agency_name, client.client_name)),
		description = CONVERT(CHAR(25),fc.product_desc),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15),(CASE fc.branch_code When 'Z' Then case  fc.business_unit_id When 8 Then 40 when 9 then 42 else 38 end Else  ( CASE fc.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
		t1 = CONVERT(CHAR(15),(CASE When fc.business_unit_id in (2,6,7,8) Then 10 when fc.business_unit_id = 5 then 21 when business_unit_id = 11 then 35 Else 20 End)),
		t2 = CONVERT(CHAR(15), tt.trantype_desc),
		t3 = CONVERT(CHAR(15),(SELECT branch.state_code FROM branch WHERE fc.branch_code = branch.branch_code)),
		t4 = CONVERT(CHAR(15),''),
		t5 = CONVERT(CHAR(15),ct.campaign_no),
		t6 = CONVERT(CHAR(15),''),
		t7 = CONVERT(CHAR(15),''),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)
FROM	account LEFT OUTER JOIN
		agency ON account.agency_id = agency.agency_id LEFT OUTER JOIN
		client ON account.client_id = client.client_id INNER JOIN
		campaign_transaction AS ct ON account.account_id = ct.account_id INNER JOIN
		transaction_type AS tt ON ct.tran_type = tt.trantype_id INNER JOIN
		accounting_period AS ap ON ct.tran_date >= ap.benchmark_start AND ct.tran_date <= ap.benchmark_end INNER JOIN
		film_campaign AS fc ON ct.campaign_no = fc.campaign_no  INNER JOIN
		branch AS branch ON fc.branch_code = branch.branch_code
WHERE	(ct.tran_category IN ('C')) 
AND		(ap.benchmark_end = @accounting_period) 
AND		(branch.country_code = @country_code OR @country_code = '')	
and  fc.business_unit_id not in (6,7,8)
ORDER BY t5, account_name
GO
