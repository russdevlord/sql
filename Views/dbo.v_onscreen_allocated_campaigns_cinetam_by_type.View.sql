/****** Object:  View [dbo].[v_onscreen_allocated_campaigns_cinetam_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_onscreen_allocated_campaigns_cinetam_by_type]
GO
/****** Object:  View [dbo].[v_onscreen_allocated_campaigns_cinetam_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_onscreen_allocated_campaigns_cinetam_by_type]
as
select			v_spots_allocated.campaign_no,
					v_spots_allocated.screening_date,
					v_spots_allocated.package_id, 
					spot_type,
					cinetam_demographics_id,
					case complex_region_class when 'M' then 'Metro' else 'Regional' end as complex_region,
					case all_movies when 'S' then 'Normal' when 'A' then 'Sponsorship' end as sponsorship,
					band_desc as duration_band,
					follow_film,
					case band_sort when 1 then 0 when 2 then 15 when 3 then 30 when 4 then 45 when 5 then 60 when 6 then 90 when 7 then 120 else 999 end as duration_number,
					sum(attendance) as attendance
from			v_spots_allocated,
					v_certificate_item_distinct,
					v_cinetam_movie_history_core_demos,
					complex,
					film_duration_bands,
					campaign_package
where			v_spots_allocated.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = v_cinetam_movie_history_core_demos.certificate_group
and				v_spots_allocated.complex_id = complex.complex_id
and				v_spots_allocated.package_id = campaign_package.package_id
and				campaign_package.band_id = film_duration_bands.band_id
group by		v_spots_allocated.campaign_no,
					v_spots_allocated.screening_date,
					case complex_region_class when 'M' then 'Metro' else 'Regional' end,
					case all_movies when 'S' then 'Normal' when 'A' then 'Sponsorship' end,
					band_desc,
					case band_sort when 1 then 0 when 2 then 15 when 3 then 30 when 4 then 45 when 5 then 60 when 6 then 90 when 7 then 120 else 999 end,
					v_spots_allocated.package_id, 
					follow_film,
					cinetam_demographics_id,
					spot_type

GO
