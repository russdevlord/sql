/****** Object:  View [dbo].[v_cinetam_weekend_estimates_complex_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_weekend_estimates_complex_report]
GO
/****** Object:  View [dbo].[v_cinetam_weekend_estimates_complex_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO





create view [dbo].[v_cinetam_weekend_estimates_complex_report]
as
select				cinetam_movie_complex_estimates.screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = film_market.country_code ), cinetam_movie_complex_estimates.screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = film_market.country_code ) as release_date,
						movie.movie_id, 
						movie.long_name,
						film_market.country_code,
						cinetam_reporting_demographics_desc,
						cinetam_reporting_demographics.cinetam_reporting_demographics_id,
						sum(cinetam_movie_complex_estimates.attendance) as demo_estimate, 
						sum(original_estimate) as demo_original_attendance,
						count(movie_history.movie_id) as no_prints_this_week,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc, 
						film_market.film_market_no,
						complex.complex_name,
						complex.complex_id
from				cinetam_movie_complex_estimates,
						movie,
						cinetam_reporting_demographics,
						complex,
						film_market,
						movie_category,
						target_categories,
						movie_history
where				cinetam_movie_complex_estimates.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					cinetam_movie_complex_estimates.movie_id = movie.movie_id
and					cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					movie.movie_id = target_categories.movie_id
and					target_categories.movie_category_code = movie_category.movie_category_code
and					cinetam_movie_complex_estimates.complex_id = movie_history.complex_id
and					cinetam_movie_complex_estimates.movie_id = movie_history.movie_id
and					cinetam_movie_complex_estimates.screening_date = movie_history.screening_date
group by			cinetam_movie_complex_estimates.screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_reporting_demographics_desc,
						cinetam_reporting_demographics.cinetam_reporting_demographics_id,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc,
						film_market.country_code,
						film_market.film_market_no,
						complex.complex_name,
						complex.complex_id
GO
