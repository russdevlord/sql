USE [production]
GO
/****** Object:  View [dbo].[v_campaign_onscreen_weeks_Package]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_campaign_onscreen_weeks_Package]
as
select screening_date, a.campaign_no, a.package_id, b.package_code
from campaign_spot a
LEFT JOIN Campaign_package b
ON a.package_id = b.package_id
AND a.campaign_no = b.Campaign_no
where spot_status = 'X'
group by  screening_date, a.campaign_no,a.package_ID, b.package_code

GO
