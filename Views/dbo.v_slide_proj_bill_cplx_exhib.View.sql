/****** Object:  View [dbo].[v_slide_proj_bill_cplx_exhib]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_proj_bill_cplx_exhib]
GO
/****** Object:  View [dbo].[v_slide_proj_bill_cplx_exhib]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_proj_bill_cplx_exhib]
AS

select  dwf.report_type_id,
        branch.country_code,
        exhibitor.exhibitor_id,
        exhibitor.exhibitor_name,
        complex.complex_id,
        complex.complex_name,
        dwf.date_period_fk  'accounting_period',
        sum(dwf.sound_amount) 'sound_amount',
        sum(dwf.cinema_amount) 'cinema_amount',
        sum(dwf.slide_amount) 'slide_amount',
        sum(dwf.total_amount) 'total_amount'
from    dw_proj_bill_wtd_slide dwf, complex, exhibitor, branch
where   dwf.complex_id = complex.complex_id
and     complex.exhibitor_id = exhibitor.exhibitor_id
and     complex.branch_code = branch.branch_code
group by dwf.report_type_id,
         branch.country_code,
         exhibitor.exhibitor_id,
         exhibitor.exhibitor_name,
         complex.complex_id,
         complex.complex_name,
         dwf.date_period_fk
GO
