/****** Object:  View [dbo].[v_cinetam_all_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_all_attendance]
GO
/****** Object:  View [dbo].[v_cinetam_all_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_cinetam_all_attendance]
as
select			movie.long_name, 
					movie_history.movie_id,
					movie_history.screening_date,
					classification.classification_code, 
					classification.classification_desc,
					complex_region_class,
					count(occurence) as no_movies,
					datepart(yy,movie_history.screening_date) as screening_year,
					datepart(wk, movie_history.screening_date) as screening_week,
					sum(movie_history.attendance) as attendance
from			movie_history, 
					movie,
					movie_country, 
					complex,
					film_market,
					classification
where			movie_history.movie_id = movie.movie_id
and				movie.movie_id = movie_country.movie_id
and				movie_country.country_code = 'A'
and				movie_history.country = 'A'
and				movie_history.complex_id = complex.complex_id
and				complex.film_market_no = film_market.film_market_no
and				movie_country.classification_id = classification.classification_id
and				movie.movie_id <> 102
group by		movie.long_name, 
					movie_history.movie_id,
					movie_history.screening_date,
					classification.classification_code, 
					classification.classification_desc,
					complex_region_class
GO
