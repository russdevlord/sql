/****** Object:  View [dbo].[v_booking_figures]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_booking_figures]
GO
/****** Object:  View [dbo].[v_booking_figures]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE	VIEW [dbo].[v_booking_figures] ( 
		figure_id,
		campaign_no,   
		rep_id,   
		branch_code,   
		team_id,   
		revision_id,   
		revision_group,   
		figure_date,   
		booking_period,   
		figure_type,   
		nett_amount,   
		figure_comment ) 
AS

SELECT	booking_figures.figure_id,
		booking_figures.campaign_no,
		booking_figures.rep_id,
		'',   
		booking_figure_team_xref.team_id, --booking_figures.team_id,
		booking_figures.revision_id,
		booking_figures.revision_group,
		booking_figures.figure_date,
		booking_figures.booking_period,
		booking_figures.figure_type,
		booking_figures.nett_amount,
		booking_figures.figure_comment
FROM	booking_figures,
		booking_figure_team_xref
WHERE	booking_figures.figure_id = booking_figure_team_xref.figure_id
UNION ALL
SELECT	booking_figures.figure_id,
		booking_figures.campaign_no,
		booking_target.rep_id,
		'',
		booking_figure_team_xref.team_id, --booking_figures.team_id,
		booking_figures.revision_id,
		booking_figures.revision_group,
		booking_figures.figure_date,
		booking_figures.booking_period,
		booking_figures.figure_type,
		booking_figures.nett_amount,
		booking_figures.figure_comment
FROM	booking_figures,
		booking_target,
		booking_figure_team_xref
WHERE	booking_figures.booking_period = booking_target.sales_period
AND		booking_figures.branch_code = booking_target.branch_code
AND		booking_figures.rep_id = booking_target.rep_id
AND		booking_figures.figure_id = booking_figure_team_xref.figure_id
UNION ALL 
SELECT	booking_figures.figure_id,
		booking_figures.campaign_no,
		0,
		booking_figures.branch_code,
		booking_figure_team_xref.team_id, --booking_figures.team_id,
		booking_figures.revision_id,
		booking_figures.revision_group,
		booking_figures.figure_date,
		booking_figures.booking_period,
		booking_figures.figure_type,
		booking_figures.nett_amount,
		booking_figures.figure_comment
FROM	booking_figures,
		booking_figure_team_xref
WHERE	booking_figures.figure_id = booking_figure_team_xref.figure_id
UNION ALL
SELECT	booking_figures.figure_id,
		booking_figures.campaign_no,
		0,
		'A',
		booking_figure_team_xref.team_id, --booking_figures.team_id,
		booking_figures.revision_id,   
		booking_figures.revision_group,
		booking_figures.figure_date,
		booking_figures.booking_period,
		booking_figures.figure_type,
		booking_figures.nett_amount,
		booking_figures.figure_comment
FROM	booking_figures,
		booking_figure_team_xref
WHERE	booking_figures.branch_code in ( 'N','V','Q','S','W')
AND		booking_figures.figure_id = booking_figure_team_xref.figure_id
GO
