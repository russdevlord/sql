/****** Object:  View [dbo].[v_nsw_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_nsw_rev_detailed]
GO
/****** Object:  View [dbo].[v_nsw_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_nsw_rev_detailed]
as
select		rep_name,
			campaign_no, 
			product_desc,  
			sum(cost) as rep_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 131) as jack_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 141) as liam_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 281) as laura_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 17) as nsw_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period) as actual_revenue,
			v_statrev_rep.revenue_period
from		v_statrev_rep 
where		branch_code = 'N' 
and			revenue_period > '1-jul-2015' 
and			business_unit_desc like '%Agency%'
group by	campaign_no, 
			product_desc, 
			rep_name,
			v_statrev_rep.revenue_period
having		sum(cost) <> 0			



GO
