/****** Object:  View [dbo].[v_slide_proj_bill_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_proj_bill_cplx]
GO
/****** Object:  View [dbo].[v_slide_proj_bill_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_proj_bill_cplx]
AS

select      x.finyear_end 'finyear', 
            x.benchmark_end 'accounting_period',
            v.country_code  'country_code',
            v.business_unit_id 'business_unit_id',
            v.media_product_id 'media_product_id',
            sum(isnull(v.billings,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings',
            sum(isnull(v.net_billings,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'net_billings',
            cpx.complex_id 'complex_id',
            cpx.complex_name 'complex_name',
            e.exhibitor_name 'exhibitor_name',
            e.exhibitor_id 'exhibitor_id'         
from        v_slide_proj_bill_cplx_week v,
            complex cpx,
            slide_screening_dates_xref x,
            exhibitor e
where       v.billing_date = x.screening_date
and         v.complex_id = cpx.complex_id
and         cpx.exhibitor_id = e.exhibitor_id
group by    x.finyear_end,
            x.benchmark_end,
            v.country_code,
            v.business_unit_id,
            v.media_product_id,
            cpx.complex_id,
            cpx.complex_name,
            e.exhibitor_name,
            e.exhibitor_id
GO
