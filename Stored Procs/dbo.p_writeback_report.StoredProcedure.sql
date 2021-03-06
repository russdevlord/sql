/****** Object:  StoredProcedure [dbo].[p_writeback_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_writeback_report]
GO
/****** Object:  StoredProcedure [dbo].[p_writeback_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_writeback_report] @sales_period	datetime
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer

/*
 * Select Figures
 */

select slide_figures.figure_id,
       slide_figures.campaign_no,
       slide_figures.branch_code,
       slide_figures.rep_id,
       slide_figures.business_group,
       slide_figures.team_id,
       slide_figures.origin_period,
       slide_figures.creation_period,
       slide_figures.release_period,
       slide_figures.figure_type,
       slide_figures.figure_status,
       slide_figures.gross_amount,
       slide_figures.nett_amount,
       slide_figures.comm_amount,
       slide_figures.release_value,
       slide_figures.re_coupe_value,
       slide_figures.branch_hold,
       slide_figures.ho_hold,
       slide_figures.figure_hold,
       slide_figures.figure_reason,
       slide_figures.figure_official,
       slide_campaign.name_on_slide,
       slide_campaign.branch_release,
       slide_campaign.npu_release,
       slide_campaign.ho_release,
       slide_campaign.campaign_release,
       slide_campaign.nett_contract_value,
       sales_rep.first_name,
       sales_rep.last_name,
       sales_period.sales_period_end,
       sales_period.sales_period_no,
       sales_period.status,
		 slide_figures.area_id,
		slide_figures.region_id
  from slide_figures,
       slide_campaign,
       sales_rep,
       sales_period
 where slide_figures.campaign_no = slide_campaign.campaign_no and
       slide_figures.rep_id = sales_rep.rep_id and
       sales_period.sales_period_end = @sales_period and
       slide_figures.figure_type = 'W' and
       ( slide_figures.release_period = sales_period.sales_period_end or
         ( slide_figures.creation_period <= sales_period.sales_period_end and
           slide_figures.release_period > sales_period.sales_period_end ) )

/*
 * Return
 */

return 0
GO
