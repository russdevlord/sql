/****** Object:  View [dbo].[v_booking_figures_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_booking_figures_detailed]
GO
/****** Object:  View [dbo].[v_booking_figures_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE	VIEW [dbo].[v_booking_figures_detailed] ( 
					figure_id,
					campaign_no,   
					product_desc, 
					rep_id,   
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
					figure_mode ) 
AS

SELECT	booking_figures.figure_id,
					booking_figures.campaign_no,
					film_campaign.product_desc,
					booking_figures.rep_id,
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
					'Team'
FROM		booking_figures,
					booking_figure_team_xref,
					film_campaign,
					sales_team,
					sales_rep,
					branch
WHERE	booking_figures.figure_id = booking_figure_team_xref.figure_id
and				booking_figures.campaign_no = film_campaign.campaign_no
and				booking_figures.branch_code = branch.branch_code
and				booking_figure_team_xref.team_id = sales_team.team_id
and				booking_figures.rep_id = sales_rep.rep_id

UNION ALL

SELECT	booking_figures.figure_id,
					booking_figures.campaign_no,
					film_campaign.product_desc,
					booking_figures.rep_id,
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
					'Sales Rep'
FROM		booking_figures,
					film_campaign,
					sales_rep,
					branch
WHERE	booking_figures.campaign_no = film_campaign.campaign_no
and				booking_figures.branch_code = branch.branch_code
and				booking_figures.rep_id = sales_rep.rep_id
GO
