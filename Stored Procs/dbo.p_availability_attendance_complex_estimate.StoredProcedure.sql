/****** Object:  StoredProcedure [dbo].[p_availability_attendance_complex_estimate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_attendance_complex_estimate]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_attendance_complex_estimate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_availability_attendance_complex_estimate] 			@country_code											char(1),                
																												@cinetam_reachfreq_mode_id					int, --mode for MM, TAP, RB, Digilite                
																												@screening_dates										varchar(max),                
																												@cinetam_reporting_demographics_id		int,                
																												@product_category_sub_concat_id				int,                
																												@cinetam_reachfreq_duration_id				int,                
																												@exhibitor_ids											varchar(max),                
																												@manual_adjustment_factor						numeric(20,8),                
																												@premium_position										bit,                
																												@alcohol_gambling										bit,                
																												@ma15_above												bit,                
																												@exclude_children										bit,                
																												@complex_ids												varchar(max) 

as

declare			@error											int,
					@film_markets							varchar(max),                
					@movie_category_codes				varchar(max)

create table #complex_avails
(
	screening_date											datetime				not null,
	generation_date											datetime				not null,
	country_code												char(1)					not null, 
	film_market_no											int						not null,
	complex_id													int						not null,
	complex_name												varchar(50)			not null,
	cinetam_reporting_demographics_id			int						not null,
	cinetam_reachfreq_duration_id					int						not null,
	exhibitor_id													int						not null,
	product_category_sub_concat_id				int						not null,
	movie_category_code									char(2)					not null,
	demo_attendance 										numeric(20,8)		not null,
	all_people_attendance									numeric(20,8)		not null,
	product_booked_percentage						numeric(20,8)		not null,
	current_booked_percentage						numeric(20,8)		not null,
	projected_booked_percentage					numeric(20,8)		not null,
	full_attendance											numeric(20,8)		not null
)

select @film_markets = coalesce(@film_markets + ',', '') + convert(varchar(2), film_market_no )
from film_market
where country_code = @country_code

select @movie_category_codes = coalesce(@movie_category_codes + ',', '') + convert(varchar(2), movie_category_code )
from movie_category


                
create table #complexes                
(                
	complex_id											        int					    not null                
)       

if len(@complex_ids) > 0                
	insert into #complexes                
	select * from dbo.f_multivalue_parameter(@complex_ids,',')            


insert into #complex_avails
exec @error = p_availability_attendance_estimate 				@country_code, 
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
	raiserror ('Error running availability procedure', 16, 1)
	return -1
end

select			screening_date,                
					generation_date,                
					country_code,                
					film_market_no,                
					#complex_avails.complex_id,          
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
from				#complex_avails            
inner join		#complexes on #complex_avails.complex_id = #complexes.complex_id

return 0
GO
