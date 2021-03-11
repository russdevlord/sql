USE [production]
GO
/****** Object:  View [dbo].[v_movio_data_post_analysis_aaa]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create	view	[dbo].[v_movio_data_post_analysis_aaa]
as
select			movie_code, 
						complex_id, 
						screening_date, 
						cinetam_demographics_id, 
						membership_id,
						sum(unique_transactions) as unique_transactions ,
						country_code
from				v_movio_data_demo_fsd 
group by		movie_code, 
						complex_id, 
						screening_date, 
						cinetam_demographics_id,
						membership_id ,
						country_code
						

GO
