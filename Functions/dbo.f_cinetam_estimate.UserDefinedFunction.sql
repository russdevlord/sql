/****** Object:  UserDefinedFunction [dbo].[f_cinetam_estimate]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cinetam_estimate]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cinetam_estimate]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[f_cinetam_estimate] (@movie_id							int,
										@complex_id							int,
										@screening_date						datetime,
										@cinetam_reporting_demographics_id	int,
										@premium_cinema						char(1))
returns int
as
begin
	declare			@attendance				int,
					@premium_movies			int,
					@normal_movies			int

	select			@attendance = attendance
	from			cinetam_movie_complex_estimates
	where			movie_id = @movie_id
	and				complex_id = @complex_id
	and				screening_date = @screening_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select			@premium_movies = count(*)
	from			movie_history
	where			movie_id = @movie_id
	and				complex_id = @complex_id
	and				screening_date = @screening_date
	and				premium_cinema = 'Y'

	select			@normal_movies = count(*)
	from			movie_history
	where			movie_id = @movie_id
	and				complex_id = @complex_id
	and				screening_date = @screening_date
	and				premium_cinema = 'N'

	if @normal_movies > 0 and @premium_movies = 0
	begin
		if @premium_cinema = 'Y'
			select			@attendance = -1
		else
			select			@attendance = @attendance / @normal_movies
	end
	else if @normal_movies > 0 and @premium_movies > 0
	begin
		if @premium_cinema = 'Y'
			select			@attendance = (@attendance * 0.15) / @premium_movies
		else
			select			@attendance = (@attendance * 0.85) / @normal_movies
	end
	else if @normal_movies > 0 and @premium_movies = 0
	begin
		if @premium_cinema = 'Y'
			 select			@attendance = (@attendance * 0.15) / @premium_movies
		else
			select			@attendance = -1
	end


	return(isnull(@attendance,0))
end
GO
