/****** Object:  UserDefinedFunction [dbo].[f_movie_attrelweek]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_movie_attrelweek]
GO
/****** Object:  UserDefinedFunction [dbo].[f_movie_attrelweek]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_movie_attrelweek] (@movie_id int, @week_num int, @country_code char(1))
RETURNS int
AS
BEGIN
   DECLARE  @attendance				int	
						
            
	select		@attendance = sum(isnull(attendance,0))
	from		movie_history,
					movie_country
	where		movie_country.movie_id = movie_history.movie_id
	and			movie_country.country_code = movie_history.country
	and			movie_country.country_code = @country_code
	and			movie_history.country = @country_code
	and			movie_history.movie_id = @movie_id
	and			movie_country.movie_id = @movie_id
	and			dateadd(wk, @week_num, movie_country.release_date) = movie_history.screening_date
    
	return(@attendance) 
   
END
GO
