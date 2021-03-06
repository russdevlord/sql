/****** Object:  View [dbo].[v_cinetam_weekend_process_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_weekend_process_report]
GO
/****** Object:  View [dbo].[v_cinetam_weekend_process_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




create view [dbo].[v_cinetam_weekend_process_report]
as
select				screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = cinetam_movie_history_weekend.country_code ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = cinetam_movie_history_weekend.country_code ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history_weekend.country_code,
						cinetam_reporting_demographics_desc,
						cinetam_reporting_demographics.cinetam_reporting_demographics_id,
						sum(attendance) as demo_attendance, 
						sum(full_attendance) as demo_full_attendance,
						(select count(*) from movie_history_weekend where screening_date =cinetam_movie_history_weekend.screening_date and country = cinetam_movie_history_weekend.country_code and movie_id = movie.movie_id ) as no_prints_this_week,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = cinetam_movie_history_weekend.country_code) as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = cinetam_movie_history_weekend.country_code) as movie_classification_desc,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc, 
						film_market.film_market_no
from				cinetam_movie_history_weekend,
						movie,
						cinetam_reporting_demographics,
						cinetam_reporting_demographics_xref,
						complex,
						film_market,
						movie_category,
						target_categories
where				cinetam_movie_history_weekend.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					cinetam_movie_history_weekend.movie_id = movie.movie_id
and					cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_movie_history_weekend.cinetam_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					movie.movie_id = target_categories.movie_id
and					target_categories.movie_category_code = movie_category.movie_category_code	
group by			screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_reporting_demographics_desc,
						cinetam_reporting_demographics.cinetam_reporting_demographics_id,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc,
						cinetam_movie_history_weekend.country_code,
						film_market.film_market_no

GO
