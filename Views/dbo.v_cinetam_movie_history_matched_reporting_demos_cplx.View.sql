/****** Object:  View [dbo].[v_cinetam_movie_history_matched_reporting_demos_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_history_matched_reporting_demos_cplx]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_matched_reporting_demos_cplx]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_cinetam_movie_history_matched_reporting_demos_cplx]

as

select			cmm.movie_id,
				v_view.long_name,
				cinetam_reporting_demographics_id,
				cinetam_reporting_demographics_desc,
				v_view.country, 
				v_view.complex_id,
				cmm.adjustment_factor,
				v_view.screening_date,
				sum(attendance) as actual_attendance,
				sum(no_prints) as playlists,
				datediff(wk, isnull(mc.release_date, dateadd(wk, 1001, v_view.screening_date)), v_view.screening_date) + 1 as week_of_release
from			v_cinetam_movie_history_reporting_demos v_view
inner join		cinetam_movie_matches cmm on  v_view.movie_id = cmm.matched_movie_id and v_view.country = cmm.country_code
left outer join	movie_country mc on v_view.movie_id = mc.movie_id and v_view.country = mc.country_code
group by		cmm.movie_id,
				v_view.long_name,
				cinetam_reporting_demographics_id,
				cinetam_reporting_demographics_desc,
				v_view.screening_date,
				mc.release_date,
				v_view.country, 
				v_view.complex_id,
				cmm.adjustment_factor
GO
