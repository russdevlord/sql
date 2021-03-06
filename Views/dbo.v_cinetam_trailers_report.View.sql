/****** Object:  View [dbo].[v_cinetam_trailers_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_trailers_report]
GO
/****** Object:  View [dbo].[v_cinetam_trailers_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view		[dbo].[v_cinetam_trailers_report]
as			
select			cinetam_trailers_screening_history.screening_date, 
					cinetam_trailers_screening_history.movie_uuid, 
					cinetam_trailers_screening_history.trailer_uuid, 
					cinetam_trailers_screening_history.plays, 
					cinetam_trailers_screening_history.movie_sessions, 
					cinetam_trailers_screening_history.attendance_multiplier, 
					cinetam_trailers_movie.title as movie_title, 
					movie.long_name as movie_name, 
					cinetam_trailers_trailers.trailer_name as trailer_name, 
					cinetam_trailers_trailers.trailer_desc as trailer_desc, 
					cinetam_trailers_trailers.title as trailer_title, 
					trailer_movie.long_name as trailer_movie_name, 
					v_cinetam_trailers_attendance.cinetam_demographics_id, 
					v_cinetam_trailers_attendance.attendance, 
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_demographics.gender,
					cinetam_demographics.min_age,
					cinetam_demographics.max_age,
					complex_name,
					v_cinetam_trailers_attendance.complex_id,
					v_cinetam_trailers_attendance.country_code
from			cinetam_trailers_screening_history,
					cinetam_trailers_movie,
					movie,
					cinetam_trailers_trailers,
					movie trailer_movie,
					v_cinetam_trailers_attendance,
					cinetam_demographics,
					complex
where			cinetam_trailers_screening_history.movie_movie_id = cinetam_trailers_movie.movie_id
and				cinetam_trailers_screening_history.movie_uuid = cinetam_trailers_movie.uuid
and				movie.movie_id = cinetam_trailers_movie.movie_id
and				movie.movie_id = cinetam_trailers_screening_history.movie_movie_id
and				cinetam_trailers_screening_history.trailer_movie_id = cinetam_trailers_trailers.movie_id
and				cinetam_trailers_screening_history.trailer_uuid = cinetam_trailers_trailers.uuid
and				trailer_movie.movie_id = cinetam_trailers_trailers.movie_id
and				trailer_movie.movie_id = cinetam_trailers_screening_history.trailer_movie_id
and				v_cinetam_trailers_attendance.screening_date = cinetam_trailers_screening_history.screening_date
and				v_cinetam_trailers_attendance.complex_id = cinetam_trailers_screening_history.complex_id
and				v_cinetam_trailers_attendance.movie_id = cinetam_trailers_screening_history.movie_movie_id
and				cinetam_demographics.cinetam_demographics_id = v_cinetam_trailers_attendance.cinetam_demographics_id
and				cinetam_trailers_screening_history.complex_id = complex.complex_id

union
select			cinetam_trailers_screening_history.screening_date, 
				cinetam_trailers_screening_history.movie_uuid, 
				cinetam_trailers_screening_history.trailer_uuid, 
				cinetam_trailers_screening_history.plays, 
				cinetam_trailers_screening_history.movie_sessions, 
				cinetam_trailers_screening_history.attendance_multiplier, 
				cinetam_trailers_movie.title as movie_title, 
				movie.long_name as movie_name, 
				cinetam_trailers_trailers.trailer_name as trailer_name, 
				cinetam_trailers_trailers.trailer_desc as trailer_desc, 
				cinetam_trailers_trailers.title as trailer_title, 
				trailer_movie.long_name as trailer_movie_name, 
				v_cinetam_trailers_attendance.cinetam_demographics_id, 
				v_cinetam_trailers_attendance.attendance, 
				'All People',
				'A',
				0,
				99,
				complex_name,
				v_cinetam_trailers_attendance.complex_id,
				v_cinetam_trailers_attendance.country_code
from			cinetam_trailers_screening_history,
				cinetam_trailers_movie,
				movie,
				cinetam_trailers_trailers,
				movie trailer_movie,
				v_cinetam_trailers_attendance,
				complex
where			cinetam_trailers_screening_history.movie_movie_id = cinetam_trailers_movie.movie_id
and				cinetam_trailers_screening_history.movie_uuid = cinetam_trailers_movie.uuid
and				movie.movie_id = cinetam_trailers_movie.movie_id
and				movie.movie_id = cinetam_trailers_screening_history.movie_movie_id
and				cinetam_trailers_screening_history.trailer_movie_id = cinetam_trailers_trailers.movie_id
and				cinetam_trailers_screening_history.trailer_uuid = cinetam_trailers_trailers.uuid
and				trailer_movie.movie_id = cinetam_trailers_trailers.movie_id
and				trailer_movie.movie_id = cinetam_trailers_screening_history.trailer_movie_id
and				v_cinetam_trailers_attendance.screening_date = cinetam_trailers_screening_history.screening_date
and				v_cinetam_trailers_attendance.complex_id = cinetam_trailers_screening_history.complex_id
and				v_cinetam_trailers_attendance.movie_id = cinetam_trailers_screening_history.movie_movie_id
and				cinetam_trailers_screening_history.complex_id = complex.complex_id
and				v_cinetam_trailers_attendance.cinetam_demographics_id = 0



/*
create view v_cinetam_trailers_attendance
as
select		cinetam_demographics_id,
			movie_id,
			complex_id,
			screening_date,
			avg(attendance) as attendance
from		cinetam_movie_history		
group by	cinetam_demographics_id,
			movie_id,
			complex_id,
			screening_date

p_cinetam_trailers_collect_data '13-nov-2014', 'A'
*/




GO
