USE [production]
GO
/****** Object:  View [dbo].[v_cinetam_trailers_attendance]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_cinetam_trailers_attendance]
as
select		cinetam_demographics_id,
			movie_id,
			complex_id,
			screening_date,
			sum(attendance) as attendance,
			country_code
from		cinetam_movie_history		
group by	cinetam_demographics_id,
			movie_id,
			complex_id,
			screening_date,
			country_code
union
select		0,
			movie_id,
			complex_id,
			screening_date,
			sum(attendance) as attendance,
			country as country_code
from		movie_history		
group by	movie_id,
			complex_id,
			screening_date,
			country




GO
