/****** Object:  View [dbo].[v_follow_film_movie_split]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_follow_film_movie_split]
GO
/****** Object:  View [dbo].[v_follow_film_movie_split]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_follow_film_movie_split]
as
select		movie_id,
			cinetam_reporting_demographics_id,
			screening_date,
			complex_id,
			sum(attendance) as attendance_share
from		v_cinetam_movie_history_reporting_demos
group by 	movie_id,
			cinetam_reporting_demographics_id,
			screening_date,
			complex_id
					
GO
