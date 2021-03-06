/****** Object:  View [dbo].[v_film_campaign_pcr_attendance_digilite]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_campaign_pcr_attendance_digilite]
GO
/****** Object:  View [dbo].[v_film_campaign_pcr_attendance_digilite]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view  [dbo].[v_film_campaign_pcr_attendance_digilite]
as
select			campaign_no,
				package_id,
				movie_history.complex_id, 
				movie_history.screening_date,
				0 as cinetam_reporting_demographics_id,
				'All People' as cinetam_reporting_demographics_desc,
				sum(attendance) as attendance
from			v_film_campaign_pcr_digilite_details
inner join		movie_history on v_film_campaign_pcr_digilite_details.complex_id = movie_history.complex_id 
and				v_film_campaign_pcr_digilite_details.screening_date = movie_history.screening_date
group by		campaign_no,
				package_id,
				movie_history.complex_id, 
				movie_history.screening_date
union all
select			campaign_no,
				package_id,
				cinetam_movie_history.complex_id, 
				cinetam_movie_history.screening_date,
				cinetam_reporting_demographics.cinetam_reporting_demographics_id,
				cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
				sum(attendance) as attendance
from			v_film_campaign_pcr_digilite_details
inner join		cinetam_movie_history on v_film_campaign_pcr_digilite_details.complex_id = cinetam_movie_history.complex_id 
and				v_film_campaign_pcr_digilite_details.screening_date = cinetam_movie_history.screening_date
inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner join		cinetam_reporting_demographics on cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
where			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
group by		campaign_no,
				package_id,
				cinetam_movie_history.complex_id, 
				cinetam_movie_history.screening_date,
				cinetam_reporting_demographics.cinetam_reporting_demographics_id,
				cinetam_reporting_demographics.cinetam_reporting_demographics_desc
GO
