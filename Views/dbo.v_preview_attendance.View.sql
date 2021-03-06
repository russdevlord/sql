/****** Object:  View [dbo].[v_preview_attendance]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_preview_attendance]
GO
/****** Object:  View [dbo].[v_preview_attendance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_preview_attendance]
as
select long_name, screening_date, release_date, cinetam_movie_history.country_code, cinetam_demographics_desc, sum(attendance) as attendance
from cinetam_movie_history, movie, movie_country, cinetam_demographics
where cinetam_movie_history.movie_id = movie.movie_id
and cinetam_movie_history.movie_id = movie_country.movie_id
and movie.movie_id = movie_country.movie_id
and cinetam_movie_history.country_code = movie_country.country_code
and screening_date < release_date
and cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
group by long_name, screening_date, release_date, cinetam_movie_history.country_code, cinetam_demographics_desc
union all
select long_name, screening_date, release_date, movie_history.country, 'All People', sum(attendance) as attendance
from movie_history, movie, movie_country
where movie_history.movie_id = movie.movie_id
and movie_history.movie_id = movie_country.movie_id
and movie.movie_id = movie_country.movie_id
and movie_history.country = movie_country.country_code
and screening_date < release_date
group by long_name, screening_date, release_date, movie_history.country
GO
