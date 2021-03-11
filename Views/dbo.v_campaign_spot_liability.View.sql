USE [production]
GO
/****** Object:  View [dbo].[v_campaign_spot_liability]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_campaign_spot_liability]
as
SELECT		'Onscreen' as liability_source, 
			campaign_spot.campaign_no, 
			sum(spot_liability.spot_amount) as spot_amount, 
			spot_liability.liability_type
FROM        spot_liability INNER JOIN
				campaign_spot ON spot_liability.spot_id = campaign_spot.spot_id
group by 	campaign_spot.campaign_no, 
			spot_liability.liability_type						
union
SELECT		'Digilite' as liability_source, 
			cinelight_spot.campaign_no, 
			sum(cinelight_spot_liability.spot_amount) as spot_amount, 
			cinelight_spot_liability.liability_type
FROM        cinelight_spot_liability INNER JOIN
				cinelight_spot ON cinelight_spot_liability.spot_id = cinelight_spot.spot_id
group by	cinelight_spot.campaign_no, 
			cinelight_spot_liability.liability_type				
union
SELECT		'CineMarketing' as liability_source, 
			inclusion_spot.campaign_no, 
			sum(inclusion_spot_liability.spot_amount) as spot_amount, 
			inclusion_spot_liability.liability_type
FROM        inclusion_spot_liability INNER JOIN
				inclusion_spot ON inclusion_spot_liability.spot_id = inclusion_spot.spot_id
group by	inclusion_spot.campaign_no, 
			inclusion_spot_liability.liability_type					
GO
