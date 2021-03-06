/****** Object:  View [dbo].[v_wtd_billings_by_cplx_michael]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_wtd_billings_by_cplx_michael]
GO
/****** Object:  View [dbo].[v_wtd_billings_by_cplx_michael]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_wtd_billings_by_cplx_michael]
AS

select  complex.complex_id, 
        complex.complex_name,
        ap.end_date 'accounting_period',
        bu.business_unit_desc,
        isnull((select sum(isnull(fb.film_wtd_nett_billings,0))
             from   v_film_wtd_billings fb
             where  fb.complex_id = complex.complex_id
             and    fb.business_unit_id = bu.business_unit_id
             and    fb.accounting_period = ap.end_date),0) 'film_wtd_nett_billings'
from    complex, accounting_period ap, business_unit bu
where   ap.status = 'X' 
and     bu.business_unit_id in (2,3)
group by complex.complex_id, 
         complex.complex_name,
         ap.end_date,
         bu.business_unit_desc,
		  bu.business_unit_id
GO
