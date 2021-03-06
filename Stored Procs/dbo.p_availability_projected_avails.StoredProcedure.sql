/****** Object:  StoredProcedure [dbo].[p_availability_projected_avails]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_projected_avails]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_projected_avails]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_availability_projected_avails]		@country_code								char(1),                
														@cinetam_reachfreq_mode_id					int, --mode for MM, TAP, RB, Digilite                
														@screening_dates							varchar(max),                
														@film_markets								varchar(max),                
														@cinetam_reporting_demographics_id			int,                
														@product_category_sub_concat_id				int,                
														@cinetam_reachfreq_duration_id				int,                
														@exhibitor_ids								varchar(max),                
														@manual_adjustment_factor					numeric(20,8),                
														@premium_position							bit,                
														@alcohol_gambling							bit,                
														@ma15_above									bit,                
														@exclude_children							bit,                
														@movie_category_codes						varchar(max)                
                                                                  
as                
                
declare			@error								int,                
				@population							int,                
				@attendance							int,                
				@all_people_attendance				int,                
				@reach								numeric(30,6),                
				@frequency							numeric(30,6),                
				@cpm								money,                
				@cost								money,                
				@market								varchar(30),                
				@screening_date						datetime,                
				@start_date							datetime,                
				@end_date							datetime,                
				@adjustment_factor					numeric(6,4),                
				@movie_adjustment_factor		    numeric(6,4),                
				@metro_avg							int,                
				@regional_avg						int,                
				@metro_screens						int,                
				@regional_screens					int,                
				@attendance_estimate				integer,                
				@attendance_pool					integer,                
				@metro_pool							integer,                
				@regional_pool						integer,                
				@metro_panels						integer,                
				@regional_panels					integer,                
				@attendance_population				integer,                
				@actual_population					integer,                      
				@movio_unique_transactions			integer,                
				@all_people_metro_avg				integer,                
				@all_people_regional_avg			integer,                
				@all_people_metro_pool				integer,                
				@all_people_regional_pool			integer,                
				@mm_adjustment						numeric(6,4),                
				@rows								integer,                
				@generation_date					datetime,                
				@duration							int,                
				@national_count						int,                
				@metro_count						int,                
				@regional_count						int,                
				@one								numeric(20,8),
				@demo_desc							varchar(50)                
                
set nocount on                

/*
 * Create Temp Tables
 */

create table #screening_dates                
(                
	screening_date         datetime   not null                
)      

create table #availability_attendance_proj
(
	screening_date								datetime			null,
	generation_date								datetime			null,
	country_code								char(1)				null,
	film_market_no								int					null,
	complex_id									int					null,
	complex_name								varchar(50)			null,
	cinetam_reporting_demographics_id			int					null,
	cinetam_reachfreq_duration_id				int					null,
	exhibitor_id								int					null,
	product_category_sub_concat_id				int					null,
	movie_category_code							char(2)				null,
	demo_attendance								numeric(20,8)		null,
	all_people_attendance						numeric(20,8)		null,
	product_booked_percentage					numeric(20,8)		null,
	current_booked_percentage					numeric(20,8)		null,
	projected_booked_percentage					numeric(20,8)		null,
	full_attendance								numeric(20,8)		null
)

if len(@screening_dates) > 0  
begin              
	insert into #screening_dates                
	select * from dbo.f_multivalue_parameter(@screening_dates,',')
end

select			@demo_desc = cinetam_reporting_demographics_desc
from			cinetam_reporting_demographics
where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

/*
 * Insert availability proc into temp table
 */
                
insert into #availability_attendance_proj
exec @error = p_availability_attendance_estimate			@country_code, 
															@cinetam_reachfreq_mode_id,
															@screening_dates,
															@film_markets,
															@cinetam_reporting_demographics_id,
															@product_category_sub_concat_id, 
															@cinetam_reachfreq_duration_id,
															@exhibitor_ids,
															@manual_adjustment_factor,
															@premium_position,
															@alcohol_gambling,
															@ma15_above,
															@exclude_children,
															@movie_category_codes	

if @error <> 0
begin		
	raiserror ('Error running availability procedure', 16,1)
	return -1
end

alter table #availability_attendance_proj
add	max_time									numeric(20,8)		null

alter table #availability_attendance_proj
add	total_30_sec_demo_attendance				numeric(20,8)		null

alter table #availability_attendance_proj
add	total_30_sec_all_people_attendance			numeric(20,8)		null

alter table #availability_attendance_proj
add	booked_demo_attendance						numeric(20,8)		null

alter table #availability_attendance_proj
add	booked_all_people_attendance				numeric(20,8)		null
	
alter table #availability_attendance_proj
add	booked_30_sec_revenue						numeric(20,8)		null

alter table #availability_attendance_proj
add	booked_revenue								numeric(20,8)		null

/*
 * set pre show length
 */             

update			#availability_attendance_proj	 
set				#availability_attendance_proj.max_time = complex_date.max_time + complex_date.mg_max_time
from			complex_date
where			#availability_attendance_proj.complex_id = complex_date.complex_id
and				#availability_attendance_proj.screening_date = complex_date.screening_date

/*
 * Set attendance pools
 */
			    
update			#availability_attendance_proj	 
set				total_30_sec_demo_attendance = demo_attendance * max_time / 30,
				total_30_sec_all_people_attendance = all_people_attendance * max_time / 30

--@cinetam_reporting_demographics_id

/*
 * Set booked attendance targets
 */

--TAP & MAP
update			#availability_attendance_proj                
set				booked_demo_attendance = isnull(booked_demo_attendance,0) + convert(numeric(20,8), temp_table.attendance_target)                
from				(select				inclusion_cinetam_targets.screening_date,                 
										inclusion_cinetam_targets.complex_id,                 
										sum(inclusion_cinetam_targets.target_attendance  * duration / 30 / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target
					from				inclusion_cinetam_targets
					inner join			inclusion_cinetam_package on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
					inner join			campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
					inner join			#screening_dates on inclusion_cinetam_targets.screening_date = #screening_dates.screening_date                
					inner join			film_screening_date_attendance_prev on inclusion_cinetam_targets.screening_date = film_screening_date_attendance_prev.screening_date
					inner join			availability_demo_matching as target_demo 
					on					inclusion_cinetam_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
					and					film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
					and					inclusion_cinetam_targets.complex_id = target_demo.complex_id
					inner join			availability_demo_matching as criteria_demo 
					on					@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and					film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and					inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
					where				campaign_package.campaign_package_status <> 'P'                
					and					campaign_package.follow_film = 'N'                
					group by			inclusion_cinetam_targets.screening_date,                 
										inclusion_cinetam_targets.complex_id) as temp_table                
inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id     

update			#availability_attendance_proj                
set				booked_all_people_attendance = isnull(booked_all_people_attendance,0) + convert(numeric(20,8), temp_table.attendance_target)                
from			(select			inclusion_cinetam_targets.screening_date,                 
								inclusion_cinetam_targets.complex_id,                 
								sum(inclusion_cinetam_targets.target_attendance  * duration / 30 / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target
				from			inclusion_cinetam_targets
				inner join		inclusion_cinetam_package on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
				inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
				inner join		#screening_dates on inclusion_cinetam_targets.screening_date = #screening_dates.screening_date                
				inner join		film_screening_date_attendance_prev on inclusion_cinetam_targets.screening_date = film_screening_date_attendance_prev.screening_date
				inner join		availability_demo_matching as target_demo 
				on				inclusion_cinetam_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
				and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
				and				inclusion_cinetam_targets.complex_id = target_demo.complex_id
				inner join		availability_demo_matching as criteria_demo 
				on				0 = criteria_demo.cinetam_reporting_demographics_id
				and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
				and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
				where			campaign_package.campaign_package_status <> 'P'                
				and				campaign_package.follow_film = 'N'                
				group by		inclusion_cinetam_targets.screening_date,                 
								inclusion_cinetam_targets.complex_id) as temp_table                
inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id   

--FAP
update			#availability_attendance_proj                
set				booked_demo_attendance = isnull(booked_demo_attendance,0) + convert(numeric(20,8), temp_table.attendance_target)                
from				(select				inclusion_follow_film_targets.screening_date,                 
										inclusion_follow_film_targets.complex_id,                 
										sum(inclusion_follow_film_targets.target_attendance  * duration / 30 / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target
					from				inclusion_follow_film_targets
					inner join			inclusion_cinetam_package on inclusion_follow_film_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
					inner join			campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
					inner join			#screening_dates on inclusion_follow_film_targets.screening_date = #screening_dates.screening_date                
					inner join			film_screening_date_attendance_prev on inclusion_follow_film_targets.screening_date = film_screening_date_attendance_prev.screening_date
					inner join			availability_demo_matching as target_demo 
					on					inclusion_follow_film_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
					and					film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
					and					inclusion_follow_film_targets.complex_id = target_demo.complex_id
					inner join			availability_demo_matching as criteria_demo 
					on					@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and					film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and					inclusion_follow_film_targets.complex_id = criteria_demo.complex_id
					where				campaign_package.campaign_package_status <> 'P'                
					and					campaign_package.follow_film = 'N'                
					group by			inclusion_follow_film_targets.screening_date,                 
										inclusion_follow_film_targets.complex_id) as temp_table                
inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id     

update			#availability_attendance_proj                
set				booked_all_people_attendance = isnull(booked_all_people_attendance,0) + convert(numeric(20,8), temp_table.attendance_target)                
from			(select			inclusion_follow_film_targets.screening_date,                 
								inclusion_follow_film_targets.complex_id,                 
								sum(inclusion_follow_film_targets.target_attendance  * duration / 30 / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target
				from			inclusion_follow_film_targets
				inner join		inclusion_cinetam_package on inclusion_follow_film_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
				inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
				inner join		#screening_dates on inclusion_follow_film_targets.screening_date = #screening_dates.screening_date                
				inner join		film_screening_date_attendance_prev on inclusion_follow_film_targets.screening_date = film_screening_date_attendance_prev.screening_date
				inner join		availability_demo_matching as target_demo 
				on				inclusion_follow_film_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
				and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
				and				inclusion_follow_film_targets.complex_id = target_demo.complex_id
				inner join		availability_demo_matching as criteria_demo 
				on				0 = criteria_demo.cinetam_reporting_demographics_id
				and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
				and				inclusion_follow_film_targets.complex_id = criteria_demo.complex_id
				where			campaign_package.campaign_package_status <> 'P'                
				and				campaign_package.follow_film = 'N'                
				group by		inclusion_follow_film_targets.screening_date,                 
								inclusion_follow_film_targets.complex_id) as temp_table                
inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id   

--RB
update			#availability_attendance_proj                
set				booked_demo_attendance = isnull(booked_demo_attendance,0) + (demo_attendance * duration_factor /** 0.75*/)
from			(select			inclusion_spot.screening_date,
								inclusion_cinetam_settings.complex_id,
								sum(convert(numeric(30,18) , campaign_package.duration / 30)) as duration_factor
				from			inclusion_cinetam_settings
				inner join		inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id
				inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
				inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id
				inner join		#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
				where			campaign_package.campaign_package_status <> 'P'                
				and				inclusion_cinetam_settings.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 30)                
				and				campaign_package.package_id not in (select package_id from campaign_category where instruction_type = 3 group by package_id having count(movie_category_code) >= 11)                
				group by		inclusion_spot.screening_date,                 
								inclusion_cinetam_settings.complex_id) as temp_table                
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id

update			#availability_attendance_proj                
set				booked_all_people_attendance = isnull(booked_all_people_attendance,0) + (all_people_attendance * duration_factor /** 0.75*/)
from			(select			inclusion_spot.screening_date,
								inclusion_cinetam_settings.complex_id,
								sum(convert(numeric(30,18) , campaign_package.duration / 30)) as duration_factor
				from			inclusion_cinetam_settings
				inner join		inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id
				inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
				inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id
				inner join		#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
				where			campaign_package.campaign_package_status <> 'P'                
				and				inclusion_cinetam_settings.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 30)                
				and				campaign_package.package_id not in (select package_id from campaign_category where instruction_type = 3 group by package_id having count(movie_category_code) >= 11)                
				group by		inclusion_spot.screening_date,                 
								inclusion_cinetam_settings.complex_id) as temp_table                
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id

--Revenue
update			#availability_attendance_proj
set				booked_30_sec_revenue = ISNULL(booked_30_sec_revenue,0) + revenue
from			(select			temp_table_two.screening_date,
								temp_table_two.complex_id,
								sum(charge_rate_30_sec * complex_attendance_share / inclusion_attendance_share) as revenue
				from			(select			inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id,
												inclusion_cinetam_settings.complex_id,
												inclusion_spot.charge_rate * campaign_package.duration / 30 as charge_rate_30_sec, 
												sum(isnull(percent_market,0))  as complex_attendance_share
								from			inclusion_spot
								inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
								inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
								inner join		film_screening_date_attendance_prev on inclusion_spot.screening_date = film_screening_date_attendance_prev.screening_date
								inner join		#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
								inner join		cinetam_complex_date_settings on film_screening_date_attendance_prev.prev_screening_date = cinetam_complex_date_settings.screening_date 
								and				inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
								and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
								inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
								inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id
								where			inclusion_type in (select inclusion_type from inclusion_type where inclusion_type_group = 'S')
								and				inclusion_status <> 'P'
								and				inclusion_cinetam_settings.complex_id not in (1,2)
								group by		inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id,
												inclusion_cinetam_settings.complex_id,
												inclusion_spot.charge_rate, 
												campaign_package.duration) as temp_table_two
				inner join		(select			inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id,
												sum(isnull(percent_market,0)) as inclusion_attendance_share
								from			inclusion_spot
								inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
								inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
								inner join		film_screening_date_attendance_prev on inclusion_spot.screening_date = film_screening_date_attendance_prev.screening_date
								inner join		#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
								inner join		cinetam_complex_date_settings on film_screening_date_attendance_prev.prev_screening_date = cinetam_complex_date_settings.screening_date 
								and				inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
								and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
								inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
								inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id
								where			inclusion_type in (select inclusion_type from inclusion_type where inclusion_type_group = 'S')
								and				inclusion_status <> 'P'
								and				inclusion_cinetam_settings.complex_id not in (1,2)
								group by		inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id) as temp_table_three
				on				temp_table_two.screening_date = temp_table_three.screening_date
				and				temp_table_two.inclusion_id = temp_table_three.inclusion_id
				where			temp_table_three.inclusion_attendance_share <> 0
				group by 		temp_table_two.screening_date,
								temp_table_two.complex_id) as temp_table
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id

update			#availability_attendance_proj
set				booked_revenue = ISNULL(booked_revenue,0) + revenue
from			(select			temp_table_two.screening_date,
								temp_table_two.complex_id,
								sum(charge_rate * complex_attendance_share / inclusion_attendance_share) as revenue
				from			(select			inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id,
												inclusion_cinetam_settings.complex_id,
												inclusion_spot.charge_rate, 
												sum(isnull(percent_market,0))  as complex_attendance_share
								from			inclusion_spot
								inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
								inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
								inner join		film_screening_date_attendance_prev on inclusion_spot.screening_date = film_screening_date_attendance_prev.screening_date
								inner join		#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
								inner join		cinetam_complex_date_settings on film_screening_date_attendance_prev.prev_screening_date = cinetam_complex_date_settings.screening_date 
								and				inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
								and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
								where			inclusion_type in (select inclusion_type from inclusion_type where inclusion_type_group = 'S')
								and				inclusion_status <> 'P'
								and				inclusion_cinetam_settings.complex_id not in (1,2)
								group by		inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id,
												inclusion_cinetam_settings.complex_id,
												inclusion_spot.charge_rate) as temp_table_two
				inner join		(select			inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id,
												sum(isnull(percent_market,0)) as inclusion_attendance_share
								from			inclusion_spot
								inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
								inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
								inner join		film_screening_date_attendance_prev on inclusion_spot.screening_date = film_screening_date_attendance_prev.screening_date
								inner join		#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
								inner join		cinetam_complex_date_settings on film_screening_date_attendance_prev.prev_screening_date = cinetam_complex_date_settings.screening_date 
								and				inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
								and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
								where			inclusion_type in (select inclusion_type from inclusion_type where inclusion_type_group = 'S')
								and				inclusion_status <> 'P'
								and				inclusion_cinetam_settings.complex_id not in (1,2)
								group by		inclusion_spot.screening_date, 
												inclusion_spot.inclusion_id) as temp_table_three
				on				temp_table_two.screening_date = temp_table_three.screening_date
				and				temp_table_two.inclusion_id = temp_table_three.inclusion_id
				where			temp_table_three.inclusion_attendance_share <> 0
				group by 		temp_table_two.screening_date,
								temp_table_two.complex_id) as temp_table
where			#availability_attendance_proj.screening_date = temp_table.screening_date                
and				#availability_attendance_proj.complex_id = temp_table.complex_id


/*                
 * Return                
 */    
 
select #availability_attendance_proj.*, @demo_desc as demo_desc, exhibitor_name, film_market_desc
 from    #availability_attendance_proj          
inner join complex on #availability_attendance_proj.complex_id = complex.complex_id
inner join film_market on complex.film_market_no = film_market.film_market_no
inner join exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id                
return 0
GO
