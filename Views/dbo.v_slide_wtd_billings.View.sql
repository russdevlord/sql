/****** Object:  View [dbo].[v_slide_wtd_billings]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_wtd_billings]
GO
/****** Object:  View [dbo].[v_slide_wtd_billings]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_wtd_billings]
AS


select  complex.complex_id 'complex_id', 
        complex.complex_name 'complex_name',
        cr.accounting_period 'accounting_period',
        sum(cr.billing_total) 'slide_wtd_nett_billings',
        1 as business_unit_id
from    slide_spot_summary cr, complex
where   cr.complex_id = complex.complex_id
and     cr.country_code = 'A'
group by complex.complex_id, 
         complex.complex_name,
         cr.accounting_period
GO
