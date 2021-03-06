/****** Object:  View [dbo].[v_cinetam_movie_history_reporting_demos_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_reporting_demos_nz]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_reporting_demos_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE VIEW [dbo].[v_cinetam_movie_history_reporting_demos_nz]
AS

SELECT    dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_desc, dbo.cinetam_movie_history.movie_id, dbo.cinetam_movie_history.complex_id, 
                      dbo.cinetam_movie_history.screening_date, dbo.cinetam_movie_history.occurence, dbo.cinetam_movie_history.print_medium, dbo.cinetam_movie_history.three_d_type,
                      SUM(ISNULL(dbo.cinetam_movie_history.attendance, 0)) AS attendance,
                       (select count(*) from movie_history hist where hist.movie_id = cinetam_movie_history.movie_id 
                       and hist.screening_date = cinetam_movie_history.screening_date 
                       and hist.complex_id = cinetam_movie_history.complex_id 
                      and	hist.occurence =  cinetam_movie_history.occurence  ) AS no_prints, 
                      dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id, long_name, cinetam_movie_history.country_code as 'country'
FROM         dbo.cinetam_movie_history,
							dbo.cinetam_reporting_demographics_xref,
							dbo.cinetam_reporting_demographics,
							dbo.movie
where				cinetam_movie_history.country_code = 'Z'                   
and						dbo.cinetam_movie_history.cinetam_demographics_id = dbo.cinetam_reporting_demographics_xref.cinetam_demographics_id
and						dbo.cinetam_movie_history.movie_id = dbo.movie.movie_id
and						dbo.cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id
GROUP BY		dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_desc, dbo.cinetam_movie_history.movie_id, dbo.cinetam_movie_history.complex_id, 
							dbo.cinetam_movie_history.screening_date, dbo.cinetam_movie_history.occurence, dbo.cinetam_movie_history.print_medium, dbo.cinetam_movie_history.three_d_type,
							dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id,cinetam_movie_history.country_code,
							long_name


GO
