/****** Object:  View [dbo].[v_kraabe_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_kraabe_rev_detailed]
GO
/****** Object:  View [dbo].[v_kraabe_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_kraabe_rev_detailed]
as
select		rep_name,
			campaign_no, 
			product_desc, 
			business_unit_desc, 
			sum(cost) as rep_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 19) as qld_agency_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 231) as qld_retail_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 241) as qld_pump_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 261) as qld_cineads_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 321) as qld_direct_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period) as actual_revenue,
			v_statrev_rep.revenue_period
from		v_statrev_rep 
where		rep_id = 1915
group by	campaign_no, 
			product_desc, 
			rep_name,
			business_unit_desc, 
			v_statrev_rep.revenue_period
having		sum(cost) <> 0			


GO
