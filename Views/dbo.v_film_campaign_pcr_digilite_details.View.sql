/****** Object:  View [dbo].[v_film_campaign_pcr_digilite_details]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_campaign_pcr_digilite_details]
GO
/****** Object:  View [dbo].[v_film_campaign_pcr_digilite_details]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_film_campaign_pcr_digilite_details]
as
select 			cinelight_spot.campaign_no,
					cinelight_spot.package_id, 
					package_desc,
					package_code, 
					screening_date,
					complex_id,
					sum(cinelight_spot.charge_rate) as charge_rate_sum
from				cinelight_spot
inner join		cinelight on cinelight_spot.cinelight_id = cinelight.cinelight_id
inner join		cinelight_package on cinelight_spot.package_id = cinelight_package.package_id
where			cinelight_spot.spot_status = 'X'
and				screening_date is not null 
group by 		cinelight_spot.campaign_no,
					cinelight_spot.package_id, 
					package_desc,
					package_code, 
					screening_date,
					complex_id
GO
