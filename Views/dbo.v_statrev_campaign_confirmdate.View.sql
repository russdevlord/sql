USE [production]
GO
/****** Object:  View [dbo].[v_statrev_campaign_confirmdate]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_statrev_campaign_confirmdate] 
as  select min(confirmation_date) as confirm_date, campaign_no from statrev_campaign_revision group by campaign_no
GO
