/****** Object:  View [dbo].[v_availability_avg_cplx_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_availability_avg_cplx_attendance]
GO
/****** Object:  View [dbo].[v_availability_avg_cplx_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_availability_avg_cplx_attendance]
as
select			movie_history.complex_id, 
					movie_history.screening_date, 
					avg(attendance * (1 - mm_adjustment)) as avg_mm_attendance, 
					0 as cinetam_reporting_demographics_id
from				movie_history
inner join		v_cinetam_mm_adjustment on movie_history.country = v_cinetam_mm_adjustment.country_code and movie_history.screening_date = v_cinetam_mm_adjustment.screening_date
where			attendance > 0
and				movie_id <> 102
and				advertising_open <> 'N'
and				premium_cinema <> 'Y'
group by		movie_history.complex_id,  
					movie_history.screening_date
union all
select			temp_table.complex_id, 
					temp_table.screening_date,
					avg(combo_attendance * (1 - mm_adjustment)) as avg_attendance,
					cinetam_reporting_demographics_id
from				(select			cinetam_movie_history.complex_id, 
										cinetam_movie_history.screening_date, 
										cinetam_movie_history.certificate_group_id,
										cinetam_movie_history.country_code,
										sum(cinetam_movie_history.attendance) as combo_attendance, 
										cinetam_reporting_demographics_id
					from				cinetam_movie_history
					inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
					inner join		movie_history on cinetam_movie_history.certificate_group_id = movie_history.certificate_group
					and				cinetam_movie_history.movie_id <> 102
					and				advertising_open <> 'N'
					and				premium_cinema <> 'Y'
					group by		cinetam_movie_history.complex_id, 
										cinetam_movie_history.screening_date, 
										cinetam_movie_history.certificate_group_id,
										cinetam_movie_history.country_code,
										cinetam_reporting_demographics_id) as temp_table
inner join		v_cinetam_mm_adjustment on temp_table.country_code = v_cinetam_mm_adjustment.country_code and temp_table.screening_date = v_cinetam_mm_adjustment.screening_date
where			combo_attendance > 0
and				cinetam_reporting_demographics_id <> 0
group by		temp_table.complex_id, 
					temp_table.screening_date,
					cinetam_reporting_demographics_id
GO
