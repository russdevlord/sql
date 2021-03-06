/****** Object:  View [dbo].[v_spot_util_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_spot_util_spots]
GO
/****** Object:  View [dbo].[v_spot_util_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view [dbo].[v_spot_util_spots]
as
select		campaign_spot.spot_id, sum(cinema_rate / duration * 30) as cinema_rate_30sec, sum(cinema_rate) as cinema_rate, sum(campaign_spot.charge_rate) as charge_rate, sum(campaign_spot.charge_rate / duration * 30) as charge_rate_30sec 
from			campaign_spot, campaign_package
where		campaign_spot.package_id = campaign_package.package_id
group by	campaign_spot.spot_id


/*create view [dbo].[v_aaa_spot_util_liab]
as
select		campaign_spot.spot_id, sum(cinema_amount * (30 / duration)) as cinema_rate_30sec, sum(cinema_amount) as cinema_rate, sum(spot_amount) as charge_rate, sum(cinema_amount / duration * 30) as charge_rate_30sec from spot_liability, campaign_spot, campaign_package
where		liability_type in (1,5,11,14,34,38) 
and			campaign_spot.spot_id = spot_liability.spot_id
and			campaign_spot.package_id = campaign_package.package_id
group by	campaign_spot.spot_id*/

GO
