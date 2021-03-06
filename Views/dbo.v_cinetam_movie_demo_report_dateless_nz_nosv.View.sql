/****** Object:  View [dbo].[v_cinetam_movie_demo_report_dateless_nz_nosv]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_demo_report_dateless_nz_nosv]
GO
/****** Object:  View [dbo].[v_cinetam_movie_demo_report_dateless_nz_nosv]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO





create view [dbo].[v_cinetam_movie_demo_report_dateless_nz_nosv]
as
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'Z' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'Z' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history.country_code,
						cinetam_demographics_desc,
						sum(attendance) as demo_attendance,
						(select count(*) from movie_history where screening_date = cinetam_movie_history.screening_date and country = 'Z' and movie_id = movie.movie_id ) as no_prints_this_week,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'Z') as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'Z') as movie_classification_desc,
						 movie_category.movie_category_code, movie_category.movie_category_desc, film_market.film_market_desc,  film_market.film_market_no
from				cinetam_movie_history,
						movie,
						cinetam_demographics,
						complex,
						film_market,
						movie_category,
						target_categories
where				cinetam_movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					cinetam_movie_history.movie_id = movie.movie_id
and					cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and					movie.movie_id = target_categories.movie_id
and					target_categories.movie_category_code = movie_category.movie_category_code	
and					cinetam_movie_history.country_code = 'Z'		
--and					screening_date > '1-jul-2012'
and					complex.complex_id not in (select complex_id from aaa_old_screenvista)
group by			screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_demographics_desc,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc,
						cinetam_movie_history.country_code,  film_market.film_market_no
union
select				'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'Z' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'Z' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history.country_code,
						cinetam_reporting_demographics_desc,
						sum(attendance) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'Z' and movie_id = movie.movie_id ) as no_prints_this_week
,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'Z') as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'Z') as movie_classification_desc,
						movie_category.movie_category_code, movie_category.movie_category_desc, film_market.film_market_desc,  film_market.film_market_no
from				cinetam_movie_history,
						movie,
						cinetam_reporting_demographics,
						cinetam_reporting_demographics_xref,
						complex,
						film_market,
						movie_category,
						target_categories
where				cinetam_movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					cinetam_movie_history.movie_id = movie.movie_id
and					cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					movie.movie_id = target_categories.movie_id
and					target_categories.movie_category_code = movie_category.movie_category_code	
and					cinetam_movie_history.country_code = 'Z'
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id not in (0,8,13) 
--and					screening_date > '1-jul-2012'
and					complex.complex_id not in (select complex_id from aaa_old_screenvista)
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_reporting_demographics_desc,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc,
						cinetam_movie_history.country_code,  film_market.film_market_no
union
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'Z' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'Z' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						country,
						'All People Attendance',
						sum(attendance) as demo_attendance,
						count(*) as no_prints_this_week,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'Z') as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'Z') as movie_classification_desc,
						movie_category.movie_category_code, movie_category.movie_category_desc, film_market.film_market_desc,  film_market.film_market_no
from				    movie_history,
						movie,
					    complex,
						film_market,
						movie_category,
						target_categories
where			movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					movie_history.movie_id = movie.movie_id
and				movie.movie_id = target_categories.movie_id
and				target_categories.movie_category_code = movie_category.movie_category_code		
and				country = 'Z'
--and					screening_date > '1-jul-2012'
and					complex.complex_id not in (select complex_id from aaa_old_screenvista)
group by			screening_date, 
						movie.movie_id, 
						movie.long_name,
						movie_category.movie_category_code, 
						movie_category.movie_category_desc, 
						film_market.film_market_desc,
						country,  film_market.film_market_no
                        having sum(attendance) <> 0



GO
