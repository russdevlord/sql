/****** Object:  StoredProcedure [dbo].[p_cinetam_add_extra_movie_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_add_extra_movie_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_add_extra_movie_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc		[dbo].[p_cinetam_add_extra_movie_estimates]		@movie_id			int,
														@country_code		char(1),
														@no_extra_weeks		int
as

declare			@error					int,
				@max_screening_date		datetime

select			@max_screening_date = max(screening_date)
from			cinetam_movie_complex_estimates cmce
inner join		complex cplx on cmce.complex_id = cplx.complex_id
inner join		branch br on cplx.branch_code = br.branch_code
where			movie_id = @movie_id
and				country_code = @country_code

print @max_screening_date

/*
 * Begin Transaction
 */

begin transaction

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
				where			screening_date between DATEADD(wk, 1, @max_screening_date) and DATEADD(wk, @no_extra_weeks, @max_screening_date)) as screening_dates
where			cinetam_movie_complex_estimates.complex_id = complex.complex_id
and				complex.branch_code = branch.branch_code
and				cinetam_movie_complex_estimates.movie_id = @movie_id
and				cinetam_movie_complex_estimates.screening_date = @max_screening_date
and				country_code = @country_code

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting extra estimates', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
