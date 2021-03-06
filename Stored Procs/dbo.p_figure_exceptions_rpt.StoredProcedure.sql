/****** Object:  StoredProcedure [dbo].[p_figure_exceptions_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_figure_exceptions_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_figure_exceptions_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_figure_exceptions_rpt] @branch_code		char(2),
                                    @sales_period		datetime
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @figure_id					int,
        @campaign_no					char(7)

/*
 * Create Temporary Table
 */

create table #includes
(
	figure_id		int			null
)

/*
 * Declare Cursor
 */

 declare figs_csr cursor static for
  select slide_figures.figure_id,
         slide_figures.campaign_no
    from slide_figures
   where slide_figures.release_period = @sales_period and
         slide_figures.branch_code = @branch_code and
         slide_figures.figure_status = 'R' and --Released
         slide_figures.figure_type = 'N' and --New Figures
         slide_figures.figure_hold = 'N' --Not on Hold
order by slide_figures.figure_id
     for read only

/*
 * Loop Cursor
 */

open figs_csr
fetch figs_csr into @figure_id, @campaign_no
while (@@fetch_status = 0)
begin

	/*
    * Check for Exceptions
    */

   execute @errorode = p_figure_exceptions_check @campaign_no, 0
   if(@errorode < 0)
	begin
		close figs_cursor
	   return -1
	end
	else
		if(@errorode = 1)
			insert into #includes values (@figure_id)
	
	/*
    * Fetch Next
    */

	fetch figs_csr into @figure_id, @campaign_no

end
close figs_csr

/*
 * Return Dataset
 */

  select slide_figures.figure_id,
         slide_figures.campaign_no,
         slide_figures.branch_code,
         slide_figures.rep_id,
         slide_figures.business_group,
         slide_figures.team_id,
			slide_figures.area_id,
			slide_figures.region_id,
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
         'A'
    from slide_figures,
         slide_campaign,
         sales_rep,
         sales_period,
         #includes
   where slide_figures.campaign_no = slide_campaign.campaign_no and
         slide_figures.rep_id = sales_rep.rep_id and
         sales_period.sales_period_end = @sales_period and
         slide_figures.branch_code = @branch_code and
         slide_figures.figure_id = #includes.figure_id

/*
 * Return Success
 */
deallocate figs_csr

return 0
GO
