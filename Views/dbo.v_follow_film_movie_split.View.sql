USE [production]
GO
/****** Object:  View [dbo].[v_follow_film_movie_split]    Script Date: 11/03/2021 2:30:32 PM ******/
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
