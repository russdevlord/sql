/****** Object:  View [dbo].[v_complex_util]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_complex_util]
GO
/****** Object:  View [dbo].[v_complex_util]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_complex_util]
as
select		exhibitor_name, 
					movie_history.complex_id, 
					complex.state_code, 
					complex_region_class, 
					complex_name, 
					movie_history.screening_date,  
					movie_history.premium_cinema,
					movie_history.movie_id, 
					(select long_name from movie  with (nolock) where movie_id = movie_history.movie_id) as movie_name, 
					certificate_group.group_name, 
					(select sum(attendance) from movie_history with(nolock) where certificate_group =certificate_group.certificate_group_id ) as attendance, 
					max(mg_max_time) + max(max_time) as time_avail, 
					max(max_time) as time_avail_main_block_only, 
					sum(duration) as duration, 
					sum(duration)  * (select sum(attendance) from movie_history with(nolock) where certificate_group = v_certificate_item_distinct.certificate_group) as duration_time_times_attendance,
					(max(mg_max_time) + max(max_time)) * (select sum(attendance) from movie_history with(nolock) where certificate_group = v_certificate_item_distinct.certificate_group) as total_time_times_attendance,
					sum(campaign_spot.cinema_rate) as sum_charge_rate, 
					(select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock) where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type
					) as all_18_39, 
					sum(duration)  * (select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock) where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type
					) as all_18_39_times_duration, 
					(max(mg_max_time) + max(max_time)) * (select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock) where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_18_39_times_total_time, 
					(select		sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 5
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54,
					sum(duration)  * (	select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 5
														and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
														and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
														and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
														and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
														and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
														and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54_times_duration,
					(max(mg_max_time) + max(max_time)) * (select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock) where cinetam_reporting_demographics_id = 5
																									and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
																									and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
																									and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
																									and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
																									and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
																									and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54_times_total_time,
					(select max(release_date) from movie_country with(nolock) where movie_id = movie_history.movie_id and country = movie_history.country ) as release_date,
					rank_table.attendance_rank
from			movie_history with(nolock) , 
					complex with(nolock) , 
					v_certificate_item_distinct with(nolock) , 
					certificate_group with(nolock) , 
					campaign_spot with(nolock) , 
					campaign_package with(nolock) , 
					film_campaign with(nolock) , 
					exhibitor with(nolock) , 
					(select			complex_id,		
											screening_date, 
											movie_id, 
											sum(attendance) as tot_attendance, 
											rank() over (partition by complex_id, screening_date order by sum(attendance) desc) as attendance_rank
					from movie_history with(nolock) 
					where screening_date > '1-jan-2014' 
					group by complex_id, screening_date, movie_id)  as rank_table 
where		movie_history.certificate_group = certificate_group.certificate_group_id
and				certificate_Group.certificate_group_id = v_certificate_item_distinct.certificate_group
and				v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
and				campaign_spot.package_id = campaign_package.package_id
and 			movie_history.complex_id = complex.complex_id
and 			certificate_group.complex_id = complex.complex_id
and 			certificate_group.complex_id = movie_history.complex_id
and			    film_campaign.campaign_no = campaign_package.campaign_no
and 			film_campaign.campaign_no = campaign_spot.campaign_no
and 			complex.exhibitor_id = exhibitor.exhibitor_id
and 			movie_history.screening_date > '1-jan-2014'
and				rank_table.complex_id = movie_history.complex_id
and				rank_table.screening_date = movie_history.screening_date
and				rank_table.movie_id = movie_history.movie_id
group by	movie_history.complex_id,
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
					rank_table.attendance_rank
union all
select		exhibitor_name, 
					movie_history.complex_id,
					complex.state_code, 
					complex_region_class, 
					complex_name, 
					movie_history.screening_date, 
					movie_history.premium_cinema,
					movie_history.movie_id, 
					(select long_name from movie with(nolock)  where movie_id = movie_history.movie_id) as movie_name, 
					'',
					movie_history.attendance, 
					mg_max_time + max_time as time_avail, 
					max_time,
					0, 
					0, 
					(mg_max_time + max_time) * (attendance) as total_time_times_attendance,
					0, 
					(select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_18_39, 
					0 as all_18_39_times_duration, 
					(mg_max_time + max_time) * (select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_18_39_times_total_time, 
					(select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 5
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54,
					0 as all_25_54_times_duration,
					(mg_max_time + max_time) * (select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 5
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54_times_total_time,
					(select max(release_date) from movie_country with(nolock) where movie_id = movie_history.movie_id and country = movie_history.country ) as release_date,
					rank_table.attendance_rank
from			movie_history with(nolock) , 
					complex with(nolock) ,  
					exhibitor with(nolock) , 
					(select			complex_id,		
											screening_date, 
											movie_id, 
											sum(attendance) as tot_attendance, 
											rank() over (partition by complex_id, screening_date order by sum(attendance) desc) as attendance_rank
					from movie_history with(nolock) 
					where screening_date > '1-jan-2014' 
					group by complex_id, screening_date, movie_id)  as rank_table
where		(movie_history.certificate_group not in (	select	distinct certificate_group_id 
																									from		v_certificate_item_distinct with(nolock) , 
																													certificate_group with(nolock)  
																									where	v_certificate_item_distinct.certificate_group =  certificate_group.certificate_group_id 
																									and			spot_reference is not null) )
and				movie_history.complex_id = complex.complex_id
and				complex.exhibitor_id = exhibitor.exhibitor_id
and				movie_history.screening_date > '1-jan-2014'
and				rank_table.complex_id = movie_history.complex_id
and				rank_table.screening_date = movie_history.screening_date
and				rank_table.movie_id = movie_history.movie_id
union all
select		exhibitor_name, 
					movie_history.complex_id,
					complex.state_code, 
					complex_region_class, 
					complex_name, 
					movie_history.screening_date, 
					movie_history.premium_cinema,
					movie_history.movie_id, (select long_name from movie with(nolock)  where movie_id = movie_history.movie_id) as movie_name, 
					'', 
					movie_history.attendance, 
					mg_max_time + max_time as time_avail, 
					max_time,
					0, 
					0, 
					(mg_max_time + max_time) * (attendance) as total_time_times_attendance,
					0, 
					(select sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type
					) as all_18_39, 
					0 as all_18_39_times_duration, 
					(mg_max_time + max_time) * (select sum(attendance) from v_cinetam_movie_history_reporting_demos with (nolock) where cinetam_reporting_demographics_id = 3
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type
					) as all_18_39_times_total_time, 
					(select sum(attendance) from v_cinetam_movie_history_reporting_demos  with (nolock) where cinetam_reporting_demographics_id = 5
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type
					) as all_25_54,
					0 as all_25_54_times_duration,
					(mg_max_time + max_time) * (select sum(attendance) from v_cinetam_movie_history_reporting_demos  with (nolock) where cinetam_reporting_demographics_id = 5
					and				movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
					and				movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
					and				movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
					and				movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
					and				movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
					and				movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type
					) as all_25_54_times_total_time,
					(select max(release_date) from movie_country  with (nolock) where movie_id = movie_history.movie_id and country = movie_history.country ) as release_date,
					rank_table.attendance_rank
from			movie_history with (nolock) , 
					complex with (nolock) ,  
					exhibitor with (nolock) , 
					(select			complex_id,		
											screening_date, 
											movie_id, 
											sum(attendance) as tot_attendance, 
											rank() over (partition by complex_id, screening_date order by sum(attendance) desc) as attendance_rank
					from movie_history with (nolock) 
					where screening_date > '1-jan-2014' 
					group by complex_id, screening_date, movie_id)  as rank_table
where		movie_history.certificate_group is null
and				movie_history.complex_id = complex.complex_id
and				complex.exhibitor_id = exhibitor.exhibitor_id
and				movie_history.screening_date > '1-jan-2014'
and				rank_table.complex_id = movie_history.complex_id
and				rank_table.screening_date = movie_history.screening_date
and				rank_table.movie_id = movie_history.movie_id
GO
