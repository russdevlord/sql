/****** Object:  View [dbo].[v_kclaude_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_kclaude_rev_detailed]
GO
/****** Object:  View [dbo].[v_kclaude_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_kclaude_rev_detailed]
as
select		rep_name,
			campaign_no, 
			product_desc, 
			business_unit_desc, 
			sum(cost) as rep_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 20) as sa_agency_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 301) as sa_cineads_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 22) as wa_agency_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 191) as wa_cineads_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period) as actual_revenue,
			v_statrev_rep.revenue_period
from		v_statrev_rep 
where		rep_id = 1865
group by	campaign_no, 
			product_desc, 
			rep_name,
			business_unit_desc, 
			v_statrev_rep.revenue_period
having		sum(cost) <> 0			


GO
