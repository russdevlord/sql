/****** Object:  View [dbo].[v_complex_yield_by_business_unit_two]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_complex_yield_by_business_unit_two]
GO
/****** Object:  View [dbo].[v_complex_yield_by_business_unit_two]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create view [dbo].[v_complex_yield_by_business_unit_two]
as
select			movie_type,
					exhibitor_name, 
					exhibitor_id,
					film_market_no,
					film_market_desc,
					complex_id, 
					state_code, 
					complex_region_class, 
					complex_name, 
					screening_date,  
					premium_cinema,
					movie_id, 
					group_name,
					max(time_avail ) as time_avail, 
					sum(duration) as duration, 
					sum(roadblock_duration) as roadblock_duration,
					sum(tap_duration) as tap_duration,
					sum(ff_aud_duration) as ff_aud_duration,
					sum(ff_old_total_duration) as ff_old_total_duration,
					sum(mm_total_duration) as mm_total_duration,
					sum(total_revenue)  as total_revenue,
					sum(roadblock_revenue) as roadblock_revenue,
					sum(tap_revenue) as tap_revenue ,
					sum(ff_aud_revenue) as ff_aud_revenue,
					sum(ff_old_revenue)  as ff_old_revenue,
					sum( mm_revenue)  as mm_revenue,
					sum(agency_duration) as agency_duration,
					sum(direct_duration) as direct_duration,
					sum(showcase_duration) as showcase_duration,
					sum(cineads_duration) as cineads_duration,
					sum(agency_revenue) as agency_revenue,
					sum(direct_revenue) as direct_revenue,
					sum(showcase_revenue) as showcase_revenue,
					sum(cineads_revenue) as cineads_revenue,
					benchmark_end,
					cal_year,
					cal_qtr,
					fin_year,
					fin_qtr,
					cal_half,
					fin_half,
					country_code
from				v_complex_cpm_ffmm
where			benchmark_end > '1-jan-2015'
group by		movie_type,
					exhibitor_name, 
					exhibitor_id,
					film_market_no,
					film_market_desc,
					complex_id, 
					state_code, 
					complex_region_class, 
					complex_name, 
					screening_date,  
					premium_cinema,
					benchmark_end,
					cal_year,
					cal_qtr,
					fin_year,
					fin_qtr,
					cal_half,
					fin_half,
					country_code,
					movie_id, 
					group_name
GO
