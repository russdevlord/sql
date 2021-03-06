/****** Object:  View [dbo].[v_cinetam_movie_history_weekend_compare]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_weekend_compare]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_weekend_compare]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_cinetam_movie_history_weekend_compare]
as
select				cinetam_movie_history_weekend.movie_id,
						cinetam_movie_history_weekend.complex_id,
						cinetam_movie_history_weekend.screening_date,
						cinetam_movie_history_weekend.occurence,
						cinetam_movie_history_weekend.print_medium,
						cinetam_movie_history_weekend.three_d_type,
						cinetam_movie_history_weekend.attendance,
						cinetam_movie_history_weekend.country_code,
						target_categories.movie_category_code,
						release_date,
						(select		attendance
						from			cinetam_movie_history
						where			movie_id = cinetam_movie_history_weekend.movie_id
						and				screening_date = cinetam_movie_history_weekend.screening_date
						and				complex_id  = cinetam_movie_history_weekend.complex_id
						and				occurence = cinetam_movie_history_weekend.occurence
						and				print_medium = cinetam_movie_history_weekend.print_medium
						and				three_d_type = cinetam_movie_history_weekend.three_d_type) as full_week_attendance,
						DATEDIFF(wk, release_date, screening_date) + 1 as week_of_release
from				cinetam_movie_history_weekend, target_categories, movie_country
where				attendance <> 0 
and					cinetam_movie_history_weekend.movie_id  = target_categories.movie_id 
and					movie_country.country_code = cinetam_movie_history_weekend.country_code
and					movie_country.movie_id = cinetam_movie_history_weekend.movie_id
GO
