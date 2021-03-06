/****** Object:  View [dbo].[v_film_proj_bill_cplx_exhib]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_proj_bill_cplx_exhib]
GO
/****** Object:  View [dbo].[v_film_proj_bill_cplx_exhib]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_proj_bill_cplx_exhib]
AS

select  branch.country_code,
        exhibitor.exhibitor_id,
        exhibitor.exhibitor_name,
        complex.complex_id,
        complex.complex_name,
        dwf.date_period_fk  'accounting_period',
        sum(dwf.billing_nett) 'billing_nett',
        sum(dwf.billing_gross) 'billing_gross'
from    dw_proj_bill_wtd_film dwf, complex, exhibitor, branch
where   dwf.complex_id = complex.complex_id
and     complex.exhibitor_id = exhibitor.exhibitor_id
and     complex.branch_code = branch.branch_code
group by branch.country_code,
         exhibitor.exhibitor_id,
         exhibitor.exhibitor_name,
         complex.complex_id,
         complex.complex_name,
         dwf.date_period_fk
GO
