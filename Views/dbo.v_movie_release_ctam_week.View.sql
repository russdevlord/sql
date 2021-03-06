/****** Object:  View [dbo].[v_movie_release_ctam_week]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movie_release_ctam_week]
GO
/****** Object:  View [dbo].[v_movie_release_ctam_week]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_movie_release_ctam_week]
as
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					1 as week_num,
					sum(isnull(attendance,0)) as attendance,
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 0, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					2 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 1, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					3 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 2, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					4 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 3, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					5 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 4, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					6 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 5, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					7 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 7, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					8 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 7, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					9 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 8, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code
union
select			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code,
					10 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			v_cinetam_movie_history_reporting_demos,
					movie_country
where			movie_country.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
and				movie_country.country_code = 'A'
and				dateadd(wk, 9, movie_country.release_date) = v_cinetam_movie_history_reporting_demos.screening_date
group by		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_desc, v_cinetam_movie_history_reporting_demos.movie_id, 
					movie_country.country_code		
GO
