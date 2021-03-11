USE [production]
GO
/****** Object:  View [dbo].[v_film_campaign_avg_duration]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_film_campaign_avg_duration]
as
select campaign_package.campaign_no, avg(convert(numeric(7,2),duration)) as avg_duration from campaign_spot, campaign_package  where campaign_package.package_id = campaign_spot.package_id
group by campaign_package.campaign_no
GO
