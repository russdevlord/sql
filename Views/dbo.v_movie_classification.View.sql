/****** Object:  View [dbo].[v_movie_classification]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_classification]
GO
/****** Object:  View [dbo].[v_movie_classification]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view		 [dbo].[v_movie_classification]
as
select				temp_table.movie_id, 
						temp_table.country_code, 
						temp_table.classification_id,
						ma_15_above,
						kids	
from					classification
inner join			(select				movie_id, 
												country_code,
												max(classification_id) as classification_id
						from					movie_country
						group by			movie_id, 
												country_code) as temp_table
on						classification.classification_id = temp_table.classification_id
GO
