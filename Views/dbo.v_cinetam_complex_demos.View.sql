USE [production]
GO
/****** Object:  View [dbo].[v_cinetam_complex_demos]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinetam_complex_demos]
AS
SELECT     dbo.complex.complex_name, dbo.cinetam_demographics.cinetam_demographics_desc, dbo.cinetam_movie_history.movie_id, dbo.cinetam_movie_history.complex_id, 
                      dbo.cinetam_movie_history.screening_date, dbo.cinetam_movie_history.occurence, dbo.cinetam_movie_history.print_medium, dbo.cinetam_movie_history.three_d_type,
                      SUM(ISNULL(dbo.cinetam_movie_history.attendance, 0)) AS attendance, (select count(*) from movie_history hist where hist.movie_id = cinetam_movie_history.movie_id and hist.screening_date = cinetam_movie_history.screening_date and hist.complex_id = cinetam_movie_history.complex_id  ) AS no_prints, 
                      dbo.cinetam_demographics.cinetam_demographics_id, long_name, 'A' as country
FROM         dbo.cinetam_movie_history INNER JOIN
                      dbo.cinetam_demographics ON 
                      dbo.cinetam_movie_history.cinetam_demographics_id = dbo.cinetam_demographics.cinetam_demographics_id INNER JOIN
                      dbo.movie ON
                      dbo.cinetam_movie_history.movie_id = dbo.movie.movie_id inner join
                      dbo.complex ON
                      dbo.complex.complex_id = dbo.cinetam_movie_history.complex_id
                     
                      
                      
GROUP BY dbo.complex.complex_name,  dbo.cinetam_demographics.cinetam_demographics_desc, dbo.cinetam_movie_history.movie_id, dbo.cinetam_movie_history.complex_id, 
                      dbo.cinetam_movie_history.screening_date, dbo.cinetam_movie_history.occurence, dbo.cinetam_movie_history.print_medium, dbo.cinetam_movie_history.three_d_type,
                      dbo.cinetam_demographics.cinetam_demographics_id,
                      long_name
GO
