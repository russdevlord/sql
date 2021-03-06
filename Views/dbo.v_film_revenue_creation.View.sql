/****** Object:  View [dbo].[v_film_revenue_creation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_revenue_creation]
GO
/****** Object:  View [dbo].[v_film_revenue_creation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_film_revenue_creation]
as
select spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         inc_typ.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period as accounting_period,
         c.currency_code,
         isnull(sum(sl.spot_amount),0) as spot_amount, 
         isnull(sum(sl.cinema_amount),0) as cinema_amount,
         mp.revenue_source,
         count(distinct spot.spot_id) as no_spots,
         0 as duration
    from inclusion_spot spot,
         inclusion_spot_liability sl,
         film_campaign fc,
         branch b,
         country c,
         inclusion inc,
		 inclusion_type inc_typ,
		 media_product mp
   where sl.spot_id = spot.spot_id
     and fc.campaign_no = spot.campaign_no
     and b.branch_code = fc.branch_code
     and c.country_code = b.country_code
     and spot.inclusion_id = inc.inclusion_id
     and inc.campaign_no = fc.campaign_no
     and spot.campaign_no = inc.campaign_no     
	 and mp.media_product_id = inc_typ.media_product_id
	 and inc_typ.inclusion_type = inc.inclusion_type
	 and inc_typ.inclusion_type  = 5
	and liability_type not in (3,10)
group by spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         inc_typ.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         c.currency_code,
         mp.revenue_source
         union all
          select spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         c.currency_code,
         isnull(sum(sl.spot_amount),0),
         isnull(sum(sl.cinema_amount),0),
         cp.revenue_source,
         count(distinct spot.spot_id) as no_spots,
         cp.duration as duration
    from cinelight_spot spot,
         cinelight_spot_liability sl,
         film_campaign fc,
         branch b,
         country c,
         cinelight_package cp
   where sl.spot_id = spot.spot_id
     and fc.campaign_no = spot.campaign_no
     and b.branch_code = fc.branch_code
     and c.country_code = b.country_code
     and spot.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and spot.campaign_no = cp.campaign_no     
	and liability_type not in (3,10)
group by spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         c.currency_code,
         cp.revenue_source,
         cp.duration 
         union all
         select spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         c.currency_code,
         isnull(sum(sl.spot_amount),0),
         isnull(sum(sl.cinema_amount),0),
         cp.revenue_source,
         count(distinct spot.spot_id) as no_spots,
         cp.duration as duration
    from campaign_spot spot,
         spot_liability sl,
         film_campaign fc,
         branch b,
         country c,
         campaign_package cp
   where sl.spot_id = spot.spot_id
     and fc.campaign_no = spot.campaign_no
     and b.branch_code = fc.branch_code
     and c.country_code = b.country_code
     and spot.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and spot.campaign_no = cp.campaign_no     
	and liability_type not in (3,10)
group by spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         c.currency_code,
         cp.revenue_source,
         cp.duration 
GO
