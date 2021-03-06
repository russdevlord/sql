/****** Object:  StoredProcedure [dbo].[p_availability_attendance_estimate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_attendance_estimate]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_attendance_estimate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[p_availability_attendance_estimate]		@country_code								char(1),                
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
                
declare			@error									int,                
				@population								int,                
				@attendance								int,                
				@all_people_attendance					int,                
				@reach									numeric(30,6),                
				@frequency								numeric(30,6),                
				@cpm									money,                
				@cost									money,                
				@market									varchar(30),                
				@screening_date							datetime,                
				@start_date								datetime,                
				@end_date								datetime,                
				@adjustment_factor						numeric(6,4),                
				@movie_adjustment_factor			    numeric(6,4),                
				@metro_avg								int,                
				@regional_avg							int,                
				@metro_screens							int,                
				@regional_screens						int,                
				@attendance_estimate					integer,                
				@attendance_pool						integer,                
				@metro_pool								integer,                
				@regional_pool							integer,                
				@metro_panels							integer,                
				@regional_panels						integer,                
				@attendance_population					integer,                
				@actual_population						integer,                      
				@movio_unique_transactions				integer,                
				@all_people_metro_avg					integer,                
				@all_people_regional_avg				integer,                
				@all_people_metro_pool					integer,                
				@all_people_regional_pool				integer,                
				@mm_adjustment							numeric(6,4),                
				@rows									integer,                
				@generation_date						datetime,                
				@duration								int,                
				@national_count							int,                
				@metro_count							int,                
				@regional_count							int,                
				@one									numeric(20,8)                
                
set nocount on                
                
select @one = 1.0                
                
/*                
 * Set generation date                
 */                
                
select @generation_date = getdate()                
                
/*                
 * Temp Tables                
 */                
                
create table #screening_dates                
(                
	screening_date         datetime   not null                
)                
                
create table #film_markets                
(                
	film_market_no         int     not null                
)                
                
create table #movie_categories                
(                
	movie_category_code		char(2)    not null                
)                
                
create table #exhibitors                
(           
	exhibitor_id           int     not null                
)                
                
create table #product_category_sub_concat                
(                
	product_category_sub_concat_id  int     not null                
)                
                
create table #product_category_sub_concat_linked                
(                
	product_category_sub_concat_id  int     not null         
)                
                
create table #availability_attendance                
(                
	screening_date								datetime			not null,                
	generation_date								datetime			not null,                
	country_code								char(1)				not null,                
	film_market_no								int					not null, 
	complex_id									int					not null,
	complex_name								varchar(50)			not null,
	preshow_time_slots_avail					numeric(20,8)		not null,
	preshow_time_slots_used_prodcat				numeric(20,8)		not null,
	preshow_time_slots_used_booking				numeric(20,8)		not null,
	preshow_time_length							numeric(20,8)		not null,
	movie_target								numeric(20,8)		not null,
	cinetam_reporting_demographics_id			int					not null,                
	cinetam_reachfreq_duration_id				int					not null,                
	exhibitor_id								int					not null,                
	product_category_sub_concat_id				int					not null,                
	movie_category_code							char(2)				not null,                
	demo_attendance								numeric(20,8)		not null,
	demo_average								numeric(20,8)		null,
	all_people_attendance						numeric(20,8)		not null,  
	demo_attendance_top_two						numeric(20,8)		not null,  
	demo_attendance_30sec_eqv					numeric(20,8)		not null,                
	demo_attendance_30sec_used					numeric(20,8)		not null,       
	demo_attendance_top_30sec					numeric(20,8)		not null,       
	demo_attendance_prod_cat					numeric(20,8)		not null,                
	product_booked_percentage					numeric(20,8)		not null,                
	current_booked_percentage					numeric(20,8)		not null,                
	product_slots_percentage					numeric(20,8)		not null,                
	current_slots_percentage					numeric(20,8)		not null,                
	projected_booked_percentage					numeric(20,8)		not null,                
	full_attendance								numeric(20,8)		not null,
	cinatt_weighting							numeric(20,8)		not null,
	previous_cinatt_weighting					numeric(20,8)		not null
)                
                
create table #top_movies                
(                
	screening_date								datetime			not null,                
	long_name									varchar(100)		not null,                
	movie_rank									int					not null                
)                
                
create table #movie_ids                
(                
	screening_date								datetime			not null,                
	movie_id									int					not null,                
	movie_rank									int					not null                
)                 
                
/*                
 * Parse Variables into the temp tables                
 */                
                
if len(@screening_dates) > 0                
	insert into #screening_dates                
	select * from dbo.f_multivalue_parameter(@screening_dates,',')                
                
if len(@film_markets) > 0                
	insert into #film_markets                
	select * from dbo.f_multivalue_parameter(@film_markets,',')                
                
if len(@movie_category_codes) > 0                
	insert into #movie_categories                
	select convert(char(2), param) from dbo.f_multivalue_parameter(@movie_category_codes,',')                
                
if len(@exhibitor_ids) > 0                
	insert into #exhibitors                
	select * from dbo.f_multivalue_parameter(@exhibitor_ids,',')                
               
insert into		#product_category_sub_concat                
values			(@product_category_sub_concat_id)                
                
insert into		#product_category_sub_concat_linked                
select			product_category_sub_concat_id                 
from			#product_category_sub_concat                
                
insert into		#product_category_sub_concat_linked                
select			product_category_sub_concat_id       
from			product_category_sub_concat                
where			product_category_id in (select product_category_id from product_category_sub_concat where product_category_sub_concat_id in (select product_category_sub_concat_id from #product_category_sub_concat))                
and				product_category_sub_concat_id not in (select product_category_sub_concat_id from #product_category_sub_concat_linked)                
and				product_subcategory_id is null                
                
select			@duration = max_duration                
from			cinetam_reachfreq_duration                
where			cinetam_reachfreq_duration_id = @cinetam_reachfreq_duration_id                
                
select			@national_count = count(*)                
from			#film_markets                
where			film_market_no = -100                
                
select			@metro_count = count(*)                
from			#film_markets                
where			film_market_no = -50                
        
select			@regional_count = count(*)                
from			#film_markets                
where			film_market_no = -25                
                
if @metro_count >= 1                
begin                
	delete			#film_markets                
	from			film_market                
	where			#film_markets.film_market_no = film_market.film_market_no                
	and				country_code = @country_code                
	and				regional = 'N'                
                
	insert into		#film_markets                
	select			film_market_no                
	from			film_market                
	where			country_code = @country_code                
	and				regional = 'N'                
end                
                
if @regional_count >= 1                
begin                
	delete			#film_markets                
	from			film_market                
	where			#film_markets.film_market_no = film_market.film_market_no                
	and				country_code = @country_code                
	and				regional = 'Y'                
                
	insert into		#film_markets                
	select			film_market_no                
	from			film_market                
	where			country_code = @country_code                
	and				regional = 'Y'                
end                
          
                
if @national_count >= 1                
begin                
	delete			#film_markets                
	from			film_market                
	where			#film_markets.film_market_no = film_market.film_market_no                
	and				country_code = @country_code                
                
	insert into		#film_markets                
	select			film_market_no                
	from			film_market                
	where			country_code = @country_code                
end                
                
insert into		#top_movies                
select			hist.screening_date,                
				case right(long_name,3) when ' 3D' then left(long_name, len(long_name) - 3) else long_name end,                
				rank() over (partition by hist.screening_date order by  sum(attendance) desc) as movie_rank                
from			movie_history hist
inner join		film_screening_date_attendance_prev on  hist.screening_date = film_screening_date_attendance_prev.prev_screening_date
inner join		#screening_dates on film_screening_date_attendance_prev.screening_date =#screening_dates.screening_date
inner join		movie on hist.movie_id = movie.movie_id and movie.is_movie='Y'                
where			hist.country = @country_code                
group by		hist.screening_date,                
				case right(long_name,3) when ' 3D' then left(long_name, len(long_name) - 3) else long_name end                
                
insert into		#movie_ids                
select			#top_movies.screening_date,                 
				movie.movie_id,                
				#top_movies.movie_rank                
from			#top_movies                    
inner join		movie on case right(movie.long_name,3) when ' 3D' then left(movie.long_name, len(movie.long_name) - 3) else movie.long_name end = #top_movies.long_name          
where			movie_id in (select movie_id from target_categories inner join  #movie_categories on target_categories.movie_category_code = #movie_categories.movie_category_code)                
and				movie_id not in (select movie_id from v_movie_classification where country_code = @country_code and ma_15_above = 0 and @ma15_above = 1)                
and				movie_id not in (select movie_id from target_categories where movie_category_code in ('AN', 'FC') and @exclude_children = 1)                
and				movie_id not in (select movie_id from movie_country where country_code = @country_code and release_date > #top_movies.screening_date)      
and				movie_id not in (select movie_id from v_movie_alcogamb where alcogamb_percent < 0.75 and @alcohol_gambling = 1)          
and				((@cinetam_reachfreq_mode_id = 3                
and				#top_movies.movie_rank != 1                
and				#top_movies.movie_rank != 2)                  
or				@cinetam_reachfreq_mode_id <> 3)          

/*
 * Generate Attendance Availability
 */

if @cinetam_reachfreq_mode_id = 1
begin                
	--you is in the wrong place! follow film has its own proc - review logic flow
	raiserror('Error: the non follow film proc is being called for a follow film', 16, 1)
	return -1                
end                
else if @cinetam_reachfreq_mode_id = 4
begin
	if @cinetam_reporting_demographics_id > 0                
	begin   
		--insert digilite info
		select @cinetam_reachfreq_mode_id = @cinetam_reachfreq_mode_id              
	end 
	else 
	begin 
		--insert digilite info
		select @cinetam_reachfreq_mode_id = @cinetam_reachfreq_mode_id              
	end
end
else
begin                
	if @cinetam_reporting_demographics_id > 0                
	begin                
		insert into		#availability_attendance                
		select			#screening_dates.screening_date,                
						@generation_date,                
						hist.country_code,                
						complex.film_market_no,                
						hist.complex_id, 
						complex.complex_name,         
						((cplx_date.max_time + cplx_date.mg_max_time) / 30) * cplx_date.movie_target,/*0.0,*/
						0,
						0,
						(cplx_date.max_time + cplx_date.mg_max_time),
						cplx_date.movie_target,
						cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,                
						@cinetam_reachfreq_duration_id,                
						complex.exhibitor_id,                
						product_category_sub_concat_id,                
						'',                
						sum(hist.attendance) as demo_attendance,      
						(select			isnull(avg_mm_attendance ,0)
						from			v_availability_avg_cplx_attendance
						where			v_availability_avg_cplx_attendance.complex_id = hist.complex_id 
						and				v_availability_avg_cplx_attendance.screening_date = film_screening_date_attendance_prev.prev_screening_date
						and				v_availability_avg_cplx_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) as demo_avg,
						(select			isnull(sum(attendance),0)  as all_people_attendance                
						from			movie_history hist_all                
						inner join		complex as complex_all on hist_all.complex_id = complex_all.complex_id                
						inner join		#movie_ids as ids_all on hist_all.movie_id = ids_all.movie_id and hist_all.screening_date = ids_all.screening_date                
						cross join		#product_category_sub_concat as prod_cat_all                
						where			hist_all.country = @country_code     
						and				complex_all.film_complex_status <> 'C'    
						and				hist_all.complex_id = hist.complex_id                
						and				hist_all.screening_date = film_screening_date_attendance_prev.prev_screening_date        
						and				prod_cat_all.product_category_sub_concat_id = #product_category_sub_concat.product_category_sub_concat_id                
						and				hist_all.premium_cinema <> 'Y'                
						and				((hist_all.advertising_open = 'Y'                
						and				@cinetam_reachfreq_mode_id <> 5)                
						or				@cinetam_reachfreq_mode_id = 5)) as all_people_attendance,          
						sum(case when #movie_ids.movie_rank <= 2 then hist.attendance else 0 end) as top_two_attendance ,                
						0.0,
						0.0,
						0.0,
						0.0,
						0.0,
						0.0,
						0,                
						0,                
						0,                
						case when @cinetam_reachfreq_mode_id <> 5 then 0 
						else	(select			isnull(sum(attendance),0) as full_attendance                
								from			movie_history as hist_all        
								inner join		complex as complex_all on hist_all.complex_id = complex_all.complex_id        
								inner join		#exhibitors e on complex_all.exhibitor_id = e.exhibitor_id            
								--inner join	#screening_dates as scr_dat_all on hist_all.screening_date = film_screening_date_attendance_prev.prev_screening_date                                
								inner join		movie as m on hist_all.movie_id=m.movie_id     
								where			hist_all.country = @country_code       
								and				hist_all.movie_id not in (select movie_id from movie_country where country_code = @country_code and release_date > hist_all.screening_date)  
								and				m.is_movie = 'Y'  
								and				complex_all.film_complex_status <> 'C'    
								and				hist_all.screening_date = film_screening_date_attendance_prev.prev_screening_date                  
								and				hist_all.premium_cinema <> 'Y'  
								and				@cinetam_reachfreq_mode_id = 5) 
						end as full_attendance,
						cplx_date.cinatt_weighting,
						prev_cplx_date.cinatt_weighting
		from			cinetam_movie_history hist                
		inner join		movie mov on hist.movie_id = mov.movie_id                
		inner join		complex on hist.complex_id = complex.complex_id                
		inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no                
		inner join		#exhibitors on complex.exhibitor_id = #exhibitors.exhibitor_id                
		inner join		film_screening_date_attendance_prev on  hist.screening_date = film_screening_date_attendance_prev.prev_screening_date
		inner join		#screening_dates on film_screening_date_attendance_prev.screening_date = #screening_dates.screening_date
		inner join		cinetam_reporting_demographics_xref on hist.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id                
		inner join		movie_history movhist on hist.movie_id = movhist.movie_id       
		and				hist.complex_id = movhist.complex_id                
		and				hist.screening_date = movhist.screening_date                
		and				hist.occurence = movhist.occurence                
		and				hist.print_medium = movhist.print_medium                
		and				hist.three_d_type = movhist.three_d_type                
		inner join		#movie_ids on hist.movie_id = #movie_ids.movie_id and hist.screening_date = #movie_ids.screening_date                
		inner join		complex_date cplx_date on hist.complex_id = cplx_date.complex_id and #screening_dates.screening_date = cplx_date.screening_date
		inner join		complex_date prev_cplx_date on hist.complex_id = prev_cplx_date.complex_id and hist.screening_date = prev_cplx_date.screening_date
		cross join		#product_category_sub_concat                
		where			hist.country_code = @country_code                
		and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id                
		and				premium_cinema <> 'Y' 
		and				complex.film_complex_status <> 'C'           
		and				((movhist.advertising_open = 'Y'                
		and				@cinetam_reachfreq_mode_id <> 5)                
		or				@cinetam_reachfreq_mode_id = 5)      
		group by		#screening_dates.screening_date,                
						film_screening_date_attendance_prev.prev_screening_date,
						hist.screening_date,                
						complex.film_market_no,                
						hist.complex_id,       
						complex.complex_name,         
						cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,                
						complex.exhibitor_id,                
						product_category_sub_concat_id,                
						hist.country_code,
						cplx_date.movie_target,
						((cplx_date.max_time + cplx_date.mg_max_time) / 30) * cplx_date.movie_target,
						(cplx_date.max_time + cplx_date.mg_max_time),
						cplx_date.cinatt_weighting,
						prev_cplx_date.cinatt_weighting
                 
		select @error = @@error                
		if @error <> 0                 
		begin                
			raiserror('Error: failed to insert basic attendance info', 16, 1)
			return -1                
		end                
	end                
	else                
	begin                
		insert into		#availability_attendance                
		select			#screening_dates.screening_date,                
						@generation_date,                
						hist.country,                
						complex.film_market_no,                
						complex.complex_id,    
						complex.complex_name, 
						((cplx_date.max_time + cplx_date.mg_max_time) / 30) * cplx_date.movie_target,
						0,
						0,
						(cplx_date.max_time + cplx_date.mg_max_time),
						cplx_date.movie_target,
						0,                
						@cinetam_reachfreq_duration_id,                
						complex.exhibitor_id,                
						product_category_sub_concat_id,                
						'',                
						sum(hist.attendance) as demo_attendance,                
						(select			isnull(avg_mm_attendance ,0)
						from			v_availability_avg_cplx_attendance
						where			v_availability_avg_cplx_attendance.complex_id = complex.complex_id 
						and				v_availability_avg_cplx_attendance.screening_date =film_screening_date_attendance_prev.prev_screening_date
						and				v_availability_avg_cplx_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) as demo_avg,
						sum(hist.attendance) as all_people_attendance,                
						sum(case when  #movie_ids.movie_rank <= 2 then hist.attendance else 0 end) as top_two_attendance ,                
						0.0,
						0.0,
						0.0,
						0.0,
						0.0,
						0.0,
						0,                
						0,                
						0,                
						case when @cinetam_reachfreq_mode_id <> 5 then 0 
						else (	select			isnull(sum(attendance),0)  as full_attendance                
								from			movie_history as hist_all        
								inner join		complex as complex_all on hist_all.complex_id = complex_all.complex_id        
								inner join		#exhibitors e on complex_all.exhibitor_id = e.exhibitor_id            																
								inner join		movie as m on hist_all.movie_id=m.movie_id     
								where			hist_all.country = @country_code       
								and				hist_all.movie_id  not in (select movie_id from movie_country where country_code = @country_code and release_date > hist_all.screening_date)  
								and				m.is_movie='Y' 
								and				complex_all.film_complex_status <> 'C'    
								and				hist_all.screening_date = film_screening_date_attendance_prev.prev_screening_date                       
								and				hist_all.premium_cinema <> 'Y'  
								and				@cinetam_reachfreq_mode_id = 5) end as full_attendance,
						cplx_date.cinatt_weighting,
						prev_cplx_date.cinatt_weighting         
		from			movie_history hist                
		inner join		movie mov on hist.movie_id = mov.movie_id                
		inner join		complex on hist.complex_id = complex.complex_id                
		inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no                
		inner join		#exhibitors on complex.exhibitor_id = #exhibitors.exhibitor_id                
		inner join		film_screening_date_attendance_prev on hist.screening_date = film_screening_date_attendance_prev.prev_screening_date
		inner join		#screening_dates on film_screening_date_attendance_prev.screening_date = #screening_dates.screening_date
		inner join		#movie_ids on hist.movie_id = #movie_ids.movie_id and hist.screening_date = #movie_ids.screening_date                
		inner join		complex_date cplx_date on hist.complex_id = cplx_date.complex_id and #screening_dates.screening_date = cplx_date.screening_date
		inner join		complex_date prev_cplx_date on hist.complex_id = prev_cplx_date.complex_id and hist.screening_date = prev_cplx_date.screening_date
		cross join		#product_category_sub_concat                
		where			hist.country = @country_code     
		and				complex.film_complex_status <> 'C'               
		and				premium_cinema <> 'Y'                
		and				((hist.advertising_open = 'Y'                
		and				@cinetam_reachfreq_mode_id <> 5)                
		or				@cinetam_reachfreq_mode_id = 5)                
		group by		#screening_dates.screening_date,     
						film_screening_date_attendance_prev.prev_screening_date,           
						complex.film_market_no,                
						complex.complex_id,        
						complex.complex_name,        
						complex.exhibitor_id,                
						product_category_sub_concat_id,                
						hist.country , 
						cplx_date.movie_target,
						((cplx_date.max_time + cplx_date.mg_max_time) / 30) * cplx_date.movie_target,
						(cplx_date.max_time + cplx_date.mg_max_time),
						cplx_date.cinatt_weighting,
						prev_cplx_date.cinatt_weighting
                 
		select @error = @@error                
		if @error <> 0                 
		begin                
			raiserror('Error: failed to insert basic attendance info', 16, 1) 
			return -1                
		end                
	end                
end             

/*                
 * Update MM Adjustment               
 */            
                
update			#availability_attendance                
set				demo_attendance  = (demo_attendance *  (@one + temp_table.mm_adjustment)) * (@manual_adjustment_factor),
				all_people_attendance = (all_people_attendance *  (@one + temp_table.mm_adjustment)) * (@manual_adjustment_factor),
				full_attendance  = (full_attendance *  (@one + temp_table.mm_adjustment)),
				demo_attendance_top_two	= (demo_attendance_top_two *  (@one + temp_table.mm_adjustment))             
from			(select			screening_date,  
								film_market_no,
								max(mm_adjustment) as mm_adjustment                
				from			cinetam_reachfreq_population                
				where			country_code = @country_code                
				group by		screening_date,  
								film_market_no) as temp_table ,
				film_screening_date_attendance_prev             
where			temp_table.screening_date = film_screening_date_attendance_prev.prev_screening_date
and				#availability_attendance.screening_date = film_screening_date_attendance_prev.screening_date
and				#availability_attendance.film_market_no = temp_table.film_market_no


/*
 * Update Cin Att Weightings 
 */


update			#availability_attendance                
set				demo_attendance = demo_attendance * cinatt_weighting / previous_cinatt_weighting, 
				all_people_attendance = all_people_attendance * cinatt_weighting / previous_cinatt_weighting, 
				full_attendance = full_attendance * cinatt_weighting / previous_cinatt_weighting, 
				demo_attendance_top_two	= demo_attendance_top_two * cinatt_weighting / previous_cinatt_weighting 
where			previous_cinatt_weighting <> cinatt_weighting	
and				previous_cinatt_weighting <> 0


/* 
 * Fix Any Null amounts
 */

update				#availability_attendance                
set					demo_attendance = isnull(demo_attendance, 0.0),
					all_people_attendance = isnull(all_people_attendance, 0.0),
					full_attendance = isnull(full_attendance, 0.0),
					demo_attendance_top_two = isnull(demo_attendance_top_two, 0.0)

/*
 * set playlists to zero if negative
 */

update				#availability_attendance
set					preshow_time_slots_avail = 0
where				preshow_time_slots_avail < 0

/*
 * Set 30 Sec Eqv pool
 */

update				#availability_attendance
set					demo_attendance_30sec_eqv = demo_attendance * ((complex_date.max_time + complex_date.mg_max_time) / 30),
					demo_attendance_top_30sec = demo_attendance_top_two * ((complex_date.max_time + complex_date.mg_max_time) / 30)
from				complex_date
where				#availability_attendance.complex_id = complex_date.complex_id
and					#availability_attendance.screening_date = complex_date.screening_date

delete				#availability_attendance
where				demo_attendance_30sec_eqv = 0

/*                
 * Calculate Current Bookings                
 */                
                
if @cinetam_reachfreq_mode_id = 2 or @cinetam_reachfreq_mode_id = 3 or @cinetam_reachfreq_mode_id = 5                 
begin        
	 --follow film product clash                
	update			#availability_attendance                
	set				demo_attendance_prod_cat = demo_attendance_prod_cat + convert(numeric(20,8), temp_table.attendance_target),
					preshow_time_slots_used_prodcat = preshow_time_slots_used_prodcat + (convert(numeric(20,8), temp_table.attendance_target) / convert(numeric(20,8), #availability_attendance.demo_attendance_30sec_eqv))
	from			(select				inclusion_follow_film_targets.screening_date,                 
										inclusion_follow_film_targets.complex_id,                 
										sum(inclusion_follow_film_targets.target_attendance / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target                
					from				inclusion_follow_film_targets                
					inner join			inclusion_cinetam_package on inclusion_follow_film_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
					inner join			campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
					inner join			#screening_dates on inclusion_follow_film_targets.screening_date = #screening_dates.screening_date                
					inner join			product_category_sub_concat on product_category_sub_concat.product_category_id = campaign_package.product_category and isnull(product_category_sub_concat.product_subcategory_id, 0) = isnull(campaign_package.product_subcategory, 0)       
					inner join			#product_category_sub_concat on #product_category_sub_concat.product_category_sub_concat_id = product_category_sub_concat.product_category_sub_concat_id
					inner join			film_screening_date_attendance_prev on inclusion_follow_film_targets.screening_date = film_screening_date_attendance_prev.screening_date
					inner join			availability_demo_matching as target_demo 
					on					inclusion_follow_film_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
					and					film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
					and					inclusion_follow_film_targets.complex_id = target_demo.complex_id
					inner join			availability_demo_matching as criteria_demo 
					on					@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and					film_screening_date_attendance_prev.prev_screening_date =  criteria_demo.screening_date
					and					inclusion_follow_film_targets.complex_id = criteria_demo.complex_id
					where				campaign_package.campaign_package_status <> 'P'                
					and					inclusion_follow_film_targets.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 29)                
					and					(allow_product_clashing = 'N'                
					or					client_clash = 'N')                
					group by			inclusion_follow_film_targets.screening_date,                 
										inclusion_follow_film_targets.complex_id) as temp_table                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id             
                
	--road block product clash                
	update			#availability_attendance                
	set				demo_attendance_prod_cat = demo_attendance_prod_cat + demo_attendance,
					preshow_time_slots_used_prodcat = preshow_time_slots_avail
	from			(select				inclusion_spot.screening_date,                 
										inclusion_cinetam_settings.complex_id            
					from				inclusion_cinetam_settings                
					inner join			inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id                
					inner join			inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id                
					inner join			campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
					inner join			#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date                
					inner join			product_category_sub_concat on product_category_sub_concat.product_category_id = campaign_package.product_category and isnull(product_category_sub_concat.product_subcategory_id, 0) = isnull(campaign_package.product_subcategory, 0)        
					inner join			#product_category_sub_concat on #product_category_sub_concat.product_category_sub_concat_id = product_category_sub_concat.product_category_sub_concat_id                
					where				campaign_package.campaign_package_status <> 'P'                
					and					inclusion_cinetam_settings.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 30)                
					and					campaign_package.package_id not in (select package_id from campaign_category where instruction_type = 3 group by package_id having count(movie_category_code) >= 11)                
					and					(allow_product_clashing = 'N'                
					or					client_clash = 'N')                
					group by			inclusion_spot.screening_date,                 
										inclusion_cinetam_settings.complex_id) as temp_table                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id                
                
	--follow film general booking level                
	update			#availability_attendance                
	set				demo_attendance_30sec_used = demo_attendance_30sec_used + convert(numeric(20,8), temp_table.attendance_target),
					preshow_time_slots_used_booking = preshow_time_slots_used_booking + (convert(numeric(20,8), temp_table.attendance_target) / convert(numeric(20,8), #availability_attendance.demo_attendance_30sec_eqv) * preshow_time_slots_avail)
	from			(select				inclusion_follow_film_targets.screening_date, 
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
					and					inclusion_follow_film_targets.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 29)
					group by			inclusion_follow_film_targets.screening_date,
										inclusion_follow_film_targets.complex_id) as temp_table
	where			#availability_attendance.screening_date = temp_table.screening_date
	and				#availability_attendance.complex_id = temp_table.complex_id
                 
	--roadblock general booking level                
	update			#availability_attendance                
	set				demo_attendance_30sec_used = demo_attendance_30sec_used + (demo_attendance * duration_factor /** 0.75*/),
					preshow_time_slots_used_booking = preshow_time_slots_used_booking + (duration_factor * movie_target)
	from			(select				inclusion_spot.screening_date,
										inclusion_cinetam_settings.complex_id,
										sum(convert(numeric(30,18) , campaign_package.duration / 30)) as duration_factor
					from				inclusion_cinetam_settings
					inner join			inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id
					inner join			inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
					inner join			campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id
					inner join			#screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date
					where				campaign_package.campaign_package_status <> 'P'                
					and					inclusion_cinetam_settings.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 30)                
					and					campaign_package.package_id not in (select package_id from campaign_category where instruction_type = 3 group by package_id having count(movie_category_code) >= 11)                
					group by			inclusion_spot.screening_date,                 
										inclusion_cinetam_settings.complex_id) as temp_table                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id
end                

if @cinetam_reachfreq_mode_id = 2 or @cinetam_reachfreq_mode_id = 3                
begin                
	--movie mix client clash                
	update			#availability_attendance                
	set				demo_attendance_prod_cat = demo_attendance_prod_cat + (((temp_table.no_spots / case when cd.movie_target = 0 then 1 else cd.movie_target end) * 0.5) * demo_attendance),
					preshow_time_slots_used_prodcat = preshow_time_slots_used_prodcat + (no_spots + #availability_attendance.movie_target)
	from			(select			campaign_spot.screening_date,                 
									campaign_spot.complex_id,                 
									count(campaign_spot.spot_id) as no_spots                
					from			campaign_spot                
					inner join		campaign_package on  campaign_spot.package_id = campaign_package.package_id 
					inner join		#screening_dates on campaign_spot.screening_date = #screening_dates.screening_date                
					inner join		product_category_sub_concat on product_category_sub_concat.product_category_id = campaign_package.product_category and isnull(product_category_sub_concat.product_subcategory_id, 0) = isnull(campaign_package.product_subcategory, 0)
 					inner join		#product_category_sub_concat on #product_category_sub_concat.product_category_sub_concat_id = product_category_sub_concat.product_category_sub_concat_id                
					where			campaign_package.campaign_package_status <> 'P'                
					and				campaign_package.follow_film = 'N'                
					and				(allow_product_clashing = 'N'                
					or				client_clash = 'N')        
					and				film_plan_id is null
					and				spot_type not in ('A', 'F', 'K', 'T', 'V', 'M')        
					group by		campaign_spot.screening_date,                 
									campaign_spot.complex_id) as temp_table                
	inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id     
                
	--movie mix general booking level                
	update			#availability_attendance                
	set				demo_attendance_30sec_used = demo_attendance_30sec_used + (demo_attendance_30sec_eqv * ((temp_table.no_30sec_spots /** .75*/)  / case when preshow_time_slots_avail = 0 then 1 else preshow_time_slots_avail end )),
					preshow_time_slots_used_booking = preshow_time_slots_used_booking + no_30sec_spots
	from			(select			campaign_spot.screening_date,                 
									campaign_spot.complex_id,                 
									sum(convert(numeric(30,18), duration) / 30.0) as no_30sec_spots                
					from			campaign_spot                
					inner join		campaign_package on  campaign_spot.package_id = campaign_package.package_id 
					inner join		#screening_dates on campaign_spot.screening_date = #screening_dates.screening_date                
					where			campaign_package.campaign_package_status <> 'P'                
					and				campaign_package.follow_film = 'N'                
					and				film_plan_id is null        
					and				spot_type not in ('A', 'F', 'K', 'T')        
					group by		campaign_spot.screening_date,                 
									campaign_spot.complex_id) as temp_table                
	inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id  

	--map audience clash
	update			#availability_attendance                
	set				demo_attendance_prod_cat = demo_attendance_prod_cat + convert(numeric(20,8), temp_table.attendance_target)  ,
					preshow_time_slots_used_prodcat = preshow_time_slots_used_prodcat + (convert(numeric(20,8), temp_table.attendance_target) / convert(numeric(20,8), #availability_attendance.demo_attendance_30sec_eqv) * preshow_time_slots_avail)              
	from			(select			inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id,                 
									sum(inclusion_cinetam_targets.target_attendance / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target
					from			inclusion_cinetam_targets
					inner join		inclusion_cinetam_package on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
					inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
					inner join		#screening_dates on inclusion_cinetam_targets.screening_date = #screening_dates.screening_date                
					inner join		product_category_sub_concat on product_category_sub_concat.product_category_id = campaign_package.product_category and isnull(product_category_sub_concat.product_subcategory_id, 0) = isnull(campaign_package.product_subcategory, 0)        
					inner join		#product_category_sub_concat on #product_category_sub_concat.product_category_sub_concat_id = product_category_sub_concat.product_category_sub_concat_id                
					inner join		film_screening_date_attendance_prev on inclusion_cinetam_targets.screening_date = film_screening_date_attendance_prev.screening_date
					inner join		availability_demo_matching as target_demo 
					on				inclusion_cinetam_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = target_demo.complex_id
					inner join		availability_demo_matching as criteria_demo 
					on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
					where			campaign_package.campaign_package_status <> 'P'                
					and				inclusion_cinetam_targets.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 32)         
					and				campaign_package.follow_film = 'N'                
					and				(allow_product_clashing = 'N'                
					or				client_clash = 'N')                
					group by		inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id) as temp_table                
	inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id          
	
                
	--map general booking level                
	update			#availability_attendance                
	set				demo_attendance_30sec_used = demo_attendance_30sec_used + convert(numeric(20,8), temp_table.attendance_target),
					preshow_time_slots_used_booking = preshow_time_slots_used_booking + (convert(numeric(20,8), temp_table.attendance_target) / convert(numeric(20,8), #availability_attendance.demo_attendance_30sec_eqv) * preshow_time_slots_avail)                
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
					on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
					where			campaign_package.campaign_package_status <> 'P'                
					and				inclusion_cinetam_targets.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 32)         
					and				campaign_package.follow_film = 'N'                
					group by		inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id) as temp_table                
	inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id          
	
end                

if @cinetam_reachfreq_mode_id = 3                
begin                
	--tap client clash                
	update			#availability_attendance                
	set				demo_attendance_prod_cat = demo_attendance_prod_cat + convert(numeric(20,8), temp_table.attendance_target),
					preshow_time_slots_used_prodcat = preshow_time_slots_used_prodcat + (convert(numeric(20,8), temp_table.attendance_target) / convert(numeric(20,8), #availability_attendance.demo_attendance_30sec_eqv) * preshow_time_slots_avail)                
	from			(select			inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id,                 
									sum(inclusion_cinetam_targets.target_attendance / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end ) as attendance_target
					from			inclusion_cinetam_targets
					inner join		inclusion_cinetam_package on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_package.inclusion_id                
					inner join		campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id                
					inner join		#screening_dates on inclusion_cinetam_targets.screening_date = #screening_dates.screening_date                
					inner join		product_category_sub_concat on product_category_sub_concat.product_category_id = campaign_package.product_category and isnull(product_category_sub_concat.product_subcategory_id, 0) = isnull(campaign_package.product_subcategory, 0)        
					inner join		#product_category_sub_concat on #product_category_sub_concat.product_category_sub_concat_id = product_category_sub_concat.product_category_sub_concat_id                
					inner join		film_screening_date_attendance_prev on inclusion_cinetam_targets.screening_date = film_screening_date_attendance_prev.screening_date
					inner join		availability_demo_matching as target_demo 
					on				inclusion_cinetam_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = target_demo.complex_id
					inner join		availability_demo_matching as criteria_demo 
					on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
					where			campaign_package.campaign_package_status <> 'P'                
					and				inclusion_cinetam_targets.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 24)         
					and				campaign_package.follow_film = 'N'                
					and				(allow_product_clashing = 'N'                
					or				client_clash = 'N')                
					group by		inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id) as temp_table                
	inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id          
	
                
	--tap general booking level                
	update			#availability_attendance                
	set				demo_attendance_30sec_used = demo_attendance_30sec_used + convert(numeric(20,8), temp_table.attendance_target),
					preshow_time_slots_used_booking = preshow_time_slots_used_booking + (convert(numeric(20,8), temp_table.attendance_target) / convert(numeric(20,8), #availability_attendance.demo_attendance_30sec_eqv) * preshow_time_slots_avail)                
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
					on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
					where			campaign_package.campaign_package_status <> 'P'                
					and				inclusion_cinetam_targets.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 24)         
					and				campaign_package.follow_film = 'N'                
					group by		inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id) as temp_table                
	inner join		complex_date cd on temp_table.complex_id = cd.complex_id and temp_table.screening_date = cd.screening_date                
	where			#availability_attendance.screening_date = temp_table.screening_date                
	and				#availability_attendance.complex_id = temp_table.complex_id     

	/*
	 * Tap - reduce booking level as most bookings are on top two movies
	 */

	update			#availability_attendance
	set				demo_attendance_prod_cat = demo_attendance_prod_cat * 0.8,
					demo_attendance_30sec_used = demo_attendance_30sec_used * 0.8

end                

/*
 * Set Percentages
 */

update			#availability_attendance
set				product_booked_percentage = demo_attendance_prod_cat / case when demo_attendance = 0 then 1 else demo_attendance end
where			demo_attendance <> 0

update			#availability_attendance
set				current_booked_percentage = demo_attendance_30sec_used / case when demo_attendance_30sec_eqv = 0 then 1 else demo_attendance_30sec_eqv end
where			demo_attendance_30sec_eqv <> 0
                
update			#availability_attendance
set				product_slots_percentage = (preshow_time_slots_used_prodcat + ((@duration / 30) * movie_target)) / case when preshow_time_slots_avail = 0 then 1 else preshow_time_slots_avail end
where			preshow_time_slots_avail <> 0
                
update			#availability_attendance
set				current_slots_percentage = (preshow_time_slots_used_booking + ((@duration / 30) * movie_target)) / case when preshow_time_slots_avail = 0 then 1 else preshow_time_slots_avail end
where			preshow_time_slots_avail <> 0

update			#availability_attendance
set				current_booked_percentage = 1
where			preshow_time_length < @duration

/*
 * Premium Position
 */              

if @premium_position = 1
begin
	--store complex, data & demo
	select			complex_id,
					screening_date,
					sum(demo_attendance) as demo_attendance,
					convert(numeric(20,8), 0) as premium_booking
	into			#premium_position_booking_level
	from			#availability_attendance
	group by		complex_id,
					screening_date

	--fap
	update			#premium_position_booking_level
	set				premium_booking = isnull(premium_booking,0) + case when demo_attendance = 0 then 0 else isnull(attendance_target / demo_attendance,0) end
	from			(select			inclusion_follow_film_targets.screening_date,                 
									inclusion_follow_film_targets.complex_id,                 
									sum(inclusion_follow_film_targets.target_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end) ) as attendance_target
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
					on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and				inclusion_follow_film_targets.complex_id = criteria_demo.complex_id
					where			campaign_package.campaign_package_status <> 'P'                
					and				campaign_package.screening_trailers in ('B', 'F')                
					group by		inclusion_follow_film_targets.screening_date,                 
									inclusion_follow_film_targets.complex_id) as temp_table
	where			#premium_position_booking_level.complex_id = temp_table.complex_id
	and				#premium_position_booking_level.screening_date = temp_table.screening_date	
	
	--map and tap
	update			#premium_position_booking_level
	set				premium_booking = isnull(premium_booking,0) + case when demo_attendance = 0 then 0 else isnull(attendance_target / demo_attendance,0) end
	from			(select			inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id,                 
									sum(inclusion_cinetam_targets.target_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end) ) as attendance_target
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
					on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
					and				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
					and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
					where			campaign_package.campaign_package_status <> 'P'                
					and				campaign_package.follow_film = 'N'                
					and				campaign_package.screening_trailers in ('B', 'F')                
					group by		inclusion_cinetam_targets.screening_date,                 
									inclusion_cinetam_targets.complex_id) as temp_table
	where			#premium_position_booking_level.complex_id = temp_table.complex_id
	and				#premium_position_booking_level.screening_date = temp_table.screening_date	

	--movie mix spot buy
	update			#premium_position_booking_level
	set				premium_booking = premium_booking + isnull(premium_positions,0)
	from			(select			complex_id,
									screening_date,
									case when movie_target <> 0 then premium_spots / convert(numeric(20,8), (movie_target / 2.0)) else 0 end as premium_positions
					from			(select			complex_id,
													screening_date,
													convert(numeric(20,8), count(campaign_package.package_id)) as premium_spots,
													(select movie_target from complex_date where screening_date = campaign_spot.screening_date and complex_id = campaign_spot.complex_id) as movie_target
									from			campaign_spot
									inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id 
									where			campaign_spot.spot_status not in  ('P', 'C', 'H', 'D')
									and				campaign_package.screening_trailers in ('B', 'F') 
									and				spot_type not in ('A', 'K', 'F', 'T')
									group by		complex_id,
													screening_date) as temp_table) as update_table
	where			#premium_position_booking_level.complex_id = update_table.complex_id
	and				#premium_position_booking_level.screening_date = update_table.screening_date

	--select * from #premium_position_booking_level
	update			#availability_attendance
	set				product_booked_percentage = premium_booking
	from			#premium_position_booking_level
	where			#availability_attendance.complex_id = #premium_position_booking_level.complex_id
	and				#availability_attendance.screening_date = #premium_position_booking_level.screening_date
	and				product_booked_percentage < premium_booking
end

/*                
 * Fix over percentages                
 */                
                
update				#availability_attendance                
set					product_booked_percentage = 1.0                
where				product_booked_percentage >= 1.0                
      
update				#availability_attendance                
set					current_booked_percentage = 1.0                
where				current_booked_percentage >= 1.0  

update				#availability_attendance                
set					product_slots_percentage = 1.0                
where				product_slots_percentage >= 1.0                
      
update				#availability_attendance                
set					current_slots_percentage = 1.0                
where				current_slots_percentage >= 1.0                


if  @cinetam_reachfreq_mode_id = 5 --Roadblock
	update				#availability_attendance                
	set					current_booked_percentage = 0
	where				current_booked_percentage < 1.0

update				#availability_attendance                
set					current_booked_percentage = product_booked_percentage                
where				product_booked_percentage > current_booked_percentage                

update				#availability_attendance                
set					current_booked_percentage = product_slots_percentage                
where				product_slots_percentage > current_booked_percentage  

update				#availability_attendance                
set					current_booked_percentage = current_slots_percentage                
where				current_slots_percentage > current_booked_percentage  

/*                
 * Return Data or insert into table                
 */                

select			screening_date,                
				generation_date,                
				country_code,                
				film_market_no,
				complex_id,          
				complex_name,       
				cinetam_reporting_demographics_id,                
				cinetam_reachfreq_duration_id,                
				exhibitor_id,                
				product_category_sub_concat_id,                
				movie_category_code,                
				demo_attendance ,                
				all_people_attendance,                
				product_booked_percentage,                
				current_booked_percentage,                
				projected_booked_percentage,                     
				full_attendance                
from			#availability_attendance                 
where			demo_attendance <> 0

/*                
 * Return                
 */                
                
return 0
GO
