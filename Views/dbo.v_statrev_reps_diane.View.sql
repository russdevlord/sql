/****** Object:  View [dbo].[v_statrev_reps_diane]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_reps_diane]
GO
/****** Object:  View [dbo].[v_statrev_reps_diane]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_statrev_reps_diane]
as
SELECT [campaign_no]
      ,[product_desc]
      ,[client_group_desc]
      ,[client_name]
      ,[agency_name]
      ,[agency_group_name]
      ,[buying_group_desc]
      ,[branch_name]
      ,[business_unit_desc]
      ,[revenue_period]
      ,[rep_name]
      ,sum([rev]) as revenue
  FROM [production].[dbo].[v_statrev_agency_week_rep] where revenue_period > '1-jul-2014'
  group by [campaign_no]
      ,[product_desc]
      ,[client_group_desc]
      ,[client_name]
      ,[agency_name]
      ,[agency_group_name]
      ,[buying_group_desc]
      ,[branch_name]
      ,[business_unit_desc]
      ,[revenue_period]
      ,[rep_name]
GO
