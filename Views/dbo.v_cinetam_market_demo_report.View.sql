/****** Object:  View [dbo].[v_cinetam_market_demo_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_market_demo_report]
GO
/****** Object:  View [dbo].[v_cinetam_market_demo_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_cinetam_market_demo_report]
as
select			'Actual Movie' as row_mode,
						screening_date, 
						film_market.film_market_no,
						film_market.film_market_code,
						film_market.film_market_desc,
						cinetam_movie_history.country_code,
						cinetam_demographics_desc,
						sum(attendance) as demo_attendance
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
						cinetam_movie_history.country_code,
						film_market.film_market_no,
						film_market.film_market_code,
						film_market.film_market_desc,
						cinetam_demographics_desc
union
select			'Actual Movie' as row_mode,
						screening_date, 
						film_market.film_market_no,
						film_market.film_market_code,
						film_market.film_market_desc,
						cinetam_movie_history.country_code,
						 'Rpt - ' + cinetam_reporting_demographics_desc,
						sum(attendance) as demo_attendance
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
						film_market.film_market_no,
						cinetam_movie_history.country_code,
						film_market.film_market_code,
						film_market.film_market_desc,
						cinetam_reporting_demographics_desc
union
select			'Actual Movie' as row_mode,
						screening_date, 
						film_market.film_market_no,
						film_market.film_market_code,
						film_market.film_market_desc,
						movie_history.country,
						'AAll People Attendance',
						sum(attendance) as demo_attendance
from				movie_history,
						movie,
						complex,
						film_market
where			movie_history.complex_id = complex.complex_id
and					complex.film_market_no = film_market.film_market_no
and					movie_history.movie_id = movie.movie_id
group by		screening_date, 
						film_market.film_market_no,
						movie_history.country,
						film_market.film_market_code,
						film_market.film_market_desc
having sum(attendance) <> 0

GO
