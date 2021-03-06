/****** Object:  View [dbo].[v_cinetam_movie_history_weekend_reporting_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_weekend_reporting_demos]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_weekend_reporting_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO





CREATE VIEW [dbo].[v_cinetam_movie_history_weekend_reporting_demos]
AS

SELECT			'All People' as cinetam_reporting_demographics_desc, 
				movie_history_weekend.movie_id, 
				movie_history_weekend.complex_id, 
				movie_history_weekend.screening_date, 
				movie_history_weekend.occurence, 
				movie_history_weekend.print_medium, 
				movie_history_weekend.three_d_type,
				SUM(ISNULL(movie_history_weekend.attendance, 0)) AS attendance,
				SUM(ISNULL(movie_history_weekend.full_attendance, 0)) AS full_attendance,
				1 AS no_prints, 
				0 as cinetam_reporting_demographics_id, 
				long_name, 
				movie_history_weekend.country as 'country',
				movie_history_weekend.certificate_group as certificate_group_id
FROM			movie_history_weekend,
				movie
where			movie_history_weekend.movie_id = movie.movie_id
GROUP BY		movie_history_weekend.movie_id, 
				movie_history_weekend.complex_id, 
				movie_history_weekend.screening_date, 
				movie_history_weekend.occurence, 
				movie_history_weekend.print_medium, 
				movie_history_weekend.three_d_type,
				long_name, 
				movie_history_weekend.country,
				movie_history_weekend.certificate_group
union all
SELECT			cinetam_reporting_demographics.cinetam_reporting_demographics_desc, 
				cinetam_movie_history_weekend.movie_id, 
				cinetam_movie_history_weekend.complex_id, 
				cinetam_movie_history_weekend.screening_date, 
				cinetam_movie_history_weekend.occurence, 
				cinetam_movie_history_weekend.print_medium, 
				cinetam_movie_history_weekend.three_d_type,
				SUM(ISNULL(cinetam_movie_history_weekend.attendance, 0)) AS attendance,
				SUM(ISNULL(cinetam_movie_history_weekend.full_attendance, 0)) AS full_attendance,
				1 AS no_prints, 
				cinetam_reporting_demographics.cinetam_reporting_demographics_id, 
				long_name, 
				cinetam_movie_history_weekend.country_code as 'country',
				cinetam_movie_history_weekend.certificate_group_id
FROM			cinetam_movie_history_weekend,
				cinetam_reporting_demographics_xref,
				cinetam_reporting_demographics,
				movie
where			cinetam_movie_history_weekend.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and				cinetam_movie_history_weekend.movie_id = movie.movie_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and				cinetam_reporting_demographics.cinetam_reporting_demographics_id <> 0		
GROUP BY		cinetam_reporting_demographics.cinetam_reporting_demographics_desc, 
				cinetam_movie_history_weekend.movie_id, 
				cinetam_movie_history_weekend.complex_id, 
				cinetam_movie_history_weekend.screening_date, 
				cinetam_movie_history_weekend.occurence, 
				cinetam_movie_history_weekend.print_medium, 
				cinetam_movie_history_weekend.three_d_type,
				cinetam_reporting_demographics.cinetam_reporting_demographics_id, 
				long_name, 
				cinetam_movie_history_weekend.country_code ,
				cinetam_movie_history_weekend.certificate_group_id
GO
