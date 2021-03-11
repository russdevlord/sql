/****** Object:  View [dbo].[v_film_wtd_cplx_invoice_nocontra]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_wtd_cplx_invoice_nocontra]
GO
/****** Object:  View [dbo].[v_film_wtd_cplx_invoice_nocontra]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_wtd_cplx_invoice_nocontra]
AS

        
         
  select x.finyear_end 'finyear', 
         x.benchmark_end 'accounting_period',
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         cp.media_product_id 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum(isnull(cs.cinema_rate,0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from v_spots_non_proposed cs,
         film_campaign fc,
         complex cpx,
         accounting_period x,
         campaign_package cp
   where cs.billing_period = x.benchmark_end
     and cs.campaign_no = fc.campaign_no
     and cs.complex_id = cpx.complex_id
     and cs.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and cs.spot_type != 'M'
     and cs.spot_type != 'V'
     and cs.spot_type != 'D'
     and cs.spot_type != 'C'
group by x.finyear_end, 
         x.benchmark_end,
         fc.branch_code,
         fc.business_unit_id,
         cp.media_product_id,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
union
  select x.finyear_end 'finyear', 
         x.benchmark_end 'accounting_period',
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         cp.media_product_id 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum(isnull(cs.charge_rate,0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from v_spots_non_proposed_cinelight cs,
         film_campaign fc,
         complex cpx,
         accounting_period x,
         cinelight_package cp
   where cs.billing_period = x.benchmark_end
     and cs.campaign_no = fc.campaign_no
     and cs.complex_id = cpx.complex_id
     and cs.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and cs.spot_type != 'M'
     and cs.spot_type != 'V'
     and cs.spot_type != 'D'
     and cs.spot_type != 'C'
group by x.finyear_end, 
         x.benchmark_end,
         fc.branch_code,
         fc.business_unit_id,
         cp.media_product_id,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
union
  select x.finyear_end 'finyear', 
         x.benchmark_end 'accounting_period',
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         6 as 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum(isnull(cs.charge_rate,0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from v_spots_non_proposed_cinemktg cs,
         film_campaign fc,
         complex cpx,
         accounting_period x
   where cs.billing_period = x.benchmark_end
     and cs.campaign_no = fc.campaign_no
     and cs.complex_id = cpx.complex_id
     and cs.spot_type != 'M'
     and cs.spot_type != 'V'
     and cs.spot_type != 'D'
     and cs.spot_type != 'C'
group by x.finyear_end, 
         x.benchmark_end,
         fc.branch_code,
         fc.business_unit_id,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
GO
