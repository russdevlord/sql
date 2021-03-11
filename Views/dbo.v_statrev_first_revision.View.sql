USE [production]
GO
/****** Object:  View [dbo].[v_statrev_first_revision]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_statrev_first_revision]
as
select campaign_no, min(confirmation_date) as confirmation_date
from statrev_campaign_revision
group by campaign_no
GO
