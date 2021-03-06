/****** Object:  View [dbo].[v_cinetam_movie_history_core_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_core_demos]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_core_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE VIEW [dbo].[v_cinetam_movie_history_core_demos]
AS
SELECT					cinetam_movie_history.movie_id, 
								cinetam_movie_history.complex_id, 
								cinetam_movie_history.screening_date, 
								cinetam_movie_history.occurence, 
								cinetam_movie_history.print_medium, 
								cinetam_movie_history.three_d_type,
								cinetam_demographics_id,
								SUM(ISNULL(cinetam_movie_history.attendance, 0)) AS attendance,
								(select	certificate_group 
								from	movie_history hist 
								where	hist.movie_id = cinetam_movie_history.movie_id 
								and		hist.screening_date = cinetam_movie_history.screening_date 
								and		hist.complex_id = cinetam_movie_history.complex_id 
								and		hist.occurence =  cinetam_movie_history.occurence
								AND		hist.three_d_type = cinetam_movie_history.three_d_type
								AND		hist.print_medium = cinetam_movie_history.print_medium) AS certificate_group,
								(select count(*) 
								from	movie_history hist 
								where	hist.movie_id = cinetam_movie_history.movie_id 
								and		hist.screening_date = cinetam_movie_history.screening_date 
								and		hist.complex_id = cinetam_movie_history.complex_id 
								and		hist.occurence =  cinetam_movie_history.occurence  ) AS no_prints, 
								cinetam_movie_history.country_code as country,
								(select	hist.premium_cinema 
								from	movie_history hist 
								where	hist.movie_id = cinetam_movie_history.movie_id 
								and		hist.screening_date = cinetam_movie_history.screening_date 
								and		hist.complex_id = cinetam_movie_history.complex_id 
								and		hist.occurence =  cinetam_movie_history.occurence
								AND		hist.three_d_type = cinetam_movie_history.three_d_type
								AND		hist.print_medium = cinetam_movie_history.print_medium) as premium_cinema
FROM			cinetam_movie_history 
GROUP BY	cinetam_movie_history.movie_id, 
					cinetam_movie_history.complex_id, 
					cinetam_movie_history.screening_date, 
					cinetam_movie_history.occurence, 
					cinetam_movie_history.print_medium, 
					cinetam_movie_history.three_d_type,
					cinetam_demographics_id,
					cinetam_movie_history.country_code


GO
