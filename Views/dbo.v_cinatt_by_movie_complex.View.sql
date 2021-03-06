/****** Object:  View [dbo].[v_cinatt_by_movie_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_by_movie_complex]
GO
/****** Object:  View [dbo].[v_cinatt_by_movie_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_cinatt_by_movie_complex]
AS

select      movie_history.country,
	        movie_history.screening_date,
            movie_history.complex_id,
            complex.complex_name,
			film_market.film_market_no,
			film_market.film_market_desc,
            movie_history.movie_id,
            movie.long_name 'movie_name',
            sum(movie_history.attendance) 'attendance' ,
            count(movie_history.movie_id) 'number_of_prints'
from        movie_history,
            complex,
            movie,
			film_market
where       movie_history.complex_id = complex.complex_id
and         movie_history.movie_id = movie.movie_id
and         movie_history.attendance is not null
and			complex.film_market_no = film_market.film_market_no
group by    movie_history.country,
	        movie_history.screening_date,
            movie_history.complex_id,
            complex.complex_name,
            movie_history.movie_id,
            movie.long_name,
			film_market.film_market_no,
			film_market.film_market_desc
having      sum(movie_history.attendance) > 0    
GO
