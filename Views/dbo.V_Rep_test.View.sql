/****** Object:  View [dbo].[V_Rep_test]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[V_Rep_test]
GO
/****** Object:  View [dbo].[V_Rep_test]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[V_Rep_test] AS
select distinct Revenue_period, Team_ID, Rep_ID from v_Tableau_Team_Rep_figures
Where mode = 'Team'
and YEAR(Revenue_period) > 2011
GO
