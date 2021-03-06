/****** Object:  View [dbo].[v_cinetam_movie_history_weekend_reporting_demos_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_weekend_reporting_demos_nz]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_weekend_reporting_demos_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO






CREATE VIEW [dbo].[v_cinetam_movie_history_weekend_reporting_demos_nz]
AS

SELECT    dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_desc, dbo.cinetam_movie_history_weekend.movie_id, dbo.cinetam_movie_history_weekend.complex_id, 
                      dbo.cinetam_movie_history_weekend.screening_date, dbo.cinetam_movie_history_weekend.occurence, dbo.cinetam_movie_history_weekend.print_medium, dbo.cinetam_movie_history_weekend.three_d_type,
                      SUM(ISNULL(dbo.cinetam_movie_history_weekend.attendance, 0)) AS attendance,
                       (select count(*) from movie_history_weekend hist where hist.movie_id = cinetam_movie_history_weekend.movie_id 
                       and hist.screening_date = cinetam_movie_history_weekend.screening_date 
                       and hist.complex_id = cinetam_movie_history_weekend.complex_id 
                      and	hist.occurence =  cinetam_movie_history_weekend.occurence  ) AS no_prints, 
                      dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id, long_name, cinetam_movie_history_weekend.country_code as 'country'
FROM         dbo.cinetam_movie_history_weekend,
							dbo.cinetam_reporting_demographics_xref,
							dbo.cinetam_reporting_demographics,
							dbo.movie
where				cinetam_movie_history_weekend.country_code = 'Z'                   
and						dbo.cinetam_movie_history_weekend.cinetam_demographics_id = dbo.cinetam_reporting_demographics_xref.cinetam_demographics_id
and						dbo.cinetam_movie_history_weekend.movie_id = dbo.movie.movie_id
and						dbo.cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id
and						dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id <> 0
GROUP BY		dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_desc, dbo.cinetam_movie_history_weekend.movie_id, dbo.cinetam_movie_history_weekend.complex_id, 
							dbo.cinetam_movie_history_weekend.screening_date, dbo.cinetam_movie_history_weekend.occurence, dbo.cinetam_movie_history_weekend.print_medium, dbo.cinetam_movie_history_weekend.three_d_type,
							dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id,cinetam_movie_history_weekend.country_code,
							long_name


GO
