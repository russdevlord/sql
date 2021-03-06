/****** Object:  View [dbo].[v_statrev_spot_attendance]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_statrev_spot_attendance]
GO
/****** Object:  View [dbo].[v_statrev_spot_attendance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_statrev_spot_attendance] 
as
select 			film_campaign.campaign_no, 
					film_campaign.product_desc,
					branch_name, 
					branch.branch_code,
					branch.country_code,
					business_unit_desc,
					business_unit.business_unit_id,
					client_name,
					client_product_desc,
					agency_name,
					agency_group_name,
					buying_group_desc,
					revenue_period,
					sum(rev) as revenue,
					(select count(spot_id) from campaign_spot, film_screening_date_xref where campaign_spot.screening_date = film_screening_date_xref.screening_date and campaign_spot.campaign_no = film_campaign.campaign_no and film_screening_date_xref.benchmark_end = temp_statrev.revenue_period) as no_spots,
					(select sum(attendance) from attendance_campaign_actuals, film_screening_date_xref where  attendance_campaign_actuals.screening_date = film_screening_date_xref.screening_date and film_screening_date_xref.benchmark_end = temp_statrev.revenue_period and attendance_campaign_actuals.campaign_no = film_campaign.campaign_no) as attendance
from 			film_campaign, 
					branch,
					business_unit,
					client,
					client_product,
					agency,
					agency_groups,
					agency_buying_groups,
					(select	campaign_no, revenue_period, sum(cost) as rev
					from		statrev_cinema_normal_transaction,  statrev_campaign_revision
					where		statrev_cinema_normal_transaction.revision_id = statrev_campaign_revision.revision_id 
					and			revenue_period > '1-jan-2015'		
					group by campaign_no, revenue_period) as temp_statrev
where			film_campaign.branch_code = branch.branch_code
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.agency_id = agency.agency_id
and				agency.agency_group_id = agency_groups.agency_group_id
and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and				film_campaign.client_id = client.client_id
and				film_campaign.client_product_id = client_product.client_product_id
and				temp_statrev.campaign_no = film_campaign.campaign_no
group by 	film_campaign.campaign_no, 
					film_campaign.product_desc,
					branch_name, branch.branch_code,branch.country_code,
					business_unit_desc,
					business_unit.business_unit_id,
					client_name,
					client_product_desc,
					agency_name,
					agency_group_name,
					buying_group_desc,
					revenue_period
GO
