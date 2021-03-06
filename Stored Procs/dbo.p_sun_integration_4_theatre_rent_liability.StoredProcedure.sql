/****** Object:  StoredProcedure [dbo].[p_sun_integration_4_theatre_rent_liability]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_4_theatre_rent_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_4_theatre_rent_liability]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[p_sun_integration_4_theatre_rent_liability] @accounting_period datetime,
																	@country_code varchar(1)
AS

SELECT	account_name = CONVERT(CHAR(15), CASE crpa.revenue_source When 'F' Then '0611' When 'D' Then '0612' when 'L' then '0612' When 'C' Then '0613' Else '0614' End),
		accounting_period = dbo.f_sun_date ( @accounting_period ),
		transaction_date = CONVERT(CHAR(8), cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), SUM(ABS(CAT2.nett_amount)))), '.', ''), 18),
		debit_credit = 'D',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRL',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), ca.agreement_desc), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15), (CASE @country_code When 'Z' Then 38 Else 66 End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crpa.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), ''), --temp_cae.business_unit_id),
		t3 = CONVERT(CHAR(15), ''), --branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), crpa.revenue_source),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15), crp.payment_method_code),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)--,
		--crpa.revenue_source,
		--temp_cae.business_unit_id,
		--crp.payment_method_code,
		--Allocation = SUM(CAT2.gross_amount),
		--Payment = SUM(CAT.gross_amount)
FROM	cinema_agreement ca,
		transaction_type,
		cinema_agreement_transaction cat,
		cinema_agreement_transaction cat2,
		cinema_rent_payment crp,
		cinema_rent_payment_allocation crpa,
		( SELECT	cinema_agreement_id,
					origin_period = max(origin_period),
					revenue_source,
					tran_id
			FROM	cinema_agreement_entitlement,
					complex,
					branch
			WHERE	accounting_period = @accounting_period
			AND		cinema_agreement_entitlement.complex_id = complex.complex_id
			and		complex.branch_code = branch.branch_code
			AND		( branch.country_code = @country_code or @country_code = '')		
			GROUP BY cinema_agreement_id,
					revenue_source,
					tran_id ) AS temp_cae
WHERE	ca.cinema_agreement_id = cat.cinema_agreement_id
AND		ca.agreement_status = 'A'
and		cat.tran_id = crp.tran_id
AND		cat.accounting_period = @accounting_period
AND		cat.trantype_id = transaction_type.trantype_id
and		transaction_type.tran_category_code = 'P'
--and		temp_cae.revenue_source <> 'L'
and		crpa.payment_tran_id = crp.tran_id
AND		crpa.entitlement_tran_id = cat2.tran_id
AND		ca.cinema_agreement_id = temp_cae.cinema_agreement_id
AND		temp_cae.revenue_source = crpa.revenue_source
and		temp_cae.tran_id = cat2.tran_id
--and		cae.revenue_source = dbo.f_cap_check(cae.cinema_agreement_id,cae.complex_id,cae.revenue_source)
--and		ca.cinema_agreement_id NOT IN ( 357/*, 513, 549*/)
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		ca.agreement_no,
		cat.tran_date,
		crpa.revenue_source,
		crp.payment_method_code
UNION
SELECT	account_name = CONVERT(CHAR(15), '8293'),
		accounting_period = dbo.f_sun_date (@accounting_period ),
		transaction_date = CONVERT(CHAR(8), cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), SUM(ABS(cat2.gst_amount)))), '.', ''), 18),
		debit_credit = 'D',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRL',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), ca.agreement_desc), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15), (CASE @country_code When 'Z' Then 38 Else 66 End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crpa.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), ''), --temp_cae.business_unit_id),
		t3 = CONVERT(CHAR(15), ''), --branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), crpa.revenue_source),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15), crp.payment_method_code),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)
FROM	cinema_agreement ca,
		transaction_type,
		cinema_agreement_transaction cat,
		cinema_agreement_transaction cat2,
		cinema_rent_payment crp,
		cinema_rent_payment_allocation crpa,
		( SELECT	cinema_agreement_id,
					origin_period = max(origin_period),
					revenue_source,
					tran_id
			FROM	cinema_agreement_entitlement,
					complex,
					branch
			WHERE	accounting_period = @accounting_period
			AND		cinema_agreement_entitlement.complex_id = complex.complex_id
			and		complex.branch_code = branch.branch_code
			AND		( branch.country_code = @country_code or @country_code = '')		
			GROUP BY cinema_agreement_id,
					revenue_source,
					tran_id ) AS temp_cae
WHERE	ca.cinema_agreement_id = cat.cinema_agreement_id
AND		ca.agreement_status = 'A'
and		cat.tran_id = crp.tran_id
AND		cat.accounting_period = @accounting_period
AND		cat.trantype_id = transaction_type.trantype_id
and		transaction_type.tran_category_code = 'P'
and		crpa.payment_tran_id = crp.tran_id
AND		crpa.entitlement_tran_id = cat2.tran_id
AND		ca.cinema_agreement_id = temp_cae.cinema_agreement_id
AND		temp_cae.revenue_source = crpa.revenue_source
and		temp_cae.tran_id = cat2.tran_id
--and		cae.revenue_source = dbo.f_cap_check(cae.cinema_agreement_id,cae.complex_id,cae.revenue_source)
--and		ca.cinema_agreement_id NOT IN ( 357/*, 513, 549*/)
--and		temp_cae.revenue_source <> 'L'
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		ca.agreement_no,
		cat.tran_date,
		crpa.revenue_source,
		crp.payment_method_code
UNION
SELECT	account_name = CONVERT(CHAR(15), CASE crp.payment_method_code When 'C' Then 
		( CASE CA.cinema_agreement_id When 474 Then 'TRC' + RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3) ELSE '5023' End)
		Else 'TRC' + RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3) End),
		accounting_period = dbo.f_sun_date ( @accounting_period),
		transaction_date = CONVERT(CHAR(8), cat.tran_date, 112), 
		filler1 = CONVERT(CHAR(2),''),
		record_type = 'M',
		filler2 = CONVERT(CHAR(14),''),
		amount = RIGHT('000000000000000000' + REPLACE(CONVERT(VARCHAR(18), CONVERT(DECIMAL(18,3), SUM(ABS(cat2.gross_amount)))), '.', ''), 18),
		debit_credit = 'C',
		allocation_marker = CONVERT(CHAR(1),''),
		journal_type = 'CVTRL',
		journal_source = CONVERT(CHAR(5),'CV'),
		transaction_reference = CONVERT(CHAR(15), ''),
		description = LEFT(CONVERT(VARCHAR(25), ca.agreement_desc), 25),
		filler3 = CONVERT(CHAR(69),''),
		conversion_code = CONVERT(CHAR(5),''),
		filler4 = CONVERT(CHAR(18),''),
		other_curr_amount = CONVERT(CHAR(18), ''),
		filler5 = CONVERT(CHAR(14),''),
		t0 = CONVERT(CHAR(15), (CASE @country_code When 'Z' Then 38 Else 66 End)),
		t1 = CONVERT(CHAR(15), (CASE ca.cinema_agreement_id when 526 then 70 else CASE crpa.revenue_source When 'F' Then '10' When 'D' Then '20' when 'L' then '22' When 'C' Then '10' Else '10' End end)),
		t2 = CONVERT(CHAR(15), ''), --temp_cae.business_unit_id),
		t3 = CONVERT(CHAR(15), ''), --branch.state_code),
		t4 = CONVERT(CHAR(15), RIGHT('000' + CONVERT(VARCHAR(3), ca.cinema_agreement_id), 3)),
		t5 = CONVERT(CHAR(15), crpa.revenue_source),
		t6 = CONVERT(CHAR(15), ca.agreement_desc),
		t7 = CONVERT(CHAR(15), crp.payment_method_code),
		t8 = CONVERT(CHAR(15),''),
		t9 = CONVERT(CHAR(15),''),
		rowend = char(13) + char(10)
FROM	cinema_agreement ca,
		transaction_type,
		cinema_agreement_transaction cat,
		cinema_agreement_transaction cat2,
		cinema_rent_payment crp,
		cinema_rent_payment_allocation crpa,
		( SELECT	cinema_agreement_id,
					origin_period = max(origin_period),
					revenue_source,
					tran_id
			FROM	cinema_agreement_entitlement,
					complex,
					branch
			WHERE	accounting_period = @accounting_period
			AND		cinema_agreement_entitlement.complex_id = complex.complex_id
			and		complex.branch_code = branch.branch_code
			AND		( branch.country_code = @country_code or @country_code = '')		
			GROUP BY cinema_agreement_id,
					revenue_source,
					tran_id ) AS temp_cae
WHERE	ca.cinema_agreement_id = cat.cinema_agreement_id
AND		ca.agreement_status = 'A'
and		cat.tran_id = crp.tran_id
AND		cat.accounting_period = @accounting_period
AND		cat.trantype_id = transaction_type.trantype_id
and		transaction_type.tran_category_code = 'P'
and		crpa.payment_tran_id = crp.tran_id
AND		crpa.entitlement_tran_id = cat2.tran_id
AND		ca.cinema_agreement_id = temp_cae.cinema_agreement_id
AND		temp_cae.revenue_source = crpa.revenue_source
and		temp_cae.tran_id = cat2.tran_id
--and		cae.revenue_source = dbo.f_cap_check(cae.cinema_agreement_id,cae.complex_id,cae.revenue_source)
--and		ca.cinema_agreement_id NOT IN ( 357/*, 513, 549*/)
--and		temp_cae.revenue_source <> 'L'
GROUP BY ca.cinema_agreement_id,
		ca.agreement_desc,
		ca.agreement_no,
		cat.tran_date,
		crpa.revenue_source,
		crp.payment_method_code
ORDER BY t5, t3, account_name
GO
