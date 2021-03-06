/****** Object:  StoredProcedure [dbo].[p_campaigns_ready_for_closure]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaigns_ready_for_closure]
GO
/****** Object:  StoredProcedure [dbo].[p_campaigns_ready_for_closure]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaigns_ready_for_closure] 		@branch_code	char(3)

as
set nocount on 
/*
 * Declare Variables
 */

declare  @campaign_no					char(7),
         @credit_status					char(1),
         @campaign_status				char(1)

/*
 * Create Temporary Table
 */

create table #campaigns
(
	campaign_no				char(7) null,
   campaign_status		char(1) null,
   status					char(1) null
)

/*
 * Insert Campaigns
 */

insert into #campaigns
select campaign_no,
       campaign_status,
       'Y'
  from slide_campaign
 where branch_code = @branch_code and
	    balance_outstanding = 0 and
       is_closed = 'N' and
		 ( campaign_status = 'C' or
			campaign_status = 'X' or
			campaign_status = 'Z' )

/*
 * Declare Cursor
 */

declare campaign_csr cursor static for
  select campaign_no,
         campaign_status
    from #campaigns
order by campaign_no
     for read only

open campaign_csr
fetch campaign_csr into @campaign_no, @campaign_status
while(@@fetch_status = 0) 
begin

	/*
    * Check Spot Status
    */

	if exists ( select 1 
                 from slide_campaign_spot
                where campaign_no = @campaign_no and (
                      (spot_status = 'L' or spot_status = 'U') OR
                      (billing_status = 'L' or billing_status = 'U') ) )
	begin
		update #campaigns
         set status = 'N'
       where campaign_no = @campaign_no
	end

	/*
	 * Check for Campaign which already have closure events.
	 */

	if exists ( select 1
		           from campaign_event
				    where campaign_no = @campaign_no and
				 	     ( event_type = 'X' or
                      event_type = 'F' ) )
	begin
		update #campaigns
         set status = 'N'
       where campaign_no = @campaign_no
	end

	/*
    * Get Credit Status
    */

	select @credit_status = credit_status
     from slide_campaign
    where campaign_no = @campaign_no

	if @credit_status <> 'B'
	begin

		/*
		 *  Check For Transactions not on a statement
		 */

		if(@campaign_status = 'Z')
		begin

			if exists ( select 1
							  from slide_transaction
							 where accounting_period is null and
									 campaign_no = @campaign_no )
			begin
				update #campaigns
					set status = 'N'
				 where campaign_no = @campaign_no
			end

		end
		else
		begin

			if exists ( select 1
							  from slide_transaction
							 where statement_id is null and
									 campaign_no = @campaign_no )
			begin
				update #campaigns
					set status = 'N'
				 where campaign_no = @campaign_no
			end

		end

	end

	/*
    * Check for Pending Figures
    */

	if exists ( select 1
                 from slide_figures
                where figure_status = 'P' and
 							 campaign_no = @campaign_no )
	begin
		update #campaigns
         set status = 'N'
       where campaign_no = @campaign_no
	end

	/*
    * Fetch Next
    */

	fetch campaign_csr into @campaign_no, @campaign_status

end
close campaign_csr
deallocate campaign_csr

/*
 * Return Result Set
 */

select campaign_no     = slide_campaign.campaign_no,
		 name_on_slide   = slide_campaign.name_on_slide,
		 start_date      = slide_campaign.start_date,
		 end_date        = dateadd(dd, ((( slide_campaign.min_campaign_period + slide_campaign.bonus_period ) * 7) - 1 ) ,slide_campaign.start_date),
		 campaign_type   = slide_campaign.campaign_type,
		 campaign_status = slide_campaign.campaign_status,
		 branch_code     = slide_campaign.branch_code
  from slide_campaign,
       #campaigns
 where #campaigns.campaign_no = slide_campaign.campaign_no and
       #campaigns.status = 'Y'

/*
 * Return
 */

return 0
GO
