/****** Object:  View [dbo].[v_cinetam_trailers_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_trailers_attendance]
GO
/****** Object:  View [dbo].[v_cinetam_trailers_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
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
