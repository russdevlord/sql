/****** Object:  View [dbo].[v_cinetam_movie_history_rfmkt_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_rfmkt_cplx]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_rfmkt_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE VIEW [dbo].[v_cinetam_movie_history_rfmkt_cplx]
AS

SELECT			movie_history.complex_id, 
				movie_history.screening_date, 
				0 as cinetam_reporting_demographics_id, 
				movie_history.country as 'country_code',
				film_market_no,
				SUM(ISNULL(movie_history.attendance, 0)) AS attendance
FROM			movie_history with (nolock) 
inner join		complex with (nolock) on movie_history.complex_id = complex.complex_id
where			isnull(attendance,0) <> 0	
GROUP BY		movie_history.complex_id, 
				movie_history.screening_date, 
				movie_history.country,
				film_market_no
union all
SELECT			cinetam_movie_history.complex_id, 
				cinetam_movie_history.screening_date, 
				cinetam_reporting_demographics_id, 
				cinetam_movie_history.country_code as 'country_code',
				film_market_no,
				SUM(ISNULL(cinetam_movie_history.attendance, 0)) AS attendance
FROM			cinetam_movie_history with (nolock)
inner join		cinetam_reporting_demographics_xref with (nolock) on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner join		complex with (nolock) on cinetam_movie_history.complex_id = complex.complex_id
where			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0		
and				isnull(attendance,0) <> 0	
GROUP BY		cinetam_movie_history.complex_id, 
				cinetam_movie_history.screening_date, 
				cinetam_reporting_demographics_id, 
				cinetam_movie_history.country_code,
				film_market_no

GO
