/****** Object:  StoredProcedure [dbo].[p_cinema_rent_audit_billings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_rent_audit_billings]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_rent_audit_billings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinema_rent_audit_billings]		@cinema_agreement_id		integer,
													@start_date                 datetime

as

declare @error     			integer,
        @temp_date1         datetime,
        @temp_date2         datetime,        
        @end_date           datetime

select  @temp_date1 = max(date_period_fk)
from    dw_proj_bill_wtd_film
where   complex_id in (select complex_id from cinema_agreement_complex where cinema_agreement_id = @cinema_agreement_id)

select  @temp_date2 = max(date_period_fk)
from    dw_proj_bill_wtd_slide
where   complex_id in (select complex_id from cinema_agreement_complex where cinema_agreement_id = @cinema_agreement_id)

if @temp_date1 is null
    select @temp_date1 = '1-jan-1900'
    
if @temp_date2 is null
    select @temp_date2 = '1-jan-1900'    

if @temp_date1 > @temp_date2
    select @end_date = @temp_date1
else
    select @end_date = @temp_date2


--select  ap.end_date        'accounting_period',
--        cpx.complex_name    'complex_name', 
--        dwf.billing_nett    'film_nett_wtd_billings',
--        dws.total_amount    'slide_nett_wtd_billings'
--from    cinema_agreement_complex cac, 
--        complex cpx, 
--        dw_proj_bill_wtd_film dwf, 
--        dw_proj_bill_wtd_slide dws, 
--        accounting_period ap
--where   cac.active_flag = 'Y'
--and     cac.cinema_agreement_id = @cinema_agreement_id
--and     cac.complex_id = cpx.complex_id
--and     cac.complex_id *= dwf.complex_id
--and     cac.complex_id *= dws.complex_id
--and     ap.end_date *= dwf.date_period_fk
--and     ap.end_date *= dws.date_period_fk
--and     ap.end_date >= @start_date
--and     ap.end_date <= @end_date

SELECT	ap.end_date AS accounting_period, 
		cpx.complex_name AS complex_name, 
		dwf.billing_nett AS film_nett_wtd_billings, 
		dws.total_amount AS slide_nett_wtd_billings
FROM	accounting_period AS ap INNER JOIN
		dw_proj_bill_wtd_film AS dwf ON ap.end_date = dwf.date_period_fk INNER JOIN
		dw_proj_bill_wtd_slide AS dws ON ap.end_date = dws.date_period_fk CROSS JOIN
		cinema_agreement_complex AS cac CROSS JOIN
		complex AS cpx
WHERE	(cac.active_flag = 'Y') 
AND		(cac.cinema_agreement_id = @cinema_agreement_id) 
AND		(cac.complex_id = cpx.complex_id) 
AND		(cac.complex_id = dwf.complex_id) 
AND		(cac.complex_id = dws.complex_id)
AND		(ap.end_date BETWEEN @start_date AND @end_date)

return 0
GO
