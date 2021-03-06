/****** Object:  View [dbo].[v_movie_history_weekend_compare]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_history_weekend_compare]
GO
/****** Object:  View [dbo].[v_movie_history_weekend_compare]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_movie_history_weekend_compare]
as
select				movie_history_weekend.movie_id,
						movie_history_weekend.complex_id,
						movie_history_weekend.screening_date,
						movie_history_weekend.occurence,
						movie_history_weekend.print_medium,
						movie_history_weekend.three_d_type,
						movie_history_weekend.premium_cinema,
						movie_history_weekend.attendance,
						movie_history_weekend.country,
						target_categories.movie_category_code,
						release_date,
						(select		attendance
						from			movie_history
						where			movie_id = movie_history_weekend.movie_id
						and				screening_date = movie_history_weekend.screening_date
						and				complex_id  = movie_history_weekend.complex_id
						and				occurence = movie_history_weekend.occurence
						and				print_medium = movie_history_weekend.print_medium
						and				premium_cinema = movie_history_weekend.premium_cinema
						and				three_d_type = movie_history_weekend.three_d_type) as full_week_attendance,
						DATEDIFF(wk, release_date, screening_date) + 1 as week_of_release
from				movie_history_weekend, target_categories, movie_country
where				attendance <> 0 
and					movie_history_weekend.movie_id  = target_categories.movie_id 
and					movie_country.country_code = movie_history_weekend.country
and					movie_country.movie_id = movie_history_weekend.movie_id
GO
