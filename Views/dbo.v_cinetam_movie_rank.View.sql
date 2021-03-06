/****** Object:  View [dbo].[v_cinetam_movie_rank]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_rank]
GO
/****** Object:  View [dbo].[v_cinetam_movie_rank]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_cinetam_movie_rank] 
AS
SELECT       ROW_NUMBER() OVER (PARTITION BY country, Screening_date, cinetam_demographics_desc
						ORDER BY cinetam_demographics_desc, sum(Attds)  Desc) as Row_Count, 
						country, 
						screening_date, 
						cinetam_demographics_desc, 
						movie_id, 
						long_name, 
						sum(Attds) as attds, 
						sum(Prints) as Prints
FROM           v_cinetam_movie_summary
GROUP by country, 
						screening_date, 
						cinetam_demographics_desc, 
						movie_id, 
						long_name
                          



GO
