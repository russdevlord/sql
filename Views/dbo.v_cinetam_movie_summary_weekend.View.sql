/****** Object:  View [dbo].[v_cinetam_movie_summary_weekend]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_summary_weekend]
GO
/****** Object:  View [dbo].[v_cinetam_movie_summary_weekend]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_cinetam_movie_summary_weekend] 
as
SELECT			Distinct a.country, 
													a.screening_date, 
													'All People' AS cinetam_demographics_desc, 
													a.movie_id, 
													b.long_name, 
													SUM(a.attendance) Attds,
													count(a.movie_id) As Prints
                          FROM				movie_history_weekend a JOIN
													movie b ON a.movie_id = b.movie_id
						 where				screening_date > '1-jan-2010'													
                         GROUP BY	a.country, 
													a.screening_date, 
													a.movie_id, 
													b.long_name
                          UNION ALL
                          SELECT			country, 
													screening_date, 
													cinetam_reporting_demographics_desc, 
													movie_id, 
													long_name, 
													SUM(attendance) as Attds,
													sum(no_prints) as Prints
                          FROM				v_cinetam_movie_history_weekend_reporting_demos
						  where cinetam_reporting_demographics_id <> 0
                         GROUP BY	country, 
													screening_date, 
													movie_id, 
													long_name,
													cinetam_reporting_demographics_desc
GO
