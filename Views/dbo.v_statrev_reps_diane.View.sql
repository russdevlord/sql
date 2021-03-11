USE [production]
GO
/****** Object:  View [dbo].[v_statrev_reps_diane]    Script Date: 11/03/2021 2:30:32 PM ******/
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
