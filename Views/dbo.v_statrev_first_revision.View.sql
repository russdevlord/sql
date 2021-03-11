/****** Object:  View [dbo].[v_statrev_first_revision]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_first_revision]
GO
/****** Object:  View [dbo].[v_statrev_first_revision]    Script Date: 12/03/2021 10:03:48 AM ******/
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
