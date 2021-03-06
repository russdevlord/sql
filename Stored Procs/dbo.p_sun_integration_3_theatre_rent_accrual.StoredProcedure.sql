/****** Object:  StoredProcedure [dbo].[p_sun_integration_3_theatre_rent_accrual]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_3_theatre_rent_accrual]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_3_theatre_rent_accrual]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p_sun_integration_3_theatre_rent_accrual]	@accounting_period datetime,
																	@country_code varchar(1)
AS

SELECT	account_name = CONVERT(CHAR(15), CASE crs.revenue_source When 'F' Then '0611' When 'D' Then '0612' when 'L' then '0612' When 'C' Then '0613' Else '0614' End),
		accounting_period = dbo.f_sun_date ( @accounting_period ),
		transaction_date = CONVERT(CHAR(8), GetDate(), 112), --cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), abs(SUM(cap.percentage_entitlement * cl.liability_amount)))), '.', ''), 18),
		debit_credit = 'D',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRA',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), complex.complex_name), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15),(CASE complex.branch_code When 'Z' Then (CASE cl.business_unit_id When 9 then 42 Else 38 End) Else ( CASE cl.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crs.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), cl.business_unit_id),
		t3 = CONVERT(CHAR(15), branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), crs.revenue_source),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15),''),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)/***/
FROM	cinema_liability cl,
		cinema_agreement ca,
		cinema_agreement_policy	cap,
		complex,
		exhibitor,
		branch,
		cinema_revenue_source crs
WHERE	cl.accounting_period = @accounting_period
and		cap.complex_id = complex.complex_id
and		crs.revenue_source = cap.revenue_source
and		cl.revenue_source = cap.revenue_source
and		complex.branch_code = branch.branch_code
AND		branch.country_code = @country_code 
and		cl.country_code = @country_code
and		cl.complex_id = cap.complex_id
and		cap.cinema_agreement_id = ca.cinema_agreement_id
and		cl.liability_amount > 0
and     isnull(cap.processing_start_date, '1-jan-1900') <= @accounting_period
and     isnull(cap.processing_end_date, '1-jan-2050') >= @accounting_period
and		cl.origin_period >= isnull(cap.rent_inclusion_start, '1-jan-1900')
and		cl.origin_period <= isnull(cap.rent_inclusion_end, @accounting_period)
AND		complex.exhibitor_id = exhibitor.exhibitor_id
AND		exhibitor.exhibitor_id NOT IN ( 576)
and	    cap.policy_status_code = 'A'
and     cap.active_flag = 'Y'
and		cap.suspend_contribution = 'N'
and     ca.agreement_status ='A'
and     cap.rent_mode in ('C','B','I','S')
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		cl.accounting_period,
		cap.complex_id,
		ca.agreement_no,
		complex.complex_name,
		complex.branch_code,
		cl.country_code,
		cl.business_unit_id,
		crs.revenue_source,
		branch.state_code
union all
SELECT	account_name = CONVERT(CHAR(15), CASE crs.revenue_source When 'F' Then '0611' When 'D' Then '0612' when 'L' then '0612' When 'C' Then '0613' Else '0614' End),
		accounting_period = dbo.f_sun_date ( @accounting_period ),
		transaction_date = CONVERT(CHAR(8), GetDate(), 112), --cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), abs(SUM(cap.percentage_entitlement * cl.liability_amount)))), '.', ''), 18),
		debit_credit = 'C',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRA',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), complex.complex_name), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15),(CASE complex.branch_code When 'Z' Then (CASE cl.business_unit_id When 9 then 42 Else 38 End) Else ( CASE cl.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crs.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), cl.business_unit_id),
		t3 = CONVERT(CHAR(15), branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), crs.revenue_source),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15),''),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)/***/
FROM	cinema_liability cl,
		cinema_agreement ca,
		cinema_agreement_policy	cap,
		complex,
		exhibitor,
		branch,
		cinema_revenue_source crs
WHERE	cl.accounting_period = @accounting_period
and		cap.complex_id = complex.complex_id
and		crs.revenue_source = cap.revenue_source
and		cl.revenue_source = cap.revenue_source
and		complex.branch_code = branch.branch_code
AND		branch.country_code = @country_code 
and		cl.country_code = @country_code
and		cl.complex_id = cap.complex_id
and		cap.cinema_agreement_id = ca.cinema_agreement_id
and		cl.liability_amount < 0
and     isnull(cap.processing_start_date, '1-jan-1900') <= @accounting_period
and     isnull(cap.processing_end_date, '1-jan-2050') >= @accounting_period
and		cl.origin_period >= isnull(cap.rent_inclusion_start, '1-jan-1900')
and		cl.origin_period <= isnull(cap.rent_inclusion_end, @accounting_period)
AND		complex.exhibitor_id = exhibitor.exhibitor_id
AND		exhibitor.exhibitor_id NOT IN ( 576)
and	    cap.policy_status_code = 'A'
and     cap.active_flag = 'Y'
and		cap.suspend_contribution = 'N'
and     ca.agreement_status ='A'
and     cap.rent_mode in ('C','B','I','S')
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		cl.accounting_period,
		cap.complex_id,
		ca.agreement_no,
		complex.complex_name,
		complex.branch_code,
		cl.country_code,
		cl.business_unit_id,
		crs.revenue_source,
		branch.state_code

union all

SELECT	account_name = CONVERT(CHAR(15), CASE ca.cinema_agreement_id When 403 Then '8102' when 548 then '8102'  Else '8101' End),
		accounting_period = dbo.f_sun_date ( @accounting_period ),
		transaction_date = CONVERT(CHAR(8), GetDate(), 112), --cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), abs(SUM(cap.percentage_entitlement * cl.liability_amount)))), '.', ''), 18),
		debit_credit = 'C',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRA',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), complex.complex_name), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15),(CASE complex.branch_code When 'Z' Then (CASE cl.business_unit_id When 9 then 42 Else 38 End) Else ( CASE cl.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crs.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), cl.business_unit_id),
		t3 = CONVERT(CHAR(15), branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), ''),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15),''),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)
FROM	cinema_liability cl,
		cinema_agreement ca,
		cinema_agreement_policy	cap,
		complex,
		exhibitor,
		branch,
		cinema_revenue_source crs
WHERE	cl.accounting_period = @accounting_period
and		cap.complex_id = complex.complex_id
and		crs.revenue_source = cap.revenue_source
and		cl.revenue_source = cap.revenue_source
and		complex.branch_code = branch.branch_code
AND		branch.country_code = @country_code 
and		cl.country_code = @country_code
and		cl.complex_id = cap.complex_id
and		cap.cinema_agreement_id = ca.cinema_agreement_id
and		cl.liability_amount > 0
and     isnull(cap.processing_start_date, '1-jan-1900') <= @accounting_period
and     isnull(cap.processing_end_date, '1-jan-2050') >= @accounting_period
and		cl.origin_period >= isnull(cap.rent_inclusion_start, '1-jan-1900')
and		cl.origin_period <= isnull(cap.rent_inclusion_end, @accounting_period)
AND		complex.exhibitor_id = exhibitor.exhibitor_id
AND		exhibitor.exhibitor_id NOT IN ( 576)
and	    cap.policy_status_code = 'A'
and     cap.active_flag = 'Y'
and		cap.suspend_contribution = 'N'
and     ca.agreement_status ='A'
and     cap.rent_mode in ('C','B','I','S')
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		cl.accounting_period,
		cap.complex_id,
		ca.agreement_no,
		complex.complex_name,
		complex.branch_code,
		cl.country_code,
		cl.business_unit_id,
		crs.revenue_source,
		branch.state_code
union all
SELECT	account_name = CONVERT(CHAR(15), CASE ca.cinema_agreement_id When 403 Then '8102' when 548 then '8102' Else '8101' End),
		accounting_period = dbo.f_sun_date ( @accounting_period ),
		transaction_date = CONVERT(CHAR(8), GetDate(), 112), --cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), abs(SUM(cap.percentage_entitlement * cl.liability_amount)))), '.', ''), 18),
		debit_credit = 'D',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRA',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), complex.complex_name), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15),(CASE complex.branch_code When 'Z' Then (CASE cl.business_unit_id When 9 then 42 Else 38 End) Else ( CASE cl.business_unit_id When 6 Then 61 when 7 then 63 when 9 then 64 Else 66 End) End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crs.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), cl.business_unit_id),
		t3 = CONVERT(CHAR(15), branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), ''),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15),''),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)
FROM	cinema_liability cl,
		cinema_agreement ca,
		cinema_agreement_policy	cap,
		complex,
		exhibitor,
		branch,
		cinema_revenue_source crs
WHERE	cl.accounting_period = @accounting_period
and		cap.complex_id = complex.complex_id
and		crs.revenue_source = cap.revenue_source
and		cl.revenue_source = cap.revenue_source
and		complex.branch_code = branch.branch_code
AND		branch.country_code = @country_code 
and		cl.country_code = @country_code
and		cl.complex_id = cap.complex_id
and		cap.cinema_agreement_id = ca.cinema_agreement_id
and		cl.liability_amount < 0
and     isnull(cap.processing_start_date, '1-jan-1900') <= @accounting_period
and     isnull(cap.processing_end_date, '1-jan-2050') >= @accounting_period
and		cl.origin_period >= isnull(cap.rent_inclusion_start, '1-jan-1900')
and		cl.origin_period <= isnull(cap.rent_inclusion_end, @accounting_period)
AND		complex.exhibitor_id = exhibitor.exhibitor_id
AND		exhibitor.exhibitor_id NOT IN ( 576)
and	    cap.policy_status_code = 'A'
and     cap.active_flag = 'Y'
and		cap.suspend_contribution = 'N'
and     ca.agreement_status ='A'
and     cap.rent_mode in ('C','B','I','S')
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		cl.accounting_period,
		cap.complex_id,
		ca.agreement_no,
		complex.complex_name,
		complex.branch_code,
		cl.country_code,
		cl.business_unit_id,
		crs.revenue_source,
		branch.state_code

ORDER BY  t6, debit_credit, account_name
GO
