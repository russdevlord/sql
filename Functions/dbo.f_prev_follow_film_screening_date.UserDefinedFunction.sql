/****** Object:  UserDefinedFunction [dbo].[f_prev_follow_film_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_prev_follow_film_screening_date]
GO
/****** Object:  UserDefinedFunction [dbo].[f_prev_follow_film_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_prev_follow_film_screening_date] (@screening_date datetime, @movie_id  int, @country_code  char(1))
RETURNS datetime
AS
BEGIN
   DECLARE  	@previous_date					datetime,
						@release_date					datetime,
						@previous_release_date	datetime,
						@matched_movie_id			int
						
	select		@release_date = release_date
	from		movie_country
	where		movie_id = @movie_id
	and			country_code = @country_code
	
	select		@matched_movie_id = matched_movie_id
	from		cinetam_movie_matches 
	where		movie_id = @movie_id       
	and			country_code = @country_code      
	
	select		@previous_release_date = release_date
	from		movie_country
	where		movie_id = @matched_movie_id
	and			country_code = @country_code
        
    select  @previous_date = dateadd(wk, (datediff(wk, @release_date, @screening_date)), @previous_release_date)

   return(@previous_date)   
   
   error:
        return(@screening_date)
   
END



GO
