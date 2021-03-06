/****** Object:  View [dbo].[v_movie_history]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_history]
GO
/****** Object:  View [dbo].[v_movie_history]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_movie_history]
AS
SELECT     dbo.movie_history.movie_id, dbo.movie_history.complex_id, 
                      dbo.movie_history.screening_date, dbo.movie_history.occurence, dbo.movie_history.print_medium, dbo.movie_history.three_d_type,
                      SUM(ISNULL(dbo.movie_history.attendance, 0)) AS attendance,
                       (select count(*) from movie_history hist where hist.movie_id = movie_history.movie_id 
                       and hist.screening_date = movie_history.screening_date 
                       and hist.complex_id = movie_history.complex_id 
                      and	hist.occurence =  movie_history.occurence  ) AS no_prints, long_name, country as country
FROM         dbo.movie_history INNER JOIN
                      dbo.movie ON
                      dbo.movie_history.movie_id = dbo.movie.movie_id
GROUP BY dbo.movie_history.movie_id, dbo.movie_history.complex_id, dbo.movie_history.country,
                      dbo.movie_history.screening_date, dbo.movie_history.occurence, dbo.movie_history.print_medium, dbo.movie_history.three_d_type,long_name








GO
