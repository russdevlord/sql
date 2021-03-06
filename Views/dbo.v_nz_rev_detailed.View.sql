/****** Object:  View [dbo].[v_nz_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_nz_rev_detailed]
GO
/****** Object:  View [dbo].[v_nz_rev_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_nz_rev_detailed]
as
select		rep_name,
				campaign_no, 
				product_desc,  
				business_unit_desc,
				revenue_period,
				sum(cost) as rep_revenue, 
				(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 24) as nz_agency_team, 
				(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period and team_id = 25) as nz_direct_team, 
				(select isnull(sum(cost),0) from v_statrev_team where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period  and team_id = 392) as nz_cineads_team, 
				(select isnull(sum(cost),0) from v_statrev where campaign_no = v_statrev_rep.campaign_no and revenue_period = v_statrev_rep.revenue_period) as actual_revenue
from			v_statrev_rep 
where		branch_code = 'Z' 
and			revenue_period > '1-jan-2017' 
and			business_unit_desc <> 'Tower TV'
group by	campaign_no, 
				product_desc, 
				rep_name,
				revenue_period,
				business_unit_desc
having		sum(cost) <> 0			
GO
