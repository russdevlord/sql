USE [production]
GO
/****** Object:  View [dbo].[v_movio_data_post_analysis_weekend]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create	view	[dbo].[v_movio_data_post_analysis_weekend]
as
select				movie_code, 
						complex_id, 
						screening_date, 
						cinetam_demographics_id, 
						country_code,
						count(distinct membership_id) as unique_people, 
						sum(unique_transactions) as unique_transactions  
from				v_movio_data_demo_fsd_weekend
group by			movie_code, 
						complex_id, 
						screening_date, 
						cinetam_demographics_id,
						country_code
GO
