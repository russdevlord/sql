/****** Object:  View [dbo].[v_inclusion_cinetam_complex_attendance_no_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_inclusion_cinetam_complex_attendance_no_movie]
GO
/****** Object:  View [dbo].[v_inclusion_cinetam_complex_attendance_no_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO









create view [dbo].[v_inclusion_cinetam_complex_attendance_no_movie]
as
SELECT		inclusion.inclusion_id,
					inclusion.campaign_no,
					movie_history.screening_date,
					movie_history.complex_id,
					0 as cinetam_reporting_demographics_id,
					sum(attendance) as attendance
FROM			inclusion_campaign_spot_xref
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner	 join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
where			spot_status = 'X'
group by		inclusion.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					inclusion.campaign_no
union	 			
SELECT		inclusion.inclusion_id,
					inclusion.campaign_no,
					cinetam_movie_history.screening_date,
					cinetam_movie_history.complex_id, 
					cinetam_reporting_demographics_id,
					sum(attendance) as attendance
FROM			inclusion_campaign_spot_xref
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		cinetam_movie_history on v_certificate_item_distinct.certificate_group = cinetam_movie_history.certificate_group_id
inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner	 join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
where			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
and				spot_status = 'X'
group by		inclusion.inclusion_id,
					cinetam_movie_history.screening_date,
					cinetam_movie_history.complex_id,
					inclusion.campaign_no,
					cinetam_reporting_demographics_id

GO
