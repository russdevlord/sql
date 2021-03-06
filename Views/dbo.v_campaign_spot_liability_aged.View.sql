/****** Object:  View [dbo].[v_campaign_spot_liability_aged]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_spot_liability_aged]
GO
/****** Object:  View [dbo].[v_campaign_spot_liability_aged]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_campaign_spot_liability_aged]
as
select			'Onscreen' as liability_source, 
				campaign_spot.campaign_no,
				sl.spot_id,
				sl.complex_id,
				campaign_package.revenue_source,
				sum(sl.spot_amount) as spot_amount_sum,
				sum(sl.cinema_amount) as cinema_amount_sum,
				(select min(creation_period) from spot_liability where spot_liability.spot_id = sl.spot_id) as creation_period
from			spot_liability sl
inner join 		campaign_spot on sl.spot_id = campaign_spot.spot_id
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
group by 		campaign_spot.campaign_no, 
				sl.complex_id,
				campaign_package.revenue_source,
				sl.spot_id						
union
select			'Digilite' as liability_source, 
				cinelight_spot.campaign_no,
				sl.spot_id,
				sl.complex_id,
				cinelight_package.revenue_source,
				sum(sl.spot_amount) as spot_amount_sum,
				sum(sl.cinema_amount) as cinema_amount_sum,
				(select min(creation_period) from cinelight_spot_liability where cinelight_spot_liability.spot_id = sl.spot_id) as creation_period
from			cinelight_spot_liability sl
inner join		cinelight_spot on sl.spot_id = cinelight_spot.spot_id
inner join		cinelight_package on cinelight_spot.package_id = cinelight_package.package_id
group by		cinelight_spot.campaign_no, 
				sl.complex_id,
				cinelight_package.revenue_source,
				sl.spot_id				
union
select			'CineMarketing' as liability_source, 
				inclusion_spot.campaign_no, 
				sl.spot_id,
				sl.complex_id,
				'I',
				sum(sl.spot_amount) as spot_amount_sum, 
				sum(sl.cinema_amount) as cinema_amount_sum, 
				(select min(creation_period) from cinelight_spot_liability where cinelight_spot_liability.spot_id = sl.spot_id) as creation_period
from			inclusion_spot_liability sl
inner join		inclusion_spot ON sl.spot_id = inclusion_spot.spot_id
group by		inclusion_spot.campaign_no, 
				sl.complex_id,
				sl.spot_id					
GO
