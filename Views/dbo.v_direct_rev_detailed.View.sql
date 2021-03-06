/****** Object:  View [dbo].[v_direct_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_direct_rev_detailed]
GO
/****** Object:  View [dbo].[v_direct_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_direct_rev_detailed]
as
select		rep_name,
			campaign_no, 
			product_desc,  
			revenue_period,
			sum(cost) as rep_revenue, 
			(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 23) as direct_team_revenue, 
			(select isnull(sum(cost),0) from v_statrev where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period) as actual_revenue
from		v_statrev_rep 
where		branch_code <> 'Q' 
and			revenue_period > '1-jul-2015' 
and			(business_unit_desc like '%Direct%' or business_unit_desc like '%Showcase%')
group by	campaign_no, 
			product_desc, 
			revenue_period,
			rep_name
having		sum(cost) <> 0			

GO
