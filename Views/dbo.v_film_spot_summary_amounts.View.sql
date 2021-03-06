/****** Object:  View [dbo].[v_film_spot_summary_amounts]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_spot_summary_amounts]
GO
/****** Object:  View [dbo].[v_film_spot_summary_amounts]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view		[dbo].[v_film_spot_summary_amounts]
as				
select			spot.campaign_no, 
				sl.creation_period, 
				sl.release_period,
				sl.complex_id,
				liability_category_id,
				sl.original_liability,
				sl.cancelled,
				cp.media_product_id,
				cp.revenue_source,
				isnull(sum(sl.spot_amount),0) as billing_total,
				isnull(sum(sl.cinema_amount),0) as billing_w_total,
				isnull(sum(sl.cinema_rent),0) as cinema_rent_total
from			campaign_spot spot
inner join		spot_liability sl on spot.spot_id = sl.spot_id 
inner join		campaign_package cp on cp.package_id = spot.package_id
inner join		liability_type lt on sl.liability_type = lt.liability_type_id 
group by		spot.campaign_no, 
				sl.creation_period, 
				sl.release_period,
				sl.complex_id,
				liability_category_id,
				sl.original_liability,
				sl.cancelled,
				cp.media_product_id,
				cp.revenue_source	
union 
select			spot.campaign_no, 
				sl.creation_period, 
				sl.release_period,
				sl.complex_id,
				liability_category_id,
				sl.original_liability,
				sl.cancelled,
				cp.media_product_id,
				cp.revenue_source,
				isnull(sum(sl.spot_amount),0) as billing_total,
				isnull(sum(sl.cinema_amount),0) as billing_w_total,
				isnull(sum(sl.cinema_rent),0) as cinema_rent_total 
from			cinelight_spot spot
inner join		cinelight_spot_liability sl on spot.spot_id = sl.spot_id 
inner join		cinelight_package cp on cp.package_id = spot.package_id
inner join		liability_type lt on sl.liability_type = lt.liability_type_id 
group by		spot.campaign_no, 
				sl.creation_period, 
				sl.release_period,
				sl.complex_id,
				liability_category_id,
				sl.original_liability,
				sl.cancelled,
				cp.media_product_id,
				cp.revenue_source	
union 
select			spot.campaign_no, 
				sl.creation_period, 
				sl.release_period,
				sl.complex_id,
				liability_category_id,
				sl.original_liability,
				sl.cancelled,
				6,
				'I',
				isnull(sum(sl.spot_amount),0) as billing_total,
				isnull(sum(sl.cinema_amount),0) as billing_w_total,
				isnull(sum(sl.cinema_rent),0) as cinema_rent_total 
from			inclusion_spot spot
inner join		inclusion_spot_liability sl on spot.spot_id = sl.spot_id 
inner join		inclusion cp on cp.inclusion_id = spot.inclusion_id
inner join		liability_type lt on sl.liability_type = lt.liability_type_id 
where			inclusion_type = 5
group by		spot.campaign_no, 
				sl.creation_period, 
				sl.release_period,
				sl.complex_id,
				liability_category_id,
				sl.original_liability,
				sl.cancelled
GO
