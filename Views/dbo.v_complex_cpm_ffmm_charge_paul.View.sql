/****** Object:  View [dbo].[v_complex_cpm_ffmm_charge_paul]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_complex_cpm_ffmm_charge_paul]
GO
/****** Object:  View [dbo].[v_complex_cpm_ffmm_charge_paul]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create view [dbo].[v_complex_cpm_ffmm_charge_paul]
as
select		'Standard' as movie_type,
				film_campaign.campaign_no, 
				film_campaign.product_desc,
				exhibitor_name, 
				film_market.film_market_desc,
				complex.state_code, 
				complex_region_class, 
				complex_name, 
				movie_history.screening_date,  
				movie_history.premium_cinema,
				movie_history.movie_id, 
				(select		long_name from movie with (nolock) where movie_id = movie_history.movie_id) as movie_name, 
				certificate_group.group_name, 
				movie_history.occurence,
				convert(numeric(18,6),max(mg_max_time) + max(max_time)) as time_avail, 
				convert(numeric(18,6),max(max_time)) as time_avail_main_block_only, 
				convert(numeric(18,6),sum(duration)) as duration, 
				convert(numeric(18,6),sum(case spot_type when 'A' then duration else 0 end)) as map_duration,
				convert(numeric(18,6),sum(case spot_type when 'K' then duration else 0 end)) as roadblock_duration,
				convert(numeric(18,6),sum(case spot_type when 'T' then duration else 0 end)) as tap_duration,
				convert(numeric(18,6),sum(case spot_type when 'F' then duration else 0 end)) as ff_aud_duration,
				convert(numeric(18,6),sum(case when spot_type <> 'F' and follow_film = 'Y' then duration else 0 end)) as ff_old_total_duration,
				convert(numeric(18,6),sum(case when spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then duration else 0 end)) as mm_total_duration,
				convert(numeric(18,6),sum(case when spot_type <> 'F' and follow_film = 'Y' and spot_type <> 'B' then duration else 0 end)) as ff_old_paid_duration,
				convert(numeric(18,6),sum(case when spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' and spot_type <> 'B' then duration else 0 end)) as mm_paid_duration,
				convert(numeric(18,6),sum(case when spot_type = 'B' and follow_film = 'Y' then duration else 0 end)) as ff_old_bonus_duration,
				convert(numeric(18,6),sum(case when spot_type = 'B' and follow_film = 'N' then duration else 0 end)) as mm_bonus_duration,
				convert(numeric(18,6),avg(v_spot_util_liab.charge_rate)) as avg_rate,
				convert(numeric(18,6),avg(case spot_type when 'A' then v_spot_util_liab.charge_rate else 0 end)) as avg_map_rate,
				convert(numeric(18,6),avg(case spot_type when 'K' then v_spot_util_liab.charge_rate else 0 end)) as avg_roadblock_rate,
				convert(numeric(18,6),avg(case spot_type when 'T' then v_spot_util_liab.charge_rate else 0 end)) as avg_tap_rate,
				convert(numeric(18,6),avg(case spot_type when 'F' then v_spot_util_liab.charge_rate else 0 end)) as avg_ff_aud_rate,
				convert(numeric(18,6),avg(case when spot_type <> 'F' and follow_film = 'Y' then v_spot_util_liab.charge_rate else 0 end)) as avg_ff_old_rate,
				convert(numeric(18,6),avg(case when spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then v_spot_util_liab.charge_rate else 0 end)) as avg_mm_rate,
				convert(numeric(18,6),sum(v_spot_util_liab.charge_rate)) as total_revenue,
				convert(numeric(18,6),sum(case spot_type when 'A' then v_spot_util_liab.charge_rate else 0 end)) as map_revenue,
				convert(numeric(18,6),sum(case spot_type when 'K' then v_spot_util_liab.charge_rate else 0 end)) as roadblock_revenue,
				convert(numeric(18,6),sum(case spot_type when 'T' then v_spot_util_liab.charge_rate else 0 end)) as tap_revenue,
				convert(numeric(18,6),sum(case spot_type when 'F' then v_spot_util_liab.charge_rate else 0 end)) as ff_aud_revenue,
				convert(numeric(18,6),sum(case when spot_type <> 'F' and follow_film = 'Y' then v_spot_util_liab.charge_rate else 0 end)) as ff_old_revenue,
				convert(numeric(18,6),sum(case when spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then v_spot_util_liab.charge_rate else 0 end)) as mm_revenue,
				convert(numeric(18,6),sum(case business_unit_id when 2 then duration else 0 end)) as agency_duration,
				convert(numeric(18,6),sum(case business_unit_id when 3 then duration else 0 end)) as direct_duration,
				convert(numeric(18,6),sum(case business_unit_id when 5 then duration else 0 end)) as showcase_duration,
				convert(numeric(18,6),sum(case business_unit_id when 9 then duration else 0 end)) as cineads_duration,
				convert(numeric(18,6),sum(case business_unit_id when 2 then v_spot_util_liab.charge_rate else 0 end)) as agency_revenue,
				convert(numeric(18,6),sum(case business_unit_id when 3 then v_spot_util_liab.charge_rate else 0 end)) as direct_revenue,
				convert(numeric(18,6),sum(case business_unit_id when 5 then v_spot_util_liab.charge_rate else 0 end)) as showcase_revenue,
				convert(numeric(18,6),sum(case business_unit_id when 9 then v_spot_util_liab.charge_rate else 0 end)) as cineads_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'T' and spot_type <> 'K' then v_spot_util_liab.charge_rate else 0 end)) as agency_revenue_ffmm,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'T' and spot_type <> 'K' then v_spot_util_liab.charge_rate  else 0 end)) as direct_revenue_ffmm,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'T' and spot_type <> 'K' then v_spot_util_liab.charge_rate  else 0 end)) as showcase_revenue_ffmm,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'T' and spot_type <> 'K' then v_spot_util_liab.charge_rate  else 0 end)) as cineads_revenue_ffmm,
				(select		convert(numeric(18,6),sum(attendance)) from movie_history with(nolock) where certificate_group =certificate_group.certificate_group_id ) as attendance, 
				(select		convert(numeric(18,6),sum(attendance)) from v_cinetam_movie_history_reporting_demos with(nolock) 
				where		cinetam_reporting_demographics_id = 3
				and			movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
				and			movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
				and			movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
				and			movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
				and			movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
				and			movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_18_39, 
				(select		convert(numeric(18,6),sum(attendance)) from v_cinetam_movie_history_reporting_demos with(nolock)  
				where		cinetam_reporting_demographics_id = 5
				and			movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
				and			movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
				and			movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
				and			movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
				and			movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
				and			movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54,
				(select		max(release_date) from movie_country with(nolock) where movie_id = movie_history.movie_id and movie_country.country_code = movie_history.country ) as release_date,
				rank_table.attendance_rank as complex_movie_rank,
				rank_table_exhibitor.attendance_rank as exhibitor_movie_rank,
				rank_table_country.attendance_rank as country_movie_rank,
				case when rank_table.attendance_rank = 1 then 'Y' else 'N' end as complex_top_1,
				case when rank_table.attendance_rank <= 2 then 'Y' else 'N' end as complex_top_2,
				case when rank_table.attendance_rank > 1 then 'Y' else 'N' end as complex_not_top_1,
				case when rank_table.attendance_rank > 2 then 'Y' else 'N' end as complex_not_top_2,
				case when rank_table_country.attendance_rank = 1 then 'Y' else 'N' end as country_top_1,
				case when rank_table_country.attendance_rank <= 2 then 'Y' else 'N' end as country_top_2,
				case when rank_table_country.attendance_rank > 1 then 'Y' else 'N' end as country_not_top_1,
				case when rank_table_country.attendance_rank > 2 then 'Y' else 'N' end as country_not_top_2,
				film_screening_date_xref.benchmark_end,
				year(benchmark_end) as cal_year,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then 'Q1' 
				when 2 then 'Q1'
				when 3 then 'Q1'
				when 4 then 'Q2' 
				when 5 then 'Q2' 
				when 6 then 'Q2' 
				when 7 then 'Q3' 
				when 8 then 'Q3' 
				when 9 then 'Q3' 
				when 10 then 'Q4'
				when 11 then 'Q4'
				when 12 then 'Q4' end as cal_qtr,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then 'H1' 
				when 2 then 'H1'
				when 3 then 'H1'
				when 4 then 'H1' 
				when 5 then 'H1' 
				when 6 then 'H1' 
				when 7 then 'H2' 
				when 8 then 'H2' 
				when 9 then 'H2' 
				when 10 then 'H2'
				when 11 then 'H2'
				when 12 then 'H2' end as cal_half,
				movie_history.country as country_code,
				convert(numeric(18,6),sum(case spot_type when 'A' then 1 else 0 end)) as map_spots,
				convert(numeric(18,6),sum(case spot_type when 'K' then 1 else 0 end)) as roadblock_spots,
				convert(numeric(18,6),sum(case spot_type when 'T' then 1 else 0 end)) as tap_spots,
				convert(numeric(18,6),sum(case spot_type when 'F' then 1 else 0 end)) as ff_aud_spots,
				convert(numeric(18,6),sum(case when spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' then 1 else 0 end)) as ff_old_total_spots,
				convert(numeric(18,6),sum(case when spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then 1 else 0 end)) as mm_total_spots,
				convert(numeric(18,6),sum(case when spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' and spot_type <> 'B' then 1 else 0 end)) as ff_old_paid_spots,
				convert(numeric(18,6),sum(case when spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' and spot_type <> 'B' then 1 else 0 end)) as mm_paid_spots,
				convert(numeric(18,6),sum(case when spot_type = 'B' and follow_film = 'Y' then 1 else 0 end)) as ff_old_bonus_spots,
				convert(numeric(18,6),sum(case when spot_type = 'B' and follow_film = 'N' then 1 else 0 end)) as mm_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'C' and spot_type <> 'N' then 1 else 0 end)) as agency_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'C' and spot_type <> 'N' then 1 else 0 end)) as direct_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'C' and spot_type <> 'N' then 1 else 0 end)) as showcase_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'C' and spot_type <> 'N' then 1 else 0 end)) as cineads_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'T' and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'K' then 1 else 0 end)) as agency_spots_ffmm,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'T' and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'K' then 1 else 0 end)) as direct_spots_ffmm,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'T' and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'K' then 1 else 0 end)) as showcase_spots_ffmm,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'T' and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'K' then 1 else 0 end)) as cineads_spots_ffmm,
				convert(numeric(18,6),sum(1)) as total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'A' then 1 else 0 end)) as agency_map_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'K' then 1 else 0 end)) as agency_roadblock_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'T' then 1 else 0 end)) as agency_tap_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'F' then 1 else 0 end)) as agency_ff_aud_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' then 1 else 0 end)) as agency_ff_old_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then 1 else 0 end)) as agency_mm_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' and spot_type <> 'B' then 1 else 0 end)) as agency_ff_old_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' and spot_type <> 'B' then 1 else 0 end)) as agency_mm_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'B' and follow_film = 'Y' then 1 else 0 end)) as agency_ff_old_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'B' and follow_film = 'N' then 1 else 0 end)) as agency_mm_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'A' then v_spot_util_liab.charge_rate else 0 end)) as agency_map_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'K' then v_spot_util_liab.charge_rate else 0 end)) as agency_roadblock_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'T' then v_spot_util_liab.charge_rate else 0 end)) as agency_tap_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type = 'F' then v_spot_util_liab.charge_rate else 0 end)) as agency_ff_aud_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'F' and follow_film = 'Y' then v_spot_util_liab.charge_rate else 0 end)) as agency_ff_old_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 2 and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then v_spot_util_liab.charge_rate else 0 end)) as agency_mm_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'A' then 1 else 0 end)) as direct_map_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'K' then 1 else 0 end)) as direct_roadblock_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'T' then 1 else 0 end)) as direct_tap_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'F' then 1 else 0 end)) as direct_ff_aud_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' then 1 else 0 end)) as direct_ff_old_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then 1 else 0 end)) as direct_mm_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' and spot_type <> 'B' then 1 else 0 end)) as direct_ff_old_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' and spot_type <> 'B' then 1 else 0 end)) as direct_mm_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'B' and follow_film = 'Y' then 1 else 0 end)) as direct_ff_old_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'B' and follow_film = 'N' then 1 else 0 end)) as direct_mm_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'A' then v_spot_util_liab.charge_rate else 0 end)) as direct_map_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'K' then v_spot_util_liab.charge_rate else 0 end)) as direct_roadblock_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'T' then v_spot_util_liab.charge_rate else 0 end)) as direct_tap_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type = 'F' then v_spot_util_liab.charge_rate else 0 end)) as direct_ff_aud_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'F' and follow_film = 'Y' then v_spot_util_liab.charge_rate else 0 end)) as direct_ff_old_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 3 and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then v_spot_util_liab.charge_rate else 0 end)) as direct_mm_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'A' then 1 else 0 end)) as showcase_map_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'K' then 1 else 0 end)) as showcase_roadblock_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'T' then 1 else 0 end)) as showcase_tap_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'F' then 1 else 0 end)) as showcase_ff_aud_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' then 1 else 0 end)) as showcase_ff_old_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then 1 else 0 end)) as showcase_mm_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' and spot_type <> 'B' then 1 else 0 end)) as showcase_ff_old_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' and spot_type <> 'B' then 1 else 0 end)) as showcase_mm_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'B' and follow_film = 'Y' then 1 else 0 end)) as showcase_ff_old_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'B' and follow_film = 'N' then 1 else 0 end)) as showcase_mm_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'A' then v_spot_util_liab.charge_rate else 0 end)) as showcase_map_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'K' then v_spot_util_liab.charge_rate else 0 end)) as showcase_roadblock_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'T' then v_spot_util_liab.charge_rate else 0 end)) as showcase_tap_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type = 'F' then v_spot_util_liab.charge_rate else 0 end)) as showcase_ff_aud_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'F' and follow_film = 'Y' then v_spot_util_liab.charge_rate else 0 end)) as showcase_ff_old_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 5 and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then v_spot_util_liab.charge_rate else 0 end)) as showcase_mm_revenue,			
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'A' then 1 else 0 end)) as cineads_map_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'K' then 1 else 0 end)) as cineads_roadblock_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'T' then 1 else 0 end)) as cineads_tap_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'F' then 1 else 0 end)) as cineads_ff_aud_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' then 1 else 0 end)) as cineads_ff_old_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then 1 else 0 end)) as cineads_mm_total_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'F' and follow_film = 'Y' and spot_type <> 'B' then 1 else 0 end)) as cineads_ff_old_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'C' and spot_type <> 'N' and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' and spot_type <> 'B' then 1 else 0 end)) as cineads_mm_paid_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'B' and follow_film = 'Y' then 1 else 0 end)) as cineads_ff_old_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'B' and follow_film = 'N' then 1 else 0 end)) as cineads_mm_bonus_spots,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'A' then v_spot_util_liab.charge_rate else 0 end)) as cineads_map_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'K' then v_spot_util_liab.charge_rate else 0 end)) as cineads_roadblock_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'T' then v_spot_util_liab.charge_rate else 0 end)) as cineads_tap_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type = 'F' then v_spot_util_liab.charge_rate else 0 end)) as cineads_ff_aud_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'F' and follow_film = 'Y' then v_spot_util_liab.charge_rate else 0 end)) as cineads_ff_old_revenue,
				convert(numeric(18,6),sum(case when business_unit_id = 9 and spot_type <> 'A' and spot_type <> 'K' and spot_type <> 'T' and spot_type <> 'F' and follow_film = 'N' then v_spot_util_liab.charge_rate else 0 end)) as cineads_mm_revenue		
from			v_spot_util_liab with(nolock),
				movie_history with(nolock) , 
				complex with(nolock) , 
				v_certificate_item_distinct with(nolock) , 
				certificate_group with(nolock) , 
				campaign_spot with(nolock) , 
				campaign_package with(nolock) , 
				film_campaign with(nolock) , 
				exhibitor with(nolock) , 
				film_market with(nolock),
				film_screening_date_xref with(nolock),
				(select		complex_id,		
								screening_date, 
								movie_id, 
								sum(attendance) as tot_attendance, 
								rank() over (partition by complex_id, screening_date order by sum(attendance) desc) as attendance_rank
				from			movie_history with(nolock) 
				where		screening_date >= '31-dec-2015' 
				and			movie_id <> 102
				and			advertising_open = 'Y'
				group by	complex_id, screening_date, movie_id) as rank_table,
				(select		exhibitor_id, 
								screening_date, 
								movie_id, 
								sum(attendance) as tot_attendance, 
								rank() over (partition by exhibitor_id, screening_date order by sum(attendance) desc) as attendance_rank
				from			movie_history with(nolock),
								complex with(nolock) 
				where		screening_date >= '31-dec-2015' 
				and			movie_id <> 102
				and			movie_history.complex_id = complex.complex_id
				and			advertising_open = 'Y'
				group by	screening_date, movie_id, exhibitor_id) as rank_table_exhibitor,  
				(select		country,
								screening_date, 
								movie_id, 
								sum(attendance) as tot_attendance, 
								rank() over (partition by country, screening_date order by sum(attendance) desc) as attendance_rank
				from			movie_history with(nolock) 
				where		screening_date >= '31-dec-2015' 
				and			movie_id <> 102
				and			advertising_open = 'Y'
				group by	screening_date, movie_id, country) as rank_table_country
where		movie_history.certificate_group = certificate_group.certificate_group_id
and			certificate_Group.certificate_group_id = v_certificate_item_distinct.certificate_group
and			v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
and			campaign_spot.package_id = campaign_package.package_id
and 			movie_history.complex_id = complex.complex_id
and 			certificate_group.complex_id = complex.complex_id
and 			certificate_group.complex_id = movie_history.complex_id
and			film_campaign.campaign_no = campaign_package.campaign_no
and 			film_campaign.campaign_no = campaign_spot.campaign_no
and 			complex.exhibitor_id = exhibitor.exhibitor_id
and 			movie_history.screening_date >= '31-dec-2015'
and			rank_table.complex_id = movie_history.complex_id
and			rank_table.screening_date = movie_history.screening_date
and			rank_table.movie_id = movie_history.movie_id
and			rank_table_exhibitor.exhibitor_id = complex.exhibitor_id
and			rank_table_exhibitor.screening_date = movie_history.screening_date
and			rank_table_exhibitor.movie_id = movie_history.movie_id
and			rank_table_country.country = movie_history.country
and			rank_table_country.screening_date = movie_history.screening_date
and			rank_table_country.movie_id = movie_history.movie_id
and			movie_history.movie_id <> 102
and			campaign_spot.spot_id = v_spot_util_liab.spot_id
and			complex.film_market_no = film_market.film_market_no
and			movie_history.advertising_open = 'Y'
and			film_screening_date_xref.screening_date = movie_history.screening_date
--AND			film_complex_status <> 'C'
group by	film_campaign.campaign_no,
				film_campaign.product_desc,
				movie_history.complex_id,
				exhibitor.exhibitor_id,
				film_market.film_market_no,
				film_market.film_market_desc,
				movie_history.movie_id,
				movie_history.screening_date,
				movie_history.occurence,
				movie_history.print_medium,
				movie_history.three_d_type,
				movie_history.country,movie_history.premium_cinema,
				exhibitor_name, 
				complex_name, 
				movie_history.screening_date,  
				certificate_group.group_name, 
				complex.state_code, 
				complex_region_class,  
				v_certificate_item_distinct.certificate_group, 
				certificate_group.certificate_group_id,
				rank_table.attendance_rank,
				rank_table_exhibitor.attendance_rank,
				rank_table_country.attendance_rank,
				film_screening_date_xref.benchmark_end
GO
