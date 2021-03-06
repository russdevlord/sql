/****** Object:  View [dbo].[v_onscreen_allocated_campaigns_all_people_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_onscreen_allocated_campaigns_all_people_by_type]
GO
/****** Object:  View [dbo].[v_onscreen_allocated_campaigns_all_people_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [dbo].[v_onscreen_allocated_campaigns_all_people_by_type]
as
select			v_spots_allocated.campaign_no,
					v_spots_allocated.screening_date,
					v_spots_allocated.package_id,
					spot_type,
					follow_film,
					case complex_region_class when 'M' then 'Metro' else 'Regional' end as complex_region,
					case all_movies when 'S' then 'Normal' when 'A' then 'Sponsorship' end as sponsorship,
					band_desc as duration_band,
					case band_sort when 1 then 0 when 2 then 15 when 3 then 30 when 4 then 45 when 5 then 60 when 6 then 90 when 7 then 120 else 999 end as duration_number,
					sum(attendance) as attendance
from			v_spots_allocated,
					v_certificate_item_distinct,
					movie_history,
					complex,
					campaign_package,
					film_duration_bands
where			v_spots_allocated.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				v_spots_allocated.complex_id = complex.complex_id
and				v_spots_allocated.package_id = campaign_package.package_id
and				campaign_package.band_id = film_duration_bands.band_id
group by		v_spots_allocated.campaign_no,
					v_spots_allocated.screening_date,
					v_spots_allocated.package_id, 
					follow_film,
					case complex_region_class when 'M' then 'Metro' else 'Regional' end,
					case all_movies when 'S' then 'Normal' when 'A' then 'Sponsorship' end,
					band_desc,
					case band_sort when 1 then 0 when 2 then 15 when 3 then 30 when 4 then 45 when 5 then 60 when 6 then 90 when 7 then 120 else 999 end,
					spot_type





GO
