/****** Object:  StoredProcedure [dbo].[p_sfin_create_live_events]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_create_live_events]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_create_live_events]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_create_live_events] 	@screening_date datetime
as

/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
  		  @campaign_no					char(7),
        @prev_screen_date			datetime,
        @start_date					datetime,
		  @date_offset					integer,
        @campaign_event_id			integer,
        @campaign_type				char(1),
        @billing_cycle				tinyint

/*
 * Calculate Offset for Previos Screening Date
 */

select @date_offset = (offset - 4),
       @billing_cycle = billing_cycle
  from slide_screening_dates
 where screening_date = @screening_date

select @error = @@error
if (@error !=0)
begin
	raiserror ('Live Event Creation: Error Calculating Previous Screening Date Offset.', 16, 1)
	return -1
end	

select @prev_screen_date = screening_date
  from slide_screening_dates
 where offset = @date_offset

select @error = @@error
if (@error !=0)
begin
	raiserror ('Live Event Creation: Error Retrieving Previous Screening Date.', 16, 1)
	return -1
end	

/*
 *	Begin Transaction
 */

begin transaction

/*
 * Declare Cursors
 */ 
 
declare camp_csr cursor static for
 select campaign_no,
        start_date,
        campaign_type
   from slide_campaign
  where start_date is not null and
        billing_cycle = @billing_cycle and
        start_date <= @screening_date and
        not exists (select 1 
                     from campaign_event 
                    where campaign_event.campaign_no = slide_campaign.campaign_no and 
                          campaign_event.event_type ='V')
order by campaign_no
for read only

/*
 * Loop Campaigns
 */

open camp_csr
fetch camp_csr into @campaign_no, @start_date, @campaign_type
while (@@fetch_status = 0)
begin

	/*
    * Check Campaign Type
    */

	if((@campaign_type = 'R') or (@start_date <= @prev_screen_date))
	begin

		/*
		 * Get Sequence No for New Live Campaign Event
		 */
	
		execute @errorode = p_get_sequence_number 'campaign_event',5,@campaign_event_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			raiserror ('Error getting sequence number', 16, 1)
			goto error
		end
	
		/*
		 * Create Event
		 */
	
		insert into campaign_event (
				 campaign_event_id,
				 campaign_no,
				 event_type,
				 event_date,
				 event_outstanding,
				 event_desc,
				 event_comment,
				 entry_date ) values (
				 @campaign_event_id,
				 @campaign_no,
				 'V',
				 @start_date,
				 'N',
				 'Campaign Live',
				 null,
				 convert(datetime,convert(varchar(12),getdate(),102)) )
	
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			raiserror ('Error Creating Campaign Live Event.', 16, 1)
			goto error
		end	

	end

	/*
    * Fetch Next
    */

	fetch camp_csr into @campaign_no, @start_date, @campaign_type

end
close camp_csr
DEALLOCATE camp_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	close camp_csr
	DEALLOCATE camp_csr
	return -1
GO
