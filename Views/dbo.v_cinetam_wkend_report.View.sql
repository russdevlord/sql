/****** Object:  View [dbo].[v_cinetam_wkend_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_wkend_report]
GO
/****** Object:  View [dbo].[v_cinetam_wkend_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_cinetam_wkend_report]
as
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = cinetam_wkend_movio_data.country_code ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = cinetam_wkend_movio_data.country_code ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_wkend_movio_data.country_code,
						cinetam_demographics_desc,
						sum(demo_population) as demo_tickets_weighted_this_week,
						(select count(*) from movie_history where screening_date =cinetam_wkend_movio_data.screening_date and country = cinetam_wkend_movio_data.country_code and movie_id = movie.movie_id ) as no_prints_this_week,
						(select count(*) from movie_history where complex_id in (select complex_id from complex where exhibitor_id in (205, 191)) and screening_date =cinetam_wkend_movio_data.screening_date and country = cinetam_wkend_movio_data.country_code and movie_id = movie.movie_id ) as no_hoyts_prints_this_week
from				cinetam_wkend_movio_data,
						movie,
						cinetam_demographics
where			cinetam_wkend_movio_data.movie_id = movie.movie_id
and					cinetam_demographics.cinetam_demographics_id = cinetam_wkend_movio_data.cinetam_demographics_id
and					datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = cinetam_wkend_movio_data.country_code ), screening_date) + 1 between 0 and 20
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_wkend_movio_data.country_code,
						cinetam_demographics_desc
union all
select			'Matched Movie' as row_mode,
						dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = cinetam_wkend_movio_data.country_code), screening_Date) , (select release_date from movie_country where country_code = cinetam_wkend_movio_data.country_code and movie_id = movie.movie_id)) as screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = cinetam_wkend_movio_data.country_code), screening_Date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = cinetam_wkend_movio_data.country_code ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_wkend_movio_data.country_code,
						cinetam_demographics_desc,
						sum(round(demo_population * adjustment_factor,0)) as demo_tickets_weighted_this_week,
						(select count(*) from movie_history where screening_date =cinetam_wkend_movio_data.screening_date and country = cinetam_wkend_movio_data.country_code and movie_id = cinetam_movie_matches.matched_movie_id ) as no_prints_this_week,
						(select count(*) from movie_history where complex_id in (select complex_id from complex where exhibitor_id in (205, 191)) and  screening_date =cinetam_wkend_movio_data.screening_date and country = cinetam_wkend_movio_data.country_code and movie_id = cinetam_movie_matches.matched_movie_id ) as no_prints_this_week
from				cinetam_wkend_movio_data,
						movie, 
						cinetam_movie_matches,
						cinetam_demographics
where			cinetam_wkend_movio_data.movie_id = cinetam_movie_matches.matched_movie_id 
and					cinetam_wkend_movio_data.country_code = cinetam_movie_matches.country_code
and					cinetam_movie_matches.movie_id = movie.movie_id
and					cinetam_demographics.cinetam_demographics_id = cinetam_wkend_movio_data.cinetam_demographics_id
and					datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = cinetam_wkend_movio_data.country_code), screening_Date) + 1 between  0 and 20
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_wkend_movio_data.country_code,
						cinetam_demographics_desc,
						cinetam_movie_matches.matched_movie_id
GO
