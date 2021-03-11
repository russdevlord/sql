USE [production]
GO
/****** Object:  View [dbo].[v_inclusion_cinetam_attendance_weekend]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO








create view [dbo].[v_inclusion_cinetam_attendance_weekend]
as
SELECT		inclusion.inclusion_id,
					inclusion.campaign_no,
					movie_history_weekend.screening_date,
					0 as cinetam_reporting_demographics_id,
					movie_history_weekend.movie_id, 
					sum(attendance) as attendance, 
					sum(full_attendance) as full_attendance
FROM			inclusion_campaign_spot_xref
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		movie_history_weekend on v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
inner	 join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
where			spot_status = 'X'
group by		inclusion.inclusion_id,
					movie_history_weekend.screening_date,
					inclusion.campaign_no,
					movie_history_weekend.movie_id
union	 			
SELECT		inclusion.inclusion_id,
					inclusion.campaign_no,
					cinetam_movie_history_weekend.screening_date,
					cinetam_reporting_demographics_id,
					cinetam_movie_history_weekend.movie_id,
					sum(attendance) as attendance, 
					sum(full_attendance) as full_attendance
FROM			inclusion_campaign_spot_xref
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		cinetam_movie_history_weekend on v_certificate_item_distinct.certificate_group = cinetam_movie_history_weekend.certificate_group_id
inner join		cinetam_reporting_demographics_xref on cinetam_movie_history_weekend.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner	 join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
where			spot_status = 'X'
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
group by		inclusion.inclusion_id,
					cinetam_movie_history_weekend.screening_date,
					inclusion.campaign_no,
					cinetam_reporting_demographics_id,
					cinetam_movie_history_weekend.movie_id

GO
