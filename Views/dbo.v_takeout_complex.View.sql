/****** Object:  View [dbo].[v_takeout_complex]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_takeout_complex]
GO
/****** Object:  View [dbo].[v_takeout_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_takeout_complex]
AS
select   x.finyear_end 'finyear', 
         sl.release_period 'accounting_period',
         
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         liability_type as 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum(isnull(sl.cinema_amount,0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from spot_liability sl,
         campaign_spot spot,
         film_campaign fc,
         complex cpx,
         film_screening_date_xref x
   where sl.release_period = x.benchmark_end
     and spot.campaign_no = fc.campaign_no
     and sl.complex_id = cpx.complex_id  
     and sl.spot_id = spot.spot_id
     and liability_type in (17,18,19,20)
     group by x.finyear_end, 
         sl.release_period,
         fc.branch_code,
         fc.business_unit_id,
         liability_type,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
     union
     
select   x.finyear_end 'finyear', 
         sl.release_period 'accounting_period',
         
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         liability_type as 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum(isnull(sl.cinema_amount,0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from cinelight_spot_liability sl,
         cinelight_spot spot,
         film_campaign fc,
         complex cpx,
         film_screening_date_xref x
   where sl.release_period = x.benchmark_end
     and spot.campaign_no = fc.campaign_no
     and sl.complex_id = cpx.complex_id  
     and sl.spot_id = spot.spot_id
     and liability_type in (17,18,19,20)
     group by x.finyear_end, 
         sl.release_period,
         fc.branch_code,
         fc.business_unit_id,
         liability_type,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
          union
          
select   x.finyear_end 'finyear', 
         sl.release_period 'accounting_period',
         
         fc.branch_code  'branch_code',
         fc.business_unit_id 'business_unit_id',
         liability_type as 'media_product_id',
         fc.agency_deal 'agency_deal',
         sum(isnull(sl.cinema_amount,0)) 'billings',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name'
    from inclusion_spot_liability sl,
         cinelight_spot spot,
         film_campaign fc,
         complex cpx,
         film_screening_date_xref x
   where sl.release_period = x.benchmark_end
     and spot.campaign_no = fc.campaign_no
     and sl.complex_id = cpx.complex_id  
     and sl.spot_id = spot.spot_id
     and liability_type in (17,18,19,20)
group by x.finyear_end, 
         sl.release_period,
         fc.branch_code,
         fc.business_unit_id,
         liability_type,
         fc.agency_deal,
         cpx.complex_id,
         cpx.complex_name
GO
