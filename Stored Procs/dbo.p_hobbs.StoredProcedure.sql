/****** Object:  StoredProcedure [dbo].[p_hobbs]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_hobbs]
GO
/****** Object:  StoredProcedure [dbo].[p_hobbs]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_hobbs]		@screening_date			datetime

as

set nocount on

declare		@error											int,
			@complex_id										int, 
			@movie_id										int, 
			@cinetam_reporting_demographics_id				int, 
			@inclusion_id									int,
			@attendance										numeric(18,10),
			@full_weekend_attendance						numeric(18,10),
			@target_attendance								numeric(18,10),
			@next_week_attendance							numeric(18,10),
			@attendance_difference							numeric(18,10)

begin transaction

/*
 * Movie Estimates
 */

declare			movie_estimate_csr cursor for
select			cinetam_movie_complex_estimates.complex_id, 
				cinetam_movie_complex_estimates.movie_id,
				cinetam_reporting_demographics_id, 
				cinetam_movie_complex_estimates.attendance as attendance
from			cinetam_movie_complex_estimates,
				movie_history
where			cinetam_movie_complex_estimates.movie_id = movie_history.movie_id
and				cinetam_movie_complex_estimates.complex_id = movie_history.complex_id
and				cinetam_movie_complex_estimates.screening_date = movie_history.screening_date
and				cinetam_movie_complex_estimates.screening_date = @screening_date
--and				premium_cinema != 'Y'
and				cinetam_movie_complex_estimates.movie_id in (12092,
12526,
12090,
12788,
11676,
12735,
12086,
2630,
12089,
12669,
12596,
12597,
12683,
12716,
12076,
12085,
12253,
12719,
12726,
12293
) 
and				isnull(cinetam_movie_complex_estimates.attendance,0) <> 0
group by		cinetam_movie_complex_estimates.complex_id, 
				cinetam_movie_complex_estimates.movie_id,
				cinetam_reporting_demographics_id,
				cinetam_movie_complex_estimates.attendance
for				read only

open movie_estimate_csr 
fetch movie_estimate_csr into @complex_id, @movie_id, @cinetam_reporting_demographics_id, @attendance
while(@@FETCH_STATUS=0)
begin

	select @full_weekend_attendance = 0

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@full_weekend_attendance = sum(full_attendance)
		from			movie_history_weekend
		where			complex_id = @complex_id
		and				movie_id = @movie_id
		and				screening_date = @screening_date
		/*and				certificate_group not in (	select			certificate_group 
													from			movie_history 
													where			complex_id = @complex_id 
													and				screening_date = @screening_date 
													and				premium_cinema = 'Y')*/

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend for movie estimates', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@full_weekend_attendance = sum(full_attendance)
		from			cinetam_movie_history_weekend
		where			complex_id = @complex_id
		and				movie_id = @movie_id
		and				screening_date = @screening_date
		and				cinetam_demographics_id in (	select			cinetam_demographics_id 
														from			cinetam_reporting_demographics_xref 
														where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 
		/*and				certificate_group_id not in (	select			certificate_group 
														from			movie_history 
														where			complex_id = @complex_id 
														and				screening_date = @screening_date 
														and				premium_cinema = 'Y')*/

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend for movie estimates', 16, 1)
			rollback transaction
			return -1
		end
	end

	if @attendance > 0 and @full_weekend_attendance > 0
	begin
		update			cinetam_movie_complex_estimates
		set				attendance = convert(int, attendance *  (@full_weekend_attendance / @attendance))
		where			screening_date > @screening_date
		and				complex_id = @complex_id
		and				movie_id = @movie_id
		and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating cinetam_movie_complex_estimates', 16, 1)
			rollback transaction
			return -1
		end

	end

	fetch movie_estimate_csr into @complex_id, @movie_id, @cinetam_reporting_demographics_id, @attendance
end

commit transaction
return 0
GO
