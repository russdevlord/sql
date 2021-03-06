/****** Object:  View [dbo].[v_commencement_spots_all]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_commencement_spots_all]
GO
/****** Object:  View [dbo].[v_commencement_spots_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_commencement_spots_all]
as
select 		film_campaign.campaign_no,
			screening_date,
			complex_id,
			package_id
from 		film_campaign,
			campaign_spot
where 		film_campaign.campaign_no = campaign_spot.campaign_no
group by 	film_campaign.campaign_no,
			screening_date,
			complex_id,
			package_id
union all
select 		film_campaign.campaign_no,
			inclusion_spot.screening_date,
			inclusion_cinetam_settings.complex_id,
			inclusion_cinetam_package.package_id
from 		film_campaign,
			inclusion,
			inclusion_spot,
			inclusion_cinetam_settings,
			inclusion_cinetam_package
where 		film_campaign.campaign_no = inclusion.campaign_no
and			film_campaign.campaign_no = inclusion_spot.campaign_no
and			inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion.campaign_no = inclusion_spot.campaign_no
and			inclusion_type in (24,29,30,31,32)
and			inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
and			inclusion_cinetam_package.inclusion_id = inclusion.inclusion_id
group by	film_campaign.campaign_no,
			inclusion_spot.screening_date,
			inclusion_cinetam_settings.complex_id,
			inclusion_cinetam_package.package_id

GO
