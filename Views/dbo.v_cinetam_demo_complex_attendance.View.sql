/****** Object:  View [dbo].[v_cinetam_demo_complex_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_demo_complex_attendance]
GO
/****** Object:  View [dbo].[v_cinetam_demo_complex_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinetam_demo_complex_attendance]
AS
SELECT			dbo.cinetam_demographics.cinetam_demographics_desc, 
						complex.complex_name, 
						dbo.cinetam_movie_history.screening_date, 
						SUM(ISNULL(dbo.cinetam_movie_history.attendance, 0)) AS attendance,
						'A' as country
FROM			dbo.cinetam_movie_history INNER JOIN
						dbo.cinetam_demographics ON  
						dbo.cinetam_demographics.cinetam_demographics_id = dbo.cinetam_movie_history.cinetam_demographics_id inner join
						dbo.complex ON
						dbo.cinetam_movie_history.complex_id = dbo.complex.complex_id 
where				dbo.cinetam_movie_history.screening_date > '1-jan-2012'						
GROUP BY	dbo.cinetam_demographics.cinetam_demographics_desc, 
						complex.complex_name, 
						dbo.cinetam_movie_history.screening_date
GO
