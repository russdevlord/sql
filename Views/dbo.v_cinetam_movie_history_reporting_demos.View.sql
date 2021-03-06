/****** Object:  View [dbo].[v_cinetam_movie_history_reporting_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_reporting_demos]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_reporting_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE VIEW [dbo].[v_cinetam_movie_history_reporting_demos]
AS

SELECT			'All People' as cinetam_reporting_demographics_desc, 
				movie_history.movie_id, 
				movie_history.complex_id, 
				movie_history.screening_date, 
				movie_history.occurence, 
				movie_history.print_medium, 
				movie_history.three_d_type,
				SUM(ISNULL(movie_history.attendance, 0)) AS attendance,
				1 AS no_prints, 
				0 as cinetam_reporting_demographics_id, 
				long_name, 
				movie_history.country as 'country',
				movie_history.certificate_group as certificate_group_id
FROM			movie_history,
				movie
where			movie_history.movie_id = movie.movie_id
GROUP BY		movie_history.movie_id, 
				movie_history.complex_id, 
				movie_history.screening_date, 
				movie_history.occurence, 
				movie_history.print_medium, 
				movie_history.three_d_type,
				long_name, 
				movie_history.country,
				movie_history.certificate_group
union all
SELECT			cinetam_reporting_demographics.cinetam_reporting_demographics_desc, 
				cinetam_movie_history.movie_id, 
				cinetam_movie_history.complex_id, 
				cinetam_movie_history.screening_date, 
				cinetam_movie_history.occurence, 
				cinetam_movie_history.print_medium, 
				cinetam_movie_history.three_d_type,
				SUM(ISNULL(cinetam_movie_history.attendance, 0)) AS attendance,
				1 AS no_prints, 
				cinetam_reporting_demographics.cinetam_reporting_demographics_id, 
				long_name, 
				cinetam_movie_history.country_code as 'country',
				cinetam_movie_history.certificate_group_id
FROM			cinetam_movie_history,
				cinetam_reporting_demographics_xref,
				cinetam_reporting_demographics,
				movie
where			cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and				cinetam_movie_history.movie_id = movie.movie_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and				cinetam_reporting_demographics.cinetam_reporting_demographics_id <> 0		
GROUP BY		cinetam_reporting_demographics.cinetam_reporting_demographics_desc, 
				cinetam_movie_history.movie_id, 
				cinetam_movie_history.complex_id, 
				cinetam_movie_history.screening_date, 
				cinetam_movie_history.occurence, 
				cinetam_movie_history.print_medium, 
				cinetam_movie_history.three_d_type,
				cinetam_reporting_demographics.cinetam_reporting_demographics_id, 
				long_name, 
				cinetam_movie_history.country_code ,
				cinetam_movie_history.certificate_group_id

GO
