USE [production]
GO
/****** Object:  View [dbo].[v_film_net_cplx_billings]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_net_cplx_billings]
AS

  select x.finyear_end 'finyear', 
         x.benchmark_end 'accounting_period',
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         cp.media_product_id 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum((isnull(cs.charge_rate,0) * (1 - fc.commission) ) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from v_spots_non_proposed cs,
         film_campaign fc,
         complex cpx,
         film_screening_date_xref x,
         campaign_package cp
   where cs.billing_date = x.screening_date
     and cs.campaign_no = fc.campaign_no
     and cs.complex_id = cpx.complex_id
     and cs.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and cs.spot_type != 'M'
     and cs.spot_type != 'V'
     and cs.spot_type != 'D'
group by x.finyear_end, 
         x.benchmark_end,
         fc.branch_code,
         fc.business_unit_id,
         cp.media_product_id,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
GO
