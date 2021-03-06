/****** Object:  View [dbo].[v_cinetam_movie_match_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_match_report]
GO
/****** Object:  View [dbo].[v_cinetam_movie_match_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_cinetam_movie_match_report]
as
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history.country_code,
						cinetam_demographics_desc,
						sum(attendance) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as no_prints_this_week,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as all_people_attendance,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) / (select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as avg_all_people_attendance
from				cinetam_movie_history,
						movie,
						cinetam_demographics
where			cinetam_movie_history.movie_id = movie.movie_id
and					cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and					datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 between 0 and 20
group by		screening_date, 
						cinetam_movie_history.country_code,
						movie.movie_id, 
						movie.long_name ,
						cinetam_demographics_desc
union all
select			'Actual Movie' as row_mode,
						screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history.country_code,
						cinetam_reporting_demographics_desc,
						sum(attendance) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as no_prints_this_week,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as all_people_attendance,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) / (select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = movie.movie_id ) as avg_all_people_attendance
from				cinetam_movie_history,
						movie,
						cinetam_reporting_demographics_xref,
                        cinetam_reporting_demographics
where			cinetam_movie_history.movie_id = movie.movie_id
and					cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and                 cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id not in (8,13)
and					datediff(wk, (select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ), screening_date) + 1 between 0 and 20
group by		screening_date, 
						movie.movie_id, 
						cinetam_movie_history.country_code,
						movie.long_name ,
						cinetam_reporting_demographics_desc
union all
select			'Matched Movie' as row_mode,
						dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = 'A'), screening_Date) , (select release_date from movie_country where country_code = 'A' and movie_id = movie.movie_id)) as screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = 'A'), screening_Date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history.country_code,
						cinetam_demographics_desc,
						sum(isnull(attendance,0) * isnull(adjustment_factor,0)) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) as no_prints_this_week,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) * isnull(adjustment_factor,0) as all_people_attendance,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) * isnull(adjustment_factor,0) / (select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) as  avg_all_people_attendance
from				cinetam_movie_history,
						movie, 
						cinetam_movie_matches,
						cinetam_demographics
where			cinetam_movie_history.movie_id = cinetam_movie_matches.matched_movie_id 
and					cinetam_movie_matches.movie_id = movie.movie_id
and					cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and					datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = 'A'), screening_Date) + 1 between  0 and 20
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_demographics_desc,
						cinetam_movie_matches.matched_movie_id,
						cinetam_movie_history.country_code,
						adjustment_factor

union all
select			'Matched Movie' as row_mode,
						dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = 'A'), screening_Date) , (select release_date from movie_country where country_code = 'A' and movie_id = movie.movie_id)) as screening_date, 
						datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = 'A'), screening_Date) + 1 as wk_num,
						(select release_date from movie_country where movie_id = movie.movie_id and country_code = 'A' ) as release_date,
						movie.movie_id, 
						movie.long_name ,
						cinetam_movie_history.country_code,
						cinetam_reporting_demographics_desc,
						sum(isnull(attendance,0) * isnull(adjustment_factor,0)) as demo_attendance,
						(select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) as no_prints_this_week,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) * isnull(adjustment_factor,0) as all_people_attendance,
						(select sum(isnull(attendance,0)) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) * isnull(adjustment_factor,0) / (select count(*) from movie_history where screening_date =cinetam_movie_history.screening_date and country = 'A' and movie_id = cinetam_movie_matches.matched_movie_id ) as  avg_all_people_attendance
from				cinetam_movie_history,
						movie, 
						cinetam_movie_matches,
						cinetam_reporting_demographics,
                        cinetam_reporting_demographics_xref
where			cinetam_movie_history.movie_id = cinetam_movie_matches.matched_movie_id 
and					cinetam_movie_matches.movie_id = movie.movie_id
and					cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id not in (8,13)
and					datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = 'A'), screening_Date) + 1 between  0 and 20
group by		screening_date, 
						movie.movie_id, 
						movie.long_name ,
						cinetam_reporting_demographics_desc,
						cinetam_movie_history.country_code,
						cinetam_movie_matches.matched_movie_id,
						adjustment_factor
GO
