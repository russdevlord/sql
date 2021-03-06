/****** Object:  StoredProcedure [dbo].[p_attendance_reverse_movie_exclusion]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_reverse_movie_exclusion]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_reverse_movie_exclusion]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_attendance_reverse_movie_exclusion]    @data_provider_id		int,
													@movie_code			varchar(30)

as

declare		@error				int,
			@complex_code		varchar(30),
			@movie_id			int,
			@occurence			int,
			@complex_id			int,
			@screening_date		datetime,
			@rowcount			int,
			@complex_name		varchar(60),
			@attendance			int,
			@movie_count		int

set nocount on

begin transaction

select 		@movie_id = movie_id
from 		data_translate_movie
where		movie_code = @movie_code
and			data_provider_id = @data_provider_id

select @error = @@rowcount
if @error != 1 
begin
	raiserror ('Movie has not been matched to a CinVendo Movie', 16, 1)
	goto error
end

declare 	screening_date_csr cursor static forward_only for
select		distinct screening_date
from		attendance_source
where		movie_code = @movie_code
and			data_provider_id = @data_provider_id
group by 	screening_date
order by 	screening_date
for			read only

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin

	declare 	complex_csr cursor static forward_only for
	select 		complex_code,
				complex_name,
				attendance
	from		attendance_source
	where		movie_code = @movie_code
	and			data_provider_id = @data_provider_id
	and			screening_date = @screening_date
	group by 	complex_code,
				complex_name,
				attendance
	order by 	complex_code
	for 		read only

	open complex_csr
	fetch complex_csr into @complex_code, @complex_name, @attendance
	while(@@fetch_status = 0)
	begin

		select 		@complex_id = complex_id
		from 		data_translate_complex
		where		complex_code = @complex_code
		and			data_provider_id = @data_provider_id
		
		select @error = @@rowcount
		if @error != 1 
		begin
			raiserror ('Complex has not been matched to a CinVendo Complex', 16, 1)
			goto error
		end

		update 	attendance_source
		set 	include = 'Y'
		where	complex_code = @complex_code
		and		movie_code = @movie_code
		and		data_provider_id = @data_provider_id
		and		screening_date = @screening_date
	
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Could not update include flag on attendance source', 16, 1)
			goto error
		end

		select 	@occurence = count(movie_id)
		from	movie_history
		where	screening_date = @screening_date
		and		complex_id = @complex_id
		and		movie_id = @movie_id

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Could not get occurence of movie prints', 16, 1)
			goto error
		end
		
		if @occurence != 0
		begin
			select @attendance = @attendance / @occurence

			update 	movie_history
			set 	attendance = @attendance,
					attendance_type = 'A'
			where	screening_date = @screening_date
			and		complex_id = @complex_id
			and		movie_id = @movie_id

			select @error = @@error
			if @error != 0
			begin
				raiserror ('Failed to update movie history table', 16, 1)
				goto error
			end
		end

		select 	@movie_count = count(movie_code)
		from	attendance_raw
		where	complex_id = @complex_id
		and		movie_code = @movie_code
		and		screening_date = @screening_date

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Could not check existence of translated data', 16, 1)
			goto error
		end

		if @movie_count = 0
		begin
			insert into attendance_raw
			(
			data_provider_id,
			screening_date,
			complex_id,
			movie_id,
			movie_code,
			movie_name,
			attendance,
			no_movies,
			processed_date,
			employee_id
			) select	data_provider_id,
						screening_date,
						@complex_id,
						@movie_id,
						movie_code,
						movie_name,
						@attendance,
						@occurence,
						process_date,
						employee_id
			from 		attendance_source
			where		complex_code = @complex_code
			and			movie_code = @movie_code
			and			data_provider_id = @data_provider_id
			and			screening_date = @screening_date
			group by 	data_provider_id,
						screening_date,
						movie_code,
						movie_name,
						process_date,
						employee_id

			select @error = @@error
			if @error != 0
			begin
				raiserror ('Failed to insert attendance raw row', 16, 1)
				goto error
			end
		end
		else
		begin
			update 	attendance_raw
			set 	no_movies = @occurence,
					attendance = @attendance,
					movie_id = @movie_id
			where	complex_id = @complex_id
			and		movie_code = @movie_code
			and		data_provider_id = @data_provider_id
			and		screening_date = @screening_date

		end

		fetch complex_csr into @complex_code, @complex_name, @attendance
	end

	deallocate complex_csr	

	update 	film_screening_dates
	set		attendance_status = 'P'
	where	screening_date = @screening_date

	select 	@error = @@error
	if @error != 0
	begin
		raiserror ('Failed to update attendance averages and actuals', 16, 1)
		goto error
	end

	exec @error = p_close_attendance_screening_date @screening_date, 193

	if @error != 0
	begin
		raiserror ('Failed to update attendance averages and actuals', 16, 1)
		goto error
	end

	fetch screening_date_csr into @screening_date
end


commit transaction
return 0

error:
	rollback transaction
	return -1
GO
