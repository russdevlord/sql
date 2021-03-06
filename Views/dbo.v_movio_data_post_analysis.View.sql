/****** Object:  View [dbo].[v_movio_data_post_analysis]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movio_data_post_analysis]
GO
/****** Object:  View [dbo].[v_movio_data_post_analysis]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create	view	[dbo].[v_movio_data_post_analysis]
as
select				movie_code, 
						complex_id, 
						screening_date, 
						cinetam_demographics_id, 
						country_code,
						count(distinct membership_id) as unique_people, 
						sum(unique_transactions) as unique_transactions  
from				v_movio_data_demo_fsd 
group by			movie_code, 
						complex_id, 
						screening_date, 
						cinetam_demographics_id,
						country_code

GO
