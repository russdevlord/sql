/****** Object:  View [dbo].[v_slide_proj_bill_bad_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_proj_bill_bad_campaign]
GO
/****** Object:  View [dbo].[v_slide_proj_bill_bad_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_proj_bill_bad_campaign]
AS


select  v1.country_code,
        v1.exhibitor_id,
        v1.exhibitor_name,
        v1.complex_id,
        v1.complex_name,
        v1.accounting_period,
        ap.finyear_end,
        v1.total_amount 'total_billings',
        -1.0 *  isnull ( (   select  total_amount
                from    v_slide_proj_bill_cplx_exhib
                where   report_type_id = 2
                and     accounting_period = v1.accounting_period
                and     complex_id = v1.complex_id ) ,0) 'bad_billings'
from    v_slide_proj_bill_cplx_exhib v1, accounting_period ap
where   v1.report_type_id = 1
and     v1.accounting_period = ap.end_date
GO
