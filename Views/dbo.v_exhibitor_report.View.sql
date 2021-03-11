USE [production]
GO
/****** Object:  View [dbo].[v_exhibitor_report]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_exhibitor_report]
as
select	exhibitor_id as exhibitor_group_id, exhibitor_id as exhibitor_id, exhibitor_name from exhibitor
union all
select	-100, 129, 'EVENT Combined'
union all
select	-100, 156, 'EVENT Combined'
GO
