/****** Object:  View [dbo].[v_statrev_campaign_confirmdate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_statrev_campaign_confirmdate]
GO
/****** Object:  View [dbo].[v_statrev_campaign_confirmdate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_statrev_campaign_confirmdate] 
as  select min(confirmation_date) as confirm_date, campaign_no from statrev_campaign_revision group by campaign_no
GO
