USE [production]
GO
/****** Object:  View [dbo].[p_campaign_package_avg_rate]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[p_campaign_package_avg_rate]
as
select package_id, AVG(charge_rate) as avg_rate, count(spot_id) as no_spots from campaign_spot
group by package_id
GO
