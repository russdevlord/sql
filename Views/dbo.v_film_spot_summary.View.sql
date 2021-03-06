/****** Object:  View [dbo].[v_film_spot_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_spot_summary]
GO
/****** Object:  View [dbo].[v_film_spot_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view		[dbo].[v_film_spot_summary]	
as
select			fc.campaign_no,
				fc.product_desc,
				b.country_code,
				sl.creation_period,
				sl.release_period,
				sl.complex_id,
				cp.media_product_id,
				cp.revenue_source,
				fc.business_unit_id
from			film_campaign fc
inner join		campaign_spot spot on fc.campaign_no = spot.campaign_no 
inner join		spot_liability sl on spot.spot_id = sl.spot_id
inner join		branch b on fc.branch_code = b.branch_code
inner join		campaign_package cp on spot.package_id = cp.package_id
where			fc.business_unit_id in (2,3,5,9)
group by		fc.campaign_no,
				fc.product_desc,
				b.country_code,
				sl.creation_period,
				sl.release_period,
				sl.complex_id,
				cp.media_product_id,
				cp.revenue_source,
				fc.business_unit_id
union 
select			fc.campaign_no,
				fc.product_desc,
				b.country_code,
				sl.creation_period,
				sl.release_period,
				sl.complex_id,
				cp.media_product_id,
				cp.revenue_source,
				fc.business_unit_id
from			film_campaign fc
inner join		cinelight_spot spot on fc.campaign_no = spot.campaign_no
inner join		cinelight_spot_liability sl on spot.spot_id = sl.spot_id
inner join		branch b on fc.branch_code = b.branch_code
inner join		cinelight_package cp on spot.package_id = cp.package_id
where			fc.business_unit_id in (2,3,5,9)
group by		fc.campaign_no,
				fc.product_desc,
				b.country_code,
				sl.creation_period,
				sl.release_period,
				sl.complex_id,
				cp.media_product_id,
				cp.revenue_source,
				fc.business_unit_id
union
select			fc.campaign_no,
				fc.product_desc,
				b.country_code,
				sl.creation_period,
				sl.release_period,
				sl.complex_id,
				6,
				'I',
				fc.business_unit_id
from			inclusion_spot spot
inner join		inclusion_spot_liability sl on spot.spot_id = sl.spot_id
inner join		inclusion cp on spot.inclusion_id = cp.inclusion_id
inner join		film_campaign fc on cp.campaign_no = fc.campaign_no
inner join		branch b on fc.branch_code = b.branch_code
where			inclusion_type = 5
group by		fc.campaign_no,
				fc.product_desc,
				b.country_code,
				sl.creation_period,
				sl.release_period,
				sl.complex_id,
				fc.business_unit_id

GO
