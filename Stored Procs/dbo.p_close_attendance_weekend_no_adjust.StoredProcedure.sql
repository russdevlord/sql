/****** Object:  StoredProcedure [dbo].[p_close_attendance_weekend_no_adjust]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_close_attendance_weekend_no_adjust]
GO
/****** Object:  StoredProcedure [dbo].[p_close_attendance_weekend_no_adjust]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_close_attendance_weekend_no_adjust]		@screening_date			datetime

as

declare			@error								int,
				@movie_id							int,
				@country_code						char(1),
				@movie_country_count				int,
				@estimate_country_count				int,
				@closing_date						datetime,
				@opening_date						datetime

set nocount on

begin transaction

select			@closing_date = @screening_date,
				@opening_date = dateadd(wk, 1, @screening_date)

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


update			film_screening_dates
set				weekend_attendance_status = 'X'
where			screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error updating screening_date', 16, 1)
	return -1
end

commit transaction
return 0
GO
