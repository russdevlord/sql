USE [production]
GO
/****** Object:  View [dbo].[v_wtd_billings_by_cplx_nocontra]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_wtd_billings_by_cplx_nocontra]
AS

select  complex.complex_id, 
        complex.complex_name,
        ap.end_date 'accounting_period',
        bu.business_unit_desc,
        mp.media_product_desc,
        isnull((select sum(isnull(fb.film_wtd_nett_billings,0))
             from   v_film_wtd_billings_nocontra fb
             where  fb.complex_id = complex.complex_id
             and    fb.business_unit_id = bu.business_unit_id
             and    fb.media_product_id = mp.media_product_id
             and    fb.accounting_period = ap.end_date),0) 'film_wtd_nett_billings'
from    complex, accounting_period ap, business_unit bu, media_product mp
where   ap.status = 'X' 
and     bu.system_use_only = 'N'
and     mp.system_use_only = 'N'
group by complex.complex_id, 
         complex.complex_name,
         ap.end_date,
         bu.business_unit_desc,
         mp.media_product_desc,
         mp.media_product_id,
		  bu.business_unit_id
GO
