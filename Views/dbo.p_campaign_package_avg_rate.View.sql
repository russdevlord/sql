/****** Object:  View [dbo].[p_campaign_package_avg_rate]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[p_campaign_package_avg_rate]
GO
/****** Object:  View [dbo].[p_campaign_package_avg_rate]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[p_campaign_package_avg_rate]
as
select package_id, AVG(charge_rate) as avg_rate, count(spot_id) as no_spots from campaign_spot
group by package_id
GO
