/****** Object:  StoredProcedure [dbo].[p_close_attendance_weekend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_close_attendance_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_close_attendance_weekend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc [dbo].[p_close_attendance_weekend] 	@screening_date			datetime,
												@employee_id			int

as

declare		@error								int,
			@attendance_contributors			int,
			@attendance_processed				int,
			@attendance_status					char(1),
			@regional_indicator					char(1),
			@country_code						char(1),
			@average							numeric(18,6),
			@programmed_average					numeric(18,6),
			@movie_id							int,
			@campaign_no						int,
			@complex_id							int,
			@attendance							int,
			@records							int,
			@cinelight_id						int,
			@showings							int,
			@package_id							int,
			@cinelight_count					int,
			@player_name						varchar(40),
			@days								int,
			@premium_movie_count				numeric(18,6),
			@normal_movie_count					numeric(18,6),			
			@premium_movie_avg					numeric(18,6),
			@normal_movie_avg					numeric(18,6),
			@closing_date						datetime,
			@opening_date						datetime,
			@movie_country_count				int,
			@estimate_country_count				int


set nocount on

/*
 * Obtain info from screening_dates table
 */

select			@attendance_contributors = weekend_attendance_contributors,
				@attendance_processed = weekend_attendance_processed,
				@attendance_status = weekend_attendance_status
from 			film_screening_dates 
where			screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Load Weekend Attendance Screening Date information. Close denied.', 16, 1)
	return -1
end

if @attendance_status != 'P'
begin
	raiserror ('Error: Weekend Attendance Status for screening week being closed is not "In Progess".  Close denied.', 16, 1)
	return -1
end

if @attendance_contributors != @attendance_processed
begin
	raiserror ('Error: All required weekend attendance files have not been imported.  Close denied.', 16, 1)
	return -1
end

select			@closing_date = @screening_date,
				@opening_date = dateadd(wk, 1, @screening_date)

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete existing attendance averages
 */

delete 	attendance_screening_date_averages_weekend
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete weekend_attendance_screening_date_averages_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete 	attendance_movie_averages_weekend
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete weekend_attendance_movie_averages_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Proceed with Average Calculation
 */

 declare 		regional_cursor cursor forward_only static for
 select 		regional_indicator,
 					country_code
 from			complex_region_class,
 					country
 group by 	country_code,
 					regional_indicator
 order by 	country_code,
 					regional_indicator
 for				read only
 
 
 open regional_cursor
 fetch regional_cursor into @regional_indicator, @country_code
 while(@@fetch_status=0)
 begin

	declare 		movie_csr cursor forward_only static for
	select			distinct movie_id
	from 			attendance_raw_weekend,
						complex,
						branch,
						complex_region_class			
	where 			screening_date = @screening_date
	and 				complex.branch_code = branch.branch_code
	and				branch.country_code = @country_code
	and				attendance_raw_weekend.complex_id = complex.complex_id	
	and				attendance_raw_weekend.movie_id is not null
	and				complex.complex_region_class = complex_region_class.complex_region_class
	and				complex_region_class.regional_indicator = @regional_indicator
	group by 	movie_id
	order by 	movie_id
	for 		read only


	open movie_csr
	fetch movie_csr into @movie_id
	while(@@fetch_status=0)
	begin

		if @country_code = 'Z'
		begin
			select 		@average = avg(attendance / (case no_movies when 0 then 1 else no_movies end))
			from 		attendance_raw_weekend,
							complex,
							branch			
			where 		screening_date = @screening_date
			and 			complex.branch_code = branch.branch_code
			and			branch.country_code = @country_code
			and			attendance_raw_weekend.complex_id = complex.complex_id
			and 			movie_id = @movie_id
		
			select @error = @@error
			if @error != 0
			begin
				raiserror ('Error: Could Not Get Attendance Movie Average information. Close denied.', 16, 1)
				rollback transaction
				return -1
			end
		
			select 		@programmed_average = avg(attendance)
			from		movie_history_weekend,
							complex,
							branch					
			where 		screening_date = @screening_date
			and 			complex.branch_code = branch.branch_code
			and			branch.country_code = @country_code
			and			movie_history_weekend.complex_id = complex.complex_id
			and 			attendance_type = 'A'
			and 			movie_id = @movie_id
			and			advertising_open = 'Y'
			
			select @error = @@error
			if @error != 0
			begin
				raiserror ('Error: Could Not Get Attendance Movie Programmed Average information. Close denied.', 16, 1)
				rollback transaction
				return -1
			end
		end
		else
		begin
			select 		@average = avg(attendance / (case no_movies when 0 then 1 else no_movies end))
			from 		attendance_raw_weekend,
							complex,
							branch,
							complex_region_class
			where 		screening_date = @screening_date
			and			complex.complex_region_class = complex_region_class.complex_region_class
			and			complex_region_class.regional_indicator = @regional_indicator
			and 			complex.branch_code = branch.branch_code
			and			branch.country_code = @country_code
			and			attendance_raw_weekend.complex_id = complex.complex_id	
			and 			movie_id = @movie_id
		
			select @error = @@error
			if @error != 0
			begin
				raiserror ('Error: Could Not Get Attendance Movie Average information. Close denied.', 16, 1)
				rollback transaction
				return -1
			end
		
			select 		@programmed_average = avg(attendance)
			from		movie_history_weekend,
							complex,
							branch,
							complex_region_class
			where 		screening_date = @screening_date
			and			complex.complex_region_class = complex_region_class.complex_region_class
			and			complex_region_class.regional_indicator = @regional_indicator
			and 			complex.branch_code = branch.branch_code
			and			branch.country_code = @country_code
			and			movie_history_weekend.complex_id = complex.complex_id
			and 			attendance_type = 'A'
			and 			movie_id = @movie_id
			and			advertising_open = 'Y'
		
			select @error = @@error
			if @error != 0
			begin
				raiserror ('Error: Could Not Get Attendance Movie Programmed Average information. Close denied.', 16, 1)
				rollback transaction
				return -1
			end
		end

		if @average > 0 or @programmed_average > 0
		begin
			insert into attendance_movie_averages_weekend
			values 		(@screening_date,
							@country_code,
							@movie_id,
							@regional_indicator, 
							isnull(@average,0),
							isnull(@programmed_average,0))
		end

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Insert Attendance Movie Averages information. Close denied.', 16, 1)
			rollback transaction
			return -1
		end

		fetch movie_csr into @movie_id
	end
	
	deallocate movie_csr

	if @country_code = 'Z'
	begin
		select 		@average = avg(attendance / (case no_movies when 0 then 1 else no_movies end))
		from 		attendance_raw_weekend,
						complex,
						branch			
		where 		screening_date = @screening_date
		and 			complex.branch_code = branch.branch_code
		and			branch.country_code = @country_code
		and			attendance_raw_weekend.complex_id = complex.complex_id	
	
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Get Attendance Screening Date Average information. Close denied.', 16, 1)
			rollback transaction
			return -1
		end

		select 		@programmed_average = avg(attendance)
		from		movie_history_weekend,
						complex,
						branch					
		where 		screening_date = @screening_date
		and 			complex.branch_code = branch.branch_code
		and			branch.country_code = @country_code
		and			movie_history_weekend.complex_id = complex.complex_id
		and 			attendance_type = 'A'
		and			movie_id in (	select 			top 20 movie_id
								 				from 			attendance_movie_averages_weekend 
								 				where 			regional_indicator = @regional_indicator 
												and 				country_code = @country_code 
												and 				screening_date = @screening_date 
												order by 	average_programmed desc)
		
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Get Attendance Screening Date Programmed Average information. Close denied.', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select 		@average = avg(attendance / (case no_movies when 0 then 1 else no_movies end))
		from 		attendance_raw_weekend,
						complex,
						branch,
						complex_region_class			
		where 		screening_date = @screening_date
		and 			complex.complex_region_class = complex_region_class.complex_region_class
		and			complex_region_class.regional_indicator = @regional_indicator
		and 			complex.branch_code = branch.branch_code
		and			branch.country_code = @country_code
		and			attendance_raw_weekend.complex_id = complex.complex_id	
	
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Get Attendance Screening Date Average information. Close denied.', 16, 1)
			rollback transaction
			return -1
		end

		select 		@programmed_average = avg(attendance)
		from		movie_history_weekend,
						complex,
						branch,
						complex_region_class
		where 		screening_date = @screening_date
		and 			complex.complex_region_class = complex_region_class.complex_region_class
		and			complex_region_class.regional_indicator = @regional_indicator
		and 			complex.branch_code = branch.branch_code
		and			branch.country_code = @country_code
		and			movie_history_weekend.complex_id = complex.complex_id
		and 			attendance_type = 'A'
		and			movie_id in (	select 			top 20 movie_id
								 				from 			attendance_movie_averages_weekend 
								 				where 			country_code = @country_code 
												and 				screening_date = @screening_date 
												and				regional_indicator = @regional_indicator
												order by 	average_programmed desc)
		
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Get Attendance Screening Date Programmed Average information. Close denied.', 16, 1)
			rollback transaction
			return -1
		end

	end	

	insert into	attendance_screening_date_averages_weekend
	select 		@screening_date,
					@country_code,
					complex_id,
					@regional_indicator, 
					isnull(@average,0),
					isnull(@programmed_average,0)
	from		complex,
					branch,
					complex_region_class
	where		(film_complex_status != 'C'
	or				closing_date >= @screening_date)
	and			complex.complex_region_class = complex_region_class.complex_region_class
	and			complex_region_class.regional_indicator = @regional_indicator
	and 			complex.branch_code = branch.branch_code
	and			branch.country_code = @country_code

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Fred Could Not Insert Attendance Screening Date Averages information. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	fetch regional_cursor into @regional_indicator, @country_code
end


--print 1

/*
 * Update Movie History Weekend with appropriate averages where actual information is not already stored.
 */

update 		movie_history_weekend
set				attendance = 0,
					attendance_type = null
where 			(attendance_type != 'A'
or					attendance_type is null)
and 				screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History Weekend information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 2

--update Australia movie averages
update 		movie_history_weekend
set				attendance = average_programmed * complex_date.cinatt_weighting,
					attendance_type = 'M'
from			attendance_movie_averages_weekend,
					complex,
					complex_date,
					complex_region_class
where			movie_history_weekend.movie_id = attendance_movie_averages_weekend.movie_id
and 				movie_history_weekend.screening_date = attendance_movie_averages_weekend.screening_date
and				movie_history_weekend.screening_date = @screening_date
and				(movie_history_weekend.attendance_type != 'A'
or					movie_history_weekend.attendance_type is null)
and				movie_history_weekend.complex_id = complex.complex_id
and				complex.complex_region_class = complex_region_class.complex_region_class
and				complex_region_class.regional_indicator = attendance_movie_averages_weekend.regional_indicator
and				movie_history_weekend.complex_id = complex_date.complex_id
and				complex_date.screening_date = movie_history_weekend.screening_date
and				complex_date.complex_id = complex.complex_id
and				attendance_movie_averages_weekend.country_code = 'A'
and				complex.branch_code != 'Z'
and				average_programmed > 0

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 3

-- update New Zealand movie averages
update 		movie_history_weekend
set				attendance = average_programmed * complex_date.cinatt_weighting,
					attendance_type = 'M'
from			attendance_movie_averages_weekend,
					complex,
					complex_date
where			movie_history_weekend.movie_id = attendance_movie_averages_weekend.movie_id
and 				movie_history_weekend.screening_date = attendance_movie_averages_weekend.screening_date
and				movie_history_weekend.screening_date = @screening_date
and				(movie_history_weekend.attendance_type != 'A'
or					movie_history_weekend.attendance_type is null)
and				movie_history_weekend.complex_id = complex.complex_id
and				movie_history_weekend.complex_id = complex_date.complex_id
and				complex_date.complex_id = complex.complex_id
and				attendance_movie_averages_weekend.country_code = 'Z'
and				complex.branch_code = 'Z'
and				average_programmed > 0
and				complex_date.screening_date = movie_history_weekend.screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History Weekend information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 4

-- update Australia regional averages
update 		movie_history_weekend
set				attendance = average_programmed * complex_date.cinatt_weighting,
					attendance_type = 'R'
from			attendance_screening_date_averages_weekend,
					complex,
					complex_date,
					complex_region_class
where			movie_history_weekend.movie_id not in (	select 			movie_id 
																							from  			attendance_movie_averages_weekend 
																							where 			screening_date = @screening_date
																							and				regional_indicator = complex_region_class.regional_indicator
																							and 				country_code = 'A'
																							and 				average_programmed > 0)
and 				movie_history_weekend.screening_date = attendance_screening_date_averages_weekend.screening_date
and				movie_history_weekend.screening_date = @screening_date
and				(movie_history_weekend.attendance_type != 'A'
or					movie_history_weekend.attendance_type is null)
and				movie_history_weekend.complex_id = complex.complex_id
and				complex.complex_region_class = complex_region_class.complex_region_class
and				complex_region_class.regional_indicator = attendance_screening_date_averages_weekend.regional_indicator
and				movie_history_weekend.complex_id = complex_date.complex_id
and				complex_date.complex_id = complex.complex_id
and				attendance_screening_date_averages_weekend.country_code = 'A'
and				complex.branch_code != 'Z'
and				complex_date.screening_date = movie_history_weekend.screening_date
and				complex_date.screening_date = attendance_screening_date_averages_weekend.screening_date
and				attendance_screening_date_averages_weekend.complex_id = complex.complex_id
and				attendance_screening_date_averages_weekend.complex_id = movie_history_weekend.complex_id
and				attendance_screening_date_averages_weekend.complex_id = complex_date.complex_id

--print 5

-- update New Zealand regional averages
update	 	movie_history_weekend
set				attendance = average_programmed * complex_date.cinatt_weighting,
					attendance_type = 'R'
from			attendance_screening_date_averages_weekend,
					complex,
					complex_date
where			movie_history_weekend.movie_id not in (	select 			movie_id 
																							from  			attendance_movie_averages_weekend 
																							where 			screening_date = @screening_date
																							and 				country_code = 'Z'
																							and 				average_programmed > 0)
and 				movie_history_weekend.screening_date = attendance_screening_date_averages_weekend.screening_date
and				movie_history_weekend.screening_date = @screening_date
and				(movie_history_weekend.attendance_type != 'A'
or					movie_history_weekend.attendance_type is null)
and				movie_history_weekend.complex_id = complex.complex_id
and				movie_history_weekend.complex_id = complex_date.complex_id
and				complex_date.complex_id = complex.complex_id
and				attendance_screening_date_averages_weekend.country_code = 'Z'
and				complex.branch_code = 'Z'
and				complex_date.screening_date = movie_history_weekend.screening_date
and				complex_date.screening_date = attendance_screening_date_averages_weekend.screening_date
and				attendance_screening_date_averages_weekend.complex_id = complex.complex_id
and				attendance_screening_date_averages_weekend.complex_id = movie_history_weekend.complex_id
and				attendance_screening_date_averages_weekend.complex_id = complex_date.complex_id	

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History Weekend information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 6

/*
 * Split Premium Cinema Attendances
 */
 
declare		premium_csr cursor for
select			complex_id,
					movie_id
from			movie_history_weekend
where			screening_date = @screening_date
and				premium_cinema = 'Y'
group by		complex_id,
					movie_id			 
having			sum(isnull(attendance,0)) <> 0

open premium_csr
fetch premium_csr into @complex_id, @movie_id
while(@@fetch_status = 0)
begin
	select		@attendance = sum(attendance)
	from		movie_history_weekend
	where		complex_id = @complex_id
	and			screening_date = @screening_date
	and			movie_id = @movie_id
	
	select		@premium_movie_count = count(*)
	from		movie_history_weekend
	where		complex_id = @complex_id
	and			screening_date = @screening_date
	and			movie_id = @movie_id
	and			premium_cinema = 'Y'
	
	select		@normal_movie_count = count(*)
	from		movie_history_weekend
	where		complex_id = @complex_id
	and			screening_date = @screening_date
	and			movie_id = @movie_id
	and			premium_cinema != 'Y'

	select		@normal_movie_count = @normal_movie_count + (@premium_movie_count * 0.21)--0.325
	
	select		@normal_movie_avg = (@attendance / @normal_movie_count) 

	select		@premium_movie_avg = @normal_movie_avg * 0.21
	
	select		@normal_movie_avg = @normal_movie_avg + 1.0

	select		@premium_movie_avg = @premium_movie_avg + 1.0

	update	movie_history_weekend
	set			attendance = @premium_movie_avg
	where		complex_id = @complex_id
	and			screening_date = @screening_date
	and			movie_id = @movie_id
	and			premium_cinema = 'Y'	

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Update Premium Premium Average. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	update	movie_history_weekend
	set			attendance = @normal_movie_avg
	where		complex_id = @complex_id
	and			screening_date = @screening_date
	and			movie_id = @movie_id
	and			premium_cinema != 'Y'	

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Update Premium Normal Average. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	fetch premium_csr into @complex_id, @movie_id
end

--print 7

/*
 * Delete Existing Actuals For Campaigns
 */

delete		attendance_campaign_actuals_weekend
where		screening_date = @screening_date


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete attendance_campaign_actuals_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end
 

--print 8

delete		attendance_campaign_complex_actuals_weekend
where		screening_date = @screening_date


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete attendance_campaign_complex_actuals_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 9

/*
 * Generate Actuals For Campaigns
 */

insert into	attendance_campaign_actuals_weekend
select 			film_campaign.campaign_no,
					@screening_date,
					@employee_id,
					getdate(),
					sum(isnull(attendance,0)),
					'Y'			
from			film_campaign,
					movie_history_weekend,
					v_certificate_item_distinct,
					campaign_spot
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
and				attendance is not null
and				attendance > 0 
and				campaign_spot.screening_date = @screening_date
and				movie_history_weekend.screening_date = @screening_date
group by 	film_campaign.campaign_no

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Campaign Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 10

declare 		act_csr cursor forward_only static for
select 			film_campaign.campaign_no,
					sum(isnull(average_programmed,0))
from			film_campaign,
					v_certificate_item_distinct,
					certificate_group,
					campaign_spot,
					attendance_screening_date_averages_weekend
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = certificate_group.certificate_group_id
and				campaign_spot.screening_date = @screening_date
and				certificate_group.screening_date = @screening_date
and				certificate_group.is_movie = 'N'
and				certificate_group.complex_id = attendance_screening_date_averages_weekend.complex_id
and				certificate_group.screening_date = attendance_screening_date_averages_weekend.screening_date
and				campaign_spot.screening_date = attendance_screening_date_averages_weekend.screening_date
and				campaign_spot.screening_date = certificate_group.screening_date
group by 	film_campaign.campaign_no
order by 	film_campaign.campaign_no

open act_csr
fetch act_csr into @campaign_no, @attendance
while(@@fetch_status=0)
begin
	
	select 	@records = count(campaign_no)
	from	attendance_campaign_actuals_weekend
	where	campaign_no = @campaign_no
	and		screening_date = @screening_date

	if @records > 0
	begin
		update 	attendance_campaign_actuals_weekend
		set			attendance = attendance + @attendance
		where		campaign_no = @campaign_no
		and			screening_date = @screening_date
		
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Generate Campaign Complex Actuals. Close denied.', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		insert into attendance_campaign_actuals_weekend values (@campaign_no, @screening_date, @employee_id, getdate(), @attendance, 'Y')

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Generate Campaign Complex Actuals. Close denied.', 16, 1)
			rollback transaction
			return -1
		end
	end
	fetch act_csr into @campaign_no, @attendance
end

deallocate act_csr

--print 11

insert into	attendance_campaign_complex_actuals_weekend
select 			film_campaign.campaign_no,
					@screening_date,
					movie_history_weekend.complex_id,
					movie_history_weekend.movie_id,
					sum(isnull(attendance,0)),
					'Y'			
from			film_campaign,
					movie_history_weekend,
					v_certificate_item_distinct,
					campaign_spot
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
and				attendance is not null
and				attendance > 0 
and				campaign_spot.screening_date = @screening_date
and				movie_history_weekend.screening_date = @screening_date
group by 	film_campaign.campaign_no,
					movie_history_weekend.complex_id,
					movie_history_weekend.movie_id
			
select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Campaign Complex Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 12

declare 		act_cplx_csr cursor forward_only static for
select 			film_campaign.campaign_no,
					campaign_spot.complex_id,
					sum(isnull(average_programmed,0))
from			film_campaign,
					v_certificate_item_distinct,
					certificate_group,
					campaign_spot,
					attendance_screening_date_averages_weekend
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = certificate_group.certificate_group_id
and			    campaign_spot.screening_date = @screening_date
and				certificate_group.screening_date = @screening_date
and				certificate_group.is_movie = 'N'
and				certificate_group.complex_id = attendance_screening_date_averages_weekend.complex_id
and				certificate_group.screening_date = attendance_screening_date_averages_weekend.screening_date
and				campaign_spot.screening_date = attendance_screening_date_averages_weekend.screening_date
and				campaign_spot.screening_date = certificate_group.screening_date
group by 	film_campaign.campaign_no, campaign_spot.complex_id
order by 	film_campaign.campaign_no, campaign_spot.complex_id


open act_cplx_csr
fetch act_cplx_csr into @campaign_no, @complex_id, @attendance
while(@@fetch_status=0)
begin
	
	select 			@records = count(campaign_no)
	from			attendance_campaign_complex_actuals_weekend
	where			campaign_no = @campaign_no
	and				screening_date = @screening_date
	and				movie_id = 0
	and				complex_id = @complex_id

	if @records > 0
	begin
		update 		attendance_campaign_complex_actuals_weekend
		set				attendance = attendance + @attendance
		where			campaign_no = @campaign_no
		and				screening_date = @screening_date
		and				movie_id = 0
		and				complex_id = @complex_id
		
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Generate Campaign Complex Actuals. Close denied.', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		insert into attendance_campaign_complex_actuals_weekend values (@campaign_no, @screening_date, @complex_id, 0, @attendance, 'Y')

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Generate Campaign Complex Actuals. Close denied.', 16, 1)
			rollback transaction
			return -1
		end
	end
	fetch act_cplx_csr into @campaign_no, @complex_id, @attendance
end

deallocate act_cplx_csr

--print 13

delete				attendance_campaign_tracking_weekend
where				screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not clear attendance_campaign_tracking_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end


/*
 * Summarise Tracking Data
 */

insert into		attendance_campaign_tracking_weekend
select				campaign_spot.campaign_no, 
						movie_history_weekend.screening_date, 
						campaign_spot.spot_type, 
						isnull(sum(attendance),0) as attendance,
						count(distinct spot_id)
from 				movie_history_weekend,
						v_certificate_item_distinct,
						campaign_spot
where				movie_history_weekend.certificate_group = v_certificate_item_distinct.certificate_group
and					v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
and					movie_history_weekend.screening_date = @screening_date
and					campaign_spot.screening_date = movie_history_weekend.screening_date
group by			campaign_spot.campaign_no, 
						movie_history_weekend.screening_date, 
						campaign_spot.spot_type

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not enter attendance_campaign_tracking_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end

declare			estimate_movie_csr cursor for
select			distinct movie_id
from			movie_history
where			screening_date = @closing_date
and				movie_id <> 102
and				movie_id not in (select			movie_id		
								from			cinetam_movie_complex_estimates
								where			screening_date = @opening_date)
for				read only

open estimate_movie_csr
fetch estimate_movie_csr into @movie_id 
while(@@fetch_status = 0)
begin

	select			@movie_country_count = 0

	select			@movie_country_count = count(movie_id)
	from			movie_history
	where			movie_id = @movie_id
	and				screening_date = @closing_date
	and				country = 'A'

	if @movie_country_count > 0 
	begin
		insert into		cinetam_movie_complex_estimates
		select			movie_id,
						cinetam_reporting_demographics_id,
						screening_dates.screening_date,
						cinetam_movie_complex_estimates.complex_id,
						round(attendance * power(0.900000000, DATEDIFF(WK, cinetam_movie_complex_estimates.screening_date, screening_dates.screening_date)),0),
						round(original_estimate * power(0.900000000, DATEDIFF(WK, cinetam_movie_complex_estimates.screening_date, screening_dates.screening_date)),0)
		from			cinetam_movie_complex_estimates,
						complex,
						branch,
						(select			screening_date
						from			film_screening_dates
						where			screening_date between @opening_date and DATEADD(wk, 4, @opening_date)) as screening_dates
		where			cinetam_movie_complex_estimates.complex_id = complex.complex_id
		and				complex.branch_code = branch.branch_code
		and				cinetam_movie_complex_estimates.movie_id = @movie_id
		and				cinetam_movie_complex_estimates.screening_date = @closing_date
		and				country_code = 'A'

		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('There was an error adding extra movie estimates for still screening AUS movies.', 16, 1)
			return -100
		end 
	end

	select			@movie_country_count = count(movie_id)
	from			movie_history
	where			movie_id = @movie_id
	and				screening_date = @closing_date
	and				country = 'Z'

	if @movie_country_count > 0 
	begin
		insert into		cinetam_movie_complex_estimates
		select			movie_id,
						cinetam_reporting_demographics_id,
						screening_dates.screening_date,
						cinetam_movie_complex_estimates.complex_id,
						round(attendance * power(0.900000000, DATEDIFF(WK, cinetam_movie_complex_estimates.screening_date, screening_dates.screening_date)),0),
						round(original_estimate * power(0.900000000, DATEDIFF(WK, cinetam_movie_complex_estimates.screening_date, screening_dates.screening_date)),0)
		from			cinetam_movie_complex_estimates,
						complex,
						branch,
						(select			screening_date
						from			film_screening_dates
						where			screening_date between @opening_date and DATEADD(wk, 4, @opening_date)) as screening_dates
		where			cinetam_movie_complex_estimates.complex_id = complex.complex_id
		and				complex.branch_code = branch.branch_code
		and				cinetam_movie_complex_estimates.movie_id = @movie_id
		and				cinetam_movie_complex_estimates.screening_date = @closing_date
		and				country_code = 'Z'

		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('There was an error adding extra movie estimates for still screening NZ movies.', 16, 1)
			return -100
		end 
	end
	select			@movie_country_count = 0


	fetch estimate_movie_csr into @movie_id 
end


--print 20

update		movie_history_weekend 
set				attendance = 0 
where			movie_id = 102

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not remove attendance . Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 21

/*
 * Close Transaction & Return
 */

commit transaction

return 0
GO
