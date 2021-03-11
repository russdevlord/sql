USE [production]
GO
/****** Object:  View [dbo].[v_movie_attendance_by_genre]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_movie_attendance_by_genre] as
select		dbo.f_movie_categories(movie.movie_id) as movie_categories, 
				long_name, 
				movie_history.country, 
				screening_date, 
				sum(attendance) as all_people_attendance, 
				count(movie.movie_id) as no_prints
from			movie, 
				movie_history
where		movie.movie_id = movie_history.movie_id
and			movie_history.attendance <> 0
group by	long_name, 
				movie_history.country, 
				screening_date,
				movie.movie_id
GO
