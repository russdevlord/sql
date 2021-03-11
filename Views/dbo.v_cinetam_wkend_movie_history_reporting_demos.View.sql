/****** Object:  View [dbo].[v_cinetam_wkend_movie_history_reporting_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_wkend_movie_history_reporting_demos]
GO
/****** Object:  View [dbo].[v_cinetam_wkend_movie_history_reporting_demos]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinetam_wkend_movie_history_reporting_demos]
AS
SELECT     dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_desc, dbo.cinetam_wkend_movie_history.movie_id, dbo.cinetam_wkend_movie_history.complex_id, 
                      dbo.cinetam_wkend_movie_history.screening_date, dbo.cinetam_wkend_movie_history.occurence, dbo.cinetam_wkend_movie_history.print_medium, dbo.cinetam_wkend_movie_history.three_d_type,
                      SUM(ISNULL(dbo.cinetam_wkend_movie_history.attendance, 0)) AS attendance,
                       (select count(*) from movie_history hist where hist.movie_id = cinetam_wkend_movie_history.movie_id 
                       and hist.screening_date = cinetam_wkend_movie_history.screening_date 
                       and hist.complex_id = cinetam_wkend_movie_history.complex_id 
                      and	hist.occurence =  cinetam_wkend_movie_history.occurence  ) AS no_prints, 
                      dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id, long_name, 'A' as country
FROM         dbo.cinetam_wkend_movie_history INNER JOIN
                      dbo.cinetam_reporting_demographics_xref ON 
                      dbo.cinetam_wkend_movie_history.cinetam_demographics_id = dbo.cinetam_reporting_demographics_xref.cinetam_demographics_id INNER JOIN
                      dbo.cinetam_reporting_demographics ON  
                      dbo.cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id inner join
                      dbo.movie ON
                      dbo.cinetam_wkend_movie_history.movie_id = dbo.movie.movie_id
                      
GROUP BY dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_desc, dbo.cinetam_wkend_movie_history.movie_id, dbo.cinetam_wkend_movie_history.complex_id, 
                      dbo.cinetam_wkend_movie_history.screening_date, dbo.cinetam_wkend_movie_history.occurence, dbo.cinetam_wkend_movie_history.print_medium, dbo.cinetam_wkend_movie_history.three_d_type,
                      dbo.cinetam_reporting_demographics.cinetam_reporting_demographics_id,
                      long_name
GO
