/****** Object:  View [dbo].[v_movie_attendance_by_release_date_and_mkt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_attendance_by_release_date_and_mkt]
GO
/****** Object:  View [dbo].[v_movie_attendance_by_release_date_and_mkt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_movie_attendance_by_release_date_and_mkt] as
select		dbo.f_movie_categories(movie.movie_id) as movie_categories, 
				long_name, movie_country.country_code, 
				release_date, 
				classification_desc, 
				screening_date,
				film_market.film_market_no,
				film_market.film_market_desc, 
				sum(attendance) as all_people_attendance, 
				count(movie.movie_id) as no_prints,
				datediff(wk, release_date,screening_date) + 1 as release_week
from		movie, 
				movie_country, 
				classification, 
				movie_history,
				complex,
				film_market
where		movie.movie_id = movie_country.movie_id
and			movie_country.classification_id = classification.classification_id
and			movie.movie_id = movie_history.movie_id
and			movie_country.country_code = movie_history.country
and			movie_history.attendance <> 0
and			movie_history.complex_id = complex.complex_id
and			complex.film_market_no = film_market.film_market_no
group by long_name, 
				movie_country.country_code, 
				release_date, 
				classification_desc, 
				screening_date, 
				movie.movie_id,
				film_market.film_market_no,
				film_market.film_market_desc

GO
