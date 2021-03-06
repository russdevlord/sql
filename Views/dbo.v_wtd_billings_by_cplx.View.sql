/****** Object:  View [dbo].[v_wtd_billings_by_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_wtd_billings_by_cplx]
GO
/****** Object:  View [dbo].[v_wtd_billings_by_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_wtd_billings_by_cplx]
AS

select  complex.complex_id, 
        complex.complex_name,
        ap.end_date 'accounting_period',
        bu.business_unit_desc,
        isnull((select sum(isnull(sb.slide_wtd_nett_billings,0))
             from   v_slide_wtd_billings sb
             where  sb.complex_id = complex.complex_id
             and    sb.business_unit_id = bu.business_unit_id
             and    sb.accounting_period = ap.end_date),0) 'slide_wtd_nett_billings',
        isnull((select sum(isnull(fb.film_wtd_nett_billings,0))
             from   v_film_wtd_billings fb
             where  fb.complex_id = complex.complex_id
             and    fb.business_unit_id = bu.business_unit_id
             and    fb.accounting_period = ap.end_date),0) 'film_wtd_nett_billings'
from    complex, accounting_period ap, business_unit bu
where   ap.status = 'X' 
and     bu.business_unit_id < 4
group by complex.complex_id, 
         complex.complex_name,
         ap.end_date,
         bu.business_unit_desc,
		  bu.business_unit_id
GO
