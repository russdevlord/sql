/****** Object:  View [dbo].[v_onscreen_allocated_campaigns_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_onscreen_allocated_campaigns_by_type]
GO
/****** Object:  View [dbo].[v_onscreen_allocated_campaigns_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_onscreen_allocated_campaigns_by_type]
as
select			v_spots_allocated_by_type.campaign_no,
					v_spots_allocated_by_type.screening_date,
					spot_type,
					follow_film,
					campaign_package.package_id, 
					case complex_region_class when 'M' then 'Metro' else 'Regional' end as complex_region,
					case all_movies when 'S' then 'Normal' when 'A' then 'Sponsorship' end as sponsorship,
					band_desc as duration_band,
					film_screening_date_xref.benchmark_end,
					datepart(yy, film_screening_date_xref.benchmark_end) as calyear,
					case band_sort when 1 then 0 when 2 then 15 when 3 then 30 when 4 then 45 when 5 then 60 when 6 then 90 when 7 then 120 else 999 end as duration_number,
					count(spot_id) as no_spots,
					sum(v_spots_allocated_by_type.charge_rate) as charge_rate_sum,
					sum(v_spots_allocated_by_type.cinema_rate) as cinema_rate_sum
from			v_spots_allocated_by_type,
					complex,
					campaign_package,
					film_duration_bands,
					film_screening_date_xref
where			v_spots_allocated_by_type.screening_date >= '25-dec-2014'
and				v_spots_allocated_by_type.complex_id = complex.complex_id
and				v_spots_allocated_by_type.package_id = campaign_package.package_id
and				campaign_package.band_id = film_duration_bands.band_id
and				v_spots_allocated_by_type.screening_date = film_screening_date_xref.screening_date
group by		v_spots_allocated_by_type.campaign_no,
					v_spots_allocated_by_type.screening_date,
					spot_type,
					follow_film,
					campaign_package.package_id, 
					film_screening_date_xref.benchmark_end,
					datepart(yy, film_screening_date_xref.benchmark_end),
					case complex_region_class when 'M' then 'Metro' else 'Regional' end,
					case all_movies when 'S' then 'Normal' when 'A' then 'Sponsorship' end,
					band_desc,
					case band_sort when 1 then 0 when 2 then 15 when 3 then 30 when 4 then 45 when 5 then 60 when 6 then 90 when 7 then 120 else 999 end 
					









GO
