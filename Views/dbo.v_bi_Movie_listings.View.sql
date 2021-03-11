USE [production]
GO
/****** Object:  View [dbo].[v_bi_Movie_listings]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[v_bi_Movie_listings] 
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
