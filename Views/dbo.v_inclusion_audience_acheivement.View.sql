/****** Object:  View [dbo].[v_inclusion_audience_acheivement]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_inclusion_audience_acheivement]
GO
/****** Object:  View [dbo].[v_inclusion_audience_acheivement]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*NOTE*/
/*SPOT STATUS NO SHOW NOT FACTORED IN AS THIS SHOWS WHAT THE SYSTEM THOUGHT IT GOT NOT WHAT IT ACTUALLY GOT*/

create view [dbo].[v_inclusion_audience_acheivement]
as
select			inclusion_spot.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,
					sum(cinetam_movie_complex_estimates.attendance) as achieved_attendance,
					inclusion_cinetam_master_target.cinetam_reporting_demographics_id,
					campaign_spot.package_id,
					campaign_spot.campaign_no,
					movie_history.country
from				inclusion_spot
inner join		inclusion_campaign_spot_xref on inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id and  inclusion_spot.inclusion_id = inclusion_campaign_spot_xref.inclusion_id
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
inner join		inclusion_cinetam_master_target on  inclusion_spot.inclusion_id = inclusion_cinetam_master_target.inclusion_id
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner join		cinetam_movie_complex_estimates on movie_history.movie_id = cinetam_movie_complex_estimates.movie_id 
					and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id 
					and				inclusion_cinetam_master_target.cinetam_reporting_demographics_id = cinetam_movie_complex_estimates.cinetam_reporting_demographics_id 
					and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
where			inclusion_type in (24,29,32)
group by		inclusion_spot.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,
					inclusion_cinetam_master_target.cinetam_reporting_demographics_id,
					campaign_spot.package_id,
					campaign_spot.campaign_no,
					movie_history.country
union all
select			inclusion_spot.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,
					sum(cinetam_movie_complex_estimates.attendance) as achieved_attendance,
					inclusion_cinetam_settings.cinetam_reporting_demographics_id,
					campaign_spot.package_id,
					campaign_spot.campaign_no,
					movie_history.country
from				inclusion_spot
inner join		inclusion_campaign_spot_xref on inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id and  inclusion_spot.inclusion_id = inclusion_campaign_spot_xref.inclusion_id
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
inner join		inclusion_cinetam_settings on  inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id and campaign_spot.complex_id = inclusion_cinetam_settings.complex_id
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner join		cinetam_movie_complex_estimates on movie_history.movie_id = cinetam_movie_complex_estimates.movie_id 
					and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id 
					and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_movie_complex_estimates.cinetam_reporting_demographics_id 
					and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
where			inclusion_type in (30)
group by		inclusion_spot.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,
					inclusion_cinetam_settings.cinetam_reporting_demographics_id,
					campaign_spot.package_id,
					campaign_spot.campaign_no,
					movie_history.country
union all
select			inclusion_spot.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,
					count(campaign_spot.spot_id) as achieved_attendance,
					inclusion_cinetam_settings.cinetam_reporting_demographics_id,
					campaign_spot.package_id,
					campaign_spot.campaign_no,
					movie_history.country
from				inclusion_spot
inner join		inclusion_campaign_spot_xref on inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id and  inclusion_spot.inclusion_id = inclusion_campaign_spot_xref.inclusion_id
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
inner join		inclusion_cinetam_settings on  inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id and campaign_spot.complex_id = inclusion_cinetam_settings.complex_id
inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
where			inclusion_type in (31)
group by		inclusion_spot.inclusion_id,
					movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,
					inclusion_cinetam_settings.cinetam_reporting_demographics_id,
					campaign_spot.package_id,
					campaign_spot.campaign_no,
					movie_history.country
GO
