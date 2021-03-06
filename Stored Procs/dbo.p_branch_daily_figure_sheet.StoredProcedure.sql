/****** Object:  StoredProcedure [dbo].[p_branch_daily_figure_sheet]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_branch_daily_figure_sheet]
GO
/****** Object:  StoredProcedure [dbo].[p_branch_daily_figure_sheet]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_branch_daily_figure_sheet] @branch_code			char(2),
                                        @sales_period			datetime
as

/*
 * Return Dataset
 */

  select slide_proposal.proposal_id,   
         slide_proposal.rep_id,   
         slide_proposal.business_group,   
         slide_proposal.branch_code,   
         slide_proposal.creation_period,   
         slide_proposal.campaign_period,   
         slide_proposal.campaign_no,   
         slide_proposal.client_name,   
         slide_proposal.proposal_date,   
         slide_proposal.comm_value,   
         slide_proposal.comm_period_value,   
         slide_proposal.contract_value,   
         slide_proposal.proposal_lost,   
         slide_proposal.proposal_comment,   
         slide_proposal.proposal_lost_date,   
         slide_proposal.sales_week,   
         sales_rep.first_name,   
         sales_rep.last_name,   
         branch.branch_name  
    from slide_proposal,   
         sales_rep,   
         branch  
   where slide_proposal.rep_id = sales_rep.rep_id and
         slide_proposal.branch_code = branch.branch_code and
         slide_proposal.branch_code = @branch_code and
         slide_proposal.creation_period = @sales_period   

/*
 * Return
 */

return 0
GO
