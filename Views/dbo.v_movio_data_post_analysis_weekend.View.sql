/****** Object:  View [dbo].[v_movio_data_post_analysis_weekend]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movio_data_post_analysis_weekend]
GO
/****** Object:  View [dbo].[v_movio_data_post_analysis_weekend]    Script Date: 12/03/2021 10:03:48 AM ******/
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
