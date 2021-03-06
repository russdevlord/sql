/****** Object:  StoredProcedure [dbo].[p_sfin_eom_campaign_close]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_campaign_close]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_campaign_close]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_eom_campaign_close] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
@campaign_no				char(7),
        @event_id						int

/*
 * Begin Transaction
 */

begin transaction

declare 	campaign_csr cursor static forward_only for
select slide_campaign.campaign_no  
  from slide_campaign,
       branch_online
 where slide_campaign.branch_code = branch_online.branch_code and
       slide_campaign.is_closed = 'Y' and
       not exists ( select 1 
                      from campaign_event
                     where campaign_event.campaign_no = slide_campaign.campaign_no and
                           campaign_event.event_type = 'F' )
order by campaign_no

open campaign_csr 
fetch campaign_csr into @campaign_no
while(@@fetch_status=0)
begin


	/*
	 * Update Slide Campaign
	 */
	
	update slide_campaign
	   set is_closed = 'Y'
	 where campaign_no = @campaign_no and
	       is_closed = 'N'
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ( 'Error : Failed to close Slide Campaign %1!', 11, 1, @campaign_no)
		return -1
	end	
	
	/*
	 * Create Financial Closure Event
	 */
	
	execute @errorode = p_get_sequence_number 'campaign_event',5,@event_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ( 'Error : Failed to close Slide Campaign %1!', 11, 1, @campaign_no)
		return -1
	end
	
	insert into campaign_event (
	       campaign_event_id,
	       campaign_no,
	       event_type,
	       event_date,
	       event_outstanding,
	       event_desc,
	       entry_date ) values (
	       @event_id,
	       @campaign_no,
	       'F',
	       @accounting_period,
	       'N',
	       'EOM - Financials Closed',
	       @accounting_period )
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error : Failed to close Slide Campaign %1!', 11, 1, @campaign_no)
		return -1
	end	

	fetch campaign_csr into @campaign_no
end

deallocate campaign_csr
/*
 * Commit and Return
 */

commit transaction
return 0
GO
