/****** Object:  StoredProcedure [dbo].[p_follow_film_generate_goodwill_targets]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_follow_film_generate_goodwill_targets]
GO
/****** Object:  StoredProcedure [dbo].[p_follow_film_generate_goodwill_targets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_follow_film_generate_goodwill_targets]			@inclusion_id				int,
																											@screening_date			datetime,
																											@no_weeks					int,
																											@attendance_total		int,
																											@movie_id					int,
																											@mode							int
as	

declare				@error															int,
						@start_date												datetime,
						@end_date													datetime,
						@row_counter												int,
						@attendance												numeric(30,20),
						@cinetam_reporting_demographics_id		int,
						@spot_count												int,
						@total_market												numeric(30,20),
						@attendance_diff										numeric(30,20),
						@attendance_rolling									numeric(30,20),
						@movie_attendance										numeric(30,20),
						@movie_total_attendance							numeric(30,20),
						@master_weekly_records							int
					
set nocount on					

create table #movie_attendance
(
movie_id			int					null,
screening_date		datetime			null,
attendance			numeric(30,20)		null
)

select			@start_date	= @screening_date	

select			@end_date = dateadd(wk, @no_weeks - 1, @start_date)

select			@no_weeks = 1 + datediff(wk, @start_date, @end_date)

insert into	#movie_attendance
select			movie_screening_instructions.movie_id,
					cinetam_movie_complex_estimates.screening_date,
					sum(attendance)
from				inclusion_cinetam_package,
					movie_screening_instructions,
					inclusion_cinetam_settings,
					cinetam_movie_complex_estimates
where			inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
and				inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and				cinetam_movie_complex_estimates.complex_id = inclusion_cinetam_settings.complex_id
and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = inclusion_cinetam_settings.cinetam_reporting_demographics_id
and				cinetam_movie_complex_estimates.movie_id = movie_screening_instructions.movie_id
and				inclusion_cinetam_settings.inclusion_id = @inclusion_id 
and				movie_screening_instructions.movie_id = @movie_id
and				instruction_type = 1
group by		movie_screening_instructions.movie_id,
					cinetam_movie_complex_estimates.screening_date

begin transaction

declare			movie_csr cursor for
select			movie_id
from				inclusion_cinetam_package,
					movie_screening_instructions
where			inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
and				inclusion_id = @inclusion_id 
and				movie_id = @movie_id
and				instruction_type = 1
order by		movie_id

open movie_csr
fetch movie_csr into @movie_id
while(@@fetch_status = 0)
begin

	select			@row_counter = 0

	declare			screening_date_csr cursor for
	select			screening_date
	from				film_screening_dates
	where			screening_date between @start_date and @end_date
	order by		screening_date
	for				read only

	open screening_date_csr
	fetch screening_date_csr into @screening_date
	while(@@fetch_status = 0)
	begin

		select		@spot_count = count(spot_id)
		from			inclusion_spot
		where		inclusion_id = @inclusion_id
		and			screening_date = @screening_date
		
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error deleting counting spots for this inclusion', 16, 1)
			rollback transaction
			return -1
		end
		
		if @spot_count > 1
		begin
			raiserror ('Too many spots per week for this inclusion.', 16, 1)
			rollback transaction
			return -1
		end
		
		if @spot_count < 1
		begin
			raiserror ('Too few spots per week for this inclusion.', 16, 1)
			rollback transaction
			return -1
		end	

		select		@spot_count = count(inclusion_id)
		from			inclusion_follow_film_targets
		where		inclusion_id = @inclusion_id
		and			screening_date = @screening_date
		and			movie_id = @movie_id
		
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error counting targets for this inclusion', 16, 1)
			rollback transaction
			return -1
		end
		
		if @spot_count > 1
		begin
			raiserror ('Targets already entered for this inclusion for the week you selected.', 16, 1)
			rollback transaction
			return -1
		end

		select	@row_counter = @row_counter + 1

		select @attendance = 0
		
		select		@movie_attendance = attendance 
		from			#movie_attendance
		where		movie_id = @movie_id
		and			screening_date = @screening_date
		
		select		@movie_total_attendance = sum(attendance)
		from			#movie_attendance
		where		screening_date = @screening_date
		
		
		if @row_counter = 1
		begin
			select	@attendance_diff = 0.0000, 
					@attendance_rolling = 0.0000


			if @no_weeks = 1
				select @attendance = @attendance_total 
			if @no_weeks = 2
				select @attendance = @attendance_total * 0.6500
			if @no_weeks = 3
				select @attendance = @attendance_total * 0.5000
			if @no_weeks >= 4
				select @attendance = @attendance_total * 0.4500
		end
		
		if @row_counter = 2
		begin
			if @no_weeks = 2
				select @attendance = @attendance_total * 0.3500
			if @no_weeks = 3
				select @attendance = @attendance_total * 0.3000
			if @no_weeks >= 4
				select @attendance = @attendance_total * 0.2500
		end
		
		if @row_counter = 3
			select @attendance = @attendance_total * 0.2000

		if @row_counter = 4
			select @attendance = @attendance_total * 0.1000
			
		if @row_counter > 4
			select @attendance = 0.0000			
			
		select @attendance = @attendance * @movie_attendance / @movie_total_attendance

		select @attendance_rolling = @attendance_rolling + @attendance

		select @attendance = @attendance + @attendance_diff
			
		select			@total_market = convert(numeric(30,10) , sum(percent_market))
		from				cinetam_complex_date_settings,
							inclusion_cinetam_settings
		where			cinetam_complex_date_settings.complex_id = inclusion_cinetam_settings.complex_id
		and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
		and				cinetam_complex_date_settings.screening_date = @screening_date
		and				inclusion_cinetam_settings.inclusion_id = @inclusion_id
		
		
		select @error = @@error
		if @error <> 0 
		begin
			raiserror ('Error: Could not create follow film targets'				, 16, 1)
			rollback transaction
			return -1
		end
		
		insert into		inclusion_follow_film_targets
		select				inclusion_cinetam_settings.inclusion_id,
								inclusion_cinetam_settings.cinetam_reporting_demographics_id,
								inclusion_cinetam_settings.complex_id,
								movie_screening_instructions.movie_id,
								inclusion_spot.screening_date,
								@attendance * convert(numeric(30,10), percent_market) / @total_market,
								0,
								'N',
								0
		from					inclusion,
								inclusion_spot,
								inclusion_cinetam_settings,
								cinetam_complex_date_settings,
								inclusion_cinetam_package,
								movie_screening_instructions
		where				inclusion.inclusion_id = inclusion_spot.inclusion_id
		and					inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
		and					inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
		and					cinetam_complex_date_settings.screening_date = inclusion_spot.screening_date 
		and					cinetam_complex_date_settings.complex_id = inclusion_cinetam_settings.complex_id 
		and					inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
		and					inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
		and					movie_screening_instructions.instruction_type = 1
		and					inclusion.inclusion_id = @inclusion_id
		and					movie_screening_instructions.movie_id = @movie_id
		and					inclusion_spot.screening_date = @screening_date
		
		select @error = @@error
		if @error <> 0 
		begin
			raiserror ('Error: Could not create follow film targets'				, 16, 1)
			rollback transaction
			return -1
		end

		
		select	@attendance_diff = @attendance_rolling - sum(target_attendance)
		from	inclusion_follow_film_targets
		where	inclusion_id = @inclusion_id
		and		screening_date <= @screening_date
		and		screening_date >= @start_date
		and		movie_id = @movie_id
		
	
		insert		into inclusion_follow_film_targets
		select		inclusion_cinetam_settings.inclusion_id, 
						inclusion_cinetam_settings.cinetam_reporting_demographics_id, 
						complex_id, 
						movie_id, 
						@screening_date, 
						isnull(sale_percentage * (		select		attendance 
																	from			cinetam_movie_complex_estimates 
																	where		complex_id = inclusion_cinetam_settings.complex_id 
																	and			cinetam_reporting_demographics_id = 1 
																	and			screening_date = @screening_date 
																	and			movie_id = movie_screening_instructions.movie_id),0),
						0, 
						'N', 
						0
		from			inclusion_cinetam_settings,
						inclusion_cinetam_package,
						movie_screening_instructions,
						inclusion_cinetam_master_target
		where		inclusion_cinetam_settings.inclusion_id in (select inclusion_id from inclusion_spot where screening_date= @screening_date) 
		and			inclusion_cinetam_master_target.inclusion_id = inclusion_cinetam_settings.inclusion_id
		and			complex_id not in (select complex_id from cinetam_complex_date_settings where screening_date = @screening_date)
		and			complex_id not in (select complex_id from inclusion_follow_film_targets where screening_date = @screening_date and inclusion_id = @inclusion_id and movie_id = @movie_id)
		and			movie_id = @movie_id
		and			instruction_type = 1
		and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
		and			inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
		and			complex_id not in (1,2)
		and			inclusion_cinetam_settings.inclusion_id = @inclusion_id

		select @error = @@error
		if @error <> 0 
		begin
			raiserror ('Error: Could not create follow film targets for '				, 16, 1)
			rollback transaction
			return -1
		end		

		if @mode = 1 
		begin
			update			inclusion_follow_film_targets
			set				original_target_attendance = target_attendance
			where			inclusion_id = @inclusion_id
			and				screening_date = @screening_date
			and				movie_id = @movie_id

			select		@error = @@error
			if @error <> 0
			begin
				raiserror ('Error matching attendance total - targets', 16, 1)
				rollback transaction
				return -1
			end	
		end
		else
		begin
			update			inclusion_follow_film_targets
			set				original_target_attendance = 0
			where			inclusion_id = @inclusion_id
			and				screening_date = @screening_date
			and				movie_id = @movie_id

			select		@error = @@error
			if @error <> 0
			begin
				raiserror ('Error matching attendance total - targets', 16, 1)
				rollback transaction
				return -1
			end	
		end

		fetch screening_date_csr into @screening_date
	end	

	close screening_date_csr
	deallocate screening_date_csr

	fetch movie_csr into @movie_id
end

if @mode = 1
begin
	update			inclusion_cinetam_master_target
	set				attendance = isnull(attendance, 0) + @attendance_total
	where			inclusion_id = @inclusion_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error updateing master target', 16, 1)
		rollback transaction
		return -1
	end	

	select			@master_weekly_records = count(*) 
	from				inclusion_cinetam_weekly_master_target 
	where			inclusion_id = @inclusion_id

	if @master_weekly_records > 0 
	begin
		select			@master_weekly_records = count(*) 
		from				inclusion_cinetam_weekly_master_target 
		where			inclusion_id = @inclusion_id
		and				screening_date between @start_date	and @end_date

		if @master_weekly_records = 0 
		begin
			insert into	inclusion_cinetam_weekly_master_target
			select			inclusion_id,
								cinetam_reporting_demographics_id,
								screening_date,
								sum(target_attendance)
			from				inclusion_follow_film_targets
			where			inclusion_id = @inclusion_id
			and				screening_date between @start_date	and @end_date			
			group by		inclusion_id,
								cinetam_reporting_demographics_id,
								screening_date							 

			select		@error = @@error
			if @error <> 0
			begin
				raiserror ('Error updateing weekly master target', 16, 1)
				rollback transaction
				return -1
			end	

		end
	end

end

commit transaction
return 0
GO
