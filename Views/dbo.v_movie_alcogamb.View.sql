USE [production]
GO
/****** Object:  View [dbo].[v_movie_alcogamb]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view		 [dbo].[v_movie_alcogamb]
as

select				over_18_olds.movie_id,
						over_18_olds.country_code,
						over_18,
						all_people,
						convert(numeric(20,10), over_18) / convert(numeric(20,10), all_people) as alcogamb_percent
from					(select				movie_id, 
												country_code,
												sum(attendance) as over_18
						from					cinetam_movie_history 
						where				cinetam_demographics_id != 1
						and					cinetam_demographics_id != 9
						--and					screening_date > dateadd(wk, -60, getdate())
						group by			movie_id, 
												country_code) as over_18_olds
inner join			(select				movie_id, 
												country,
												sum(attendance) as all_people
						from					movie_history 
						group by			movie_id, 
												country) as all_peoples on over_18_olds.movie_id = all_peoples.movie_id and over_18_olds.country_code = all_peoples.country
where				all_people <> 0
GO
