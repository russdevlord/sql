USE [production]
GO
/****** Object:  View [dbo].[v_cinetam_movie_market_demo_report]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Drop View v_cinetam_movie_market_demo_report
--GO
/****** Object:  View [dbo].[v_cinetam_movie_demo_report]    Script Date: 10/31/2013 08:22:25 ******/
create view [dbo].[v_cinetam_movie_market_demo_report]
as
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						'A' as country_code,
						cinetam_demographics_desc,
						sum(attendance) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as no_prints_this_week,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'A') as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'A') as movie_classification_desc,
						film_market.film_market_no,
						film_market.film_market_desc
from				cinetam_movie_history,
						movie,
						cinetam_demographics,
						complex,
						film_market
where			cinetam_movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					cinetam_movie_history.movie_id = movie.movie_id
and					cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_demographics_desc,
						film_market.film_market_no,
						film_market.film_market_desc
union
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						'A' as country_code,
						cinetam_reporting_demographics_desc,
						sum(attendance) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as no_prints_this_week
,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'A') as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'A') as movie_classification_desc,
						film_market.film_market_no,
						film_market.film_market_desc
from				cinetam_movie_history,
						movie,
						cinetam_reporting_demographics,
						cinetam_reporting_demographics_xref,
						complex,
						film_market
where			cinetam_movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					cinetam_movie_history.movie_id = movie.movie_id
and					cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id not in (8,13) 
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_reporting_demographics_desc,
						film_market.film_market_no,
						film_market.film_market_desc
union
SELECT row_mode, screening_date, wk_num, release_date, movie_id, long_name , country_code, cinetam_reporting_demographics_desc, demo_attendance, SUM(no_prints_this_week) no_prints_this_week, movie_classification_code,movie_classification_desc, film_market_no, film_market_desc
FROM
(select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						'A' as country_code,
						'AAll People Attendance' cinetam_reporting_demographics_desc,
						sum(attendance) as demo_attendance,
						count(*) as no_prints_this_week,
						(select classification_code from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'A') as movie_classification_code,
						(select classification_desc from movie_country, classification where movie_country.classification_id = classification.classification_id and movie_id = movie.movie_id and movie_country.country_code = 'A') as movie_classification_desc,
						film_market.film_market_no,
						film_market.film_market_desc
from				    movie_history,
						movie,
					    complex,
						film_market
where			movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					movie_history.movie_id = movie.movie_id
and country = 'A'
group by		screening_date, 
						movie.movie_id, 
						movie.long_name,
						film_market.film_market_no,
						film_market.film_market_desc
                        having sum(attendance) <> 0
)b
GROUP BY row_mode, screening_date, wk_num, release_date, movie_id, long_name , country_code, cinetam_reporting_demographics_desc, demo_attendance, movie_classification_code,movie_classification_desc, film_market_no, film_market_desc


GO
