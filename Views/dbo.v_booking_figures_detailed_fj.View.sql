/****** Object:  View [dbo].[v_booking_figures_detailed_fj]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_booking_figures_detailed_fj]
GO
/****** Object:  View [dbo].[v_booking_figures_detailed_fj]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE	VIEW [dbo].[v_booking_figures_detailed_fj] ( 
					figure_id,
					campaign_no,   
					product_desc, 
					rep_id,   
					client_group_desc,
					client_name,
					agency_name,
					agency_group_name,
					branch_code,   
					branch_name, 
					team_id,   
					revision_id,   
					revision_group,   
					figure_date,   
					booking_period,   
					figure_type,   
					nett_amount,   
					figure_comment,
					team_name, 
					rep_name,
					figure_mode,
					Country_code,
					buying_group_description,
					cal_year, 
					cal_qtr,
					fin_year,
					fin_qtr,
					cal_half,
					fin_half) 
AS

SELECT	DISTINCT booking_figures.figure_id,
					CAST(booking_figures.campaign_no AS varchar) campaign_no,
					film_campaign.product_desc,
					booking_figures.rep_id,
					client_group.client_group_desc,
					client.client_name,
					agency.agency_name,
					agency_groups.agency_group_name,
					booking_figures.branch_code, 
					branch.branch_name,   
					booking_figure_team_xref.team_id, --booking_figures.team_id,
					booking_figures.revision_id,
					booking_figures.revision_group,
					booking_figures.figure_date,
					booking_figures.booking_period,
					booking_figures.figure_type,
					booking_figures.nett_amount,
					booking_figures.figure_comment,
					sales_team.team_name,
					sales_rep.first_name + ' ' + sales_rep.last_name,
					'Team',
					branch.country_code,
					agency_buying_groups.buying_group_desc,
					year(booking_figures.booking_period) as cal_year, 
					case month(booking_figures.booking_period) 
when 1 then 'Q1' 
when 2 then 'Q1'
when 3 then 'Q1'
when 4 then 'Q2' 
when 5 then 'Q2' 
when 6 then 'Q2' 
when 7 then 'Q3' 
when 8 then 'Q3' 
when 9 then 'Q3' 
when 10 then 'Q4'
when 11 then 'Q4'
when 12 then 'Q4' end as cal_qtr,
case month(booking_figures.booking_period) 
when 1 then year(booking_figures.booking_period)
when 2 then year(booking_figures.booking_period)
when 3 then year(booking_figures.booking_period)
when 4 then year(booking_figures.booking_period)
when 5 then year(booking_figures.booking_period)
when 6 then year(booking_figures.booking_period)
when 7 then year(booking_figures.booking_period) + 1 
when 8 then year(booking_figures.booking_period) + 1
when 9 then year(booking_figures.booking_period)  + 1
when 10 then year(booking_figures.booking_period) + 1
when 11 then year(booking_figures.booking_period) + 1
when 12 then year(booking_figures.booking_period) + 1 end as fin_year,
case month(booking_figures.booking_period) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as fin_qtr,
case month(booking_figures.booking_period) 
when 1 then 'H1' 
when 2 then 'H1'
when 3 then 'H1'
when 4 then 'H1' 
when 5 then 'H1' 
when 6 then 'H1' 
when 7 then 'H2' 
when 8 then 'H2' 
when 9 then 'H2' 
when 10 then 'H2'
when 11 then 'H2'
when 12 then 'H2' end as cal_half,
case month(booking_figures.booking_period) 
when 1 then 'H2' 
when 2 then 'H2'
when 3 then 'H2'
when 4 then 'H2' 
when 5 then 'H2' 
when 6 then 'H2' 
when 7 then 'H1' 
when 8 then 'H1' 
when 9 then 'H1' 
when 10 then 'H1'
when 11 then 'H1'
when 12 then 'H1' end as fin_half
FROM		booking_figures,
					booking_figure_team_xref,
					film_campaign,
					sales_team,
					sales_rep,
					business_unit,
					client,
					client_group,
					agency,
					agency_buying_groups,
					agency_groups,
					branch
WHERE	booking_figures.figure_id = booking_figure_team_xref.figure_id
and				booking_figures.campaign_no = film_campaign.campaign_no
and				booking_figures.branch_code = branch.branch_code
and				booking_figure_team_xref.team_id = sales_team.team_id
and				booking_figures.rep_id = sales_rep.rep_id
and		client.client_group_id = client_group.client_group_id
and		client.client_id = film_campaign.client_id
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and		booking_figures.booking_period >= '2012-07-31'

UNION ALL

SELECT	DISTINCT booking_figures.figure_id,
					CAST(booking_figures.campaign_no AS varchar) campaign_no,
					film_campaign.product_desc,
					booking_figures.rep_id,
					client_group.client_group_desc,
					client.client_name,
					agency.agency_name,
					agency_groups.agency_group_name,
					booking_figures.branch_code, 
					branch.branch_name,   
					null,
					booking_figures.revision_id,
					booking_figures.revision_group,
					booking_figures.figure_date,
					booking_figures.booking_period,
					booking_figures.figure_type,
					booking_figures.nett_amount,
					booking_figures.figure_comment,
					null,
					sales_rep.first_name + ' ' + sales_rep.last_name,
					'Sales Rep',
					branch.country_code,
					agency_buying_groups.buying_group_desc,
					year(booking_figures.booking_period) as cal_year, 
					case month(booking_figures.booking_period) 
when 1 then 'Q1' 
when 2 then 'Q1'
when 3 then 'Q1'
when 4 then 'Q2' 
when 5 then 'Q2' 
when 6 then 'Q2' 
when 7 then 'Q3' 
when 8 then 'Q3' 
when 9 then 'Q3' 
when 10 then 'Q4'
when 11 then 'Q4'
when 12 then 'Q4' end as cal_qtr,
case month(booking_figures.booking_period) 
when 1 then year(booking_figures.booking_period)
when 2 then year(booking_figures.booking_period)
when 3 then year(booking_figures.booking_period)
when 4 then year(booking_figures.booking_period)
when 5 then year(booking_figures.booking_period)
when 6 then year(booking_figures.booking_period)
when 7 then year(booking_figures.booking_period) + 1 
when 8 then year(booking_figures.booking_period) + 1
when 9 then year(booking_figures.booking_period)  + 1
when 10 then year(booking_figures.booking_period) + 1
when 11 then year(booking_figures.booking_period) + 1
when 12 then year(booking_figures.booking_period) + 1 end as fin_year,
case month(booking_figures.booking_period) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as fin_qtr,
case month(booking_figures.booking_period) 
when 1 then 'H1' 
when 2 then 'H1'
when 3 then 'H1'
when 4 then 'H1' 
when 5 then 'H1' 
when 6 then 'H1' 
when 7 then 'H2' 
when 8 then 'H2' 
when 9 then 'H2' 
when 10 then 'H2'
when 11 then 'H2'
when 12 then 'H2' end as cal_half,
case month(booking_figures.booking_period) 
when 1 then 'H2' 
when 2 then 'H2'
when 3 then 'H2'
when 4 then 'H2' 
when 5 then 'H2' 
when 6 then 'H2' 
when 7 then 'H1' 
when 8 then 'H1' 
when 9 then 'H1' 
when 10 then 'H1'
when 11 then 'H1'
when 12 then 'H1' end as fin_half
FROM		booking_figures,
					film_campaign,
					sales_rep,
					branch,
					client,
					client_group,
					agency,
					agency_buying_groups,
					agency_groups
WHERE	booking_figures.campaign_no = film_campaign.campaign_no
and				booking_figures.branch_code = branch.branch_code
and				booking_figures.rep_id = sales_rep.rep_id
and		client.client_group_id = client_group.client_group_id
and		client.client_id = film_campaign.client_id
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and		booking_figures.booking_period >= '2012-07-31'



GO
