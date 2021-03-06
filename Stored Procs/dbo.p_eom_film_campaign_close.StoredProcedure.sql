/****** Object:  StoredProcedure [dbo].[p_eom_film_campaign_close]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_campaign_close]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_campaign_close]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_film_campaign_close] @campaign_no				int,
                                      @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			int,
        @rowcount     			int,
        @errorode					int,
        @errno					int,
        @print_id				int,
        @event_id 				int,
        @campaign_usage 		int,
        @shell_usage 			int,
        @found					tinyint


 
/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Closure Event
 */

execute @errorode = p_get_sequence_number 'film_campaign_event', 5, @event_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to get sequence no.', 16, 1)
	return -1
end

insert into film_campaign_event (
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
	raiserror ('Error : Failed to create close event.', 16, 1)
	return -1
end	

/*
 * Update Certificate Items
 */

update certificate_item
   set campaign_summary = 'Y'
  from campaign_spot spot
 where spot.campaign_no = @campaign_no and
	   spot.spot_id = certificate_item.spot_reference

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update certificate items.', 16, 1)
	return -1
end	

/*
 * Remove Campaign Patterns
 */

delete film_campaign_pattern
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to delete film campaign patterns.', 16, 1)
	return -1
end	

/*
 * Remove Campaign Patterns
 */

delete cinelight_pattern
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to delete cinelight patterns.', 16, 1)
	return -1
end	

/*
 * Remove Campaign Patterns
 */

delete inclusion_pattern
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to delete cinelight patterns.', 16, 1)
	return -1
end	

/*
 * Remove Campaign Partitions
 */

delete film_campaign_partition
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to delete film campaigns partitions.', 16, 1)
	return -1
end	

/*
 * Remove Plan Dates
 */

delete film_plan_dates 
  from film_plan
 where film_plan.campaign_no = @campaign_no and
	    film_plan.film_plan_id = film_plan_dates.film_plan_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to delete film plan dates.', 16, 1)
	return -1
end	

/*
 * Remove Plan Complexes
 */

delete film_plan_complex 
  from film_plan
 where film_plan.campaign_no = @campaign_no and
	    film_plan.film_plan_id = film_plan_complex.film_plan_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to delete film plan complexes.', 16, 1)
	return -1
end


/*
 * Declare Cursors
 */

 declare print_csr cursor static for
  select distinct print_id
    from film_campaign_prints
   where campaign_no = @campaign_no
order by print_id
     for read only

/*
 * Deactivate Campaign Prints
 */

open print_csr
fetch print_csr into @print_id
while(@@fetch_status = 0)
begin

	select @campaign_usage = 0,
          @shell_usage = 0,
          @found = 0

	/*
    * Check Other Campaigns
    */

	select @campaign_usage = isnull(count(fcp.print_id),0)
     from film_campaign_prints fcp,
          film_campaign fc
    where fcp.print_id = @print_id and
          fcp.campaign_no = fc.campaign_no and
          fc.campaign_no <> @campaign_no and
          fc.campaign_status in ('P','L','F')

	if(@campaign_usage > 0)
		select @found = 1

	/*
    * Check Shell Usage
    */

	if(@found = 0)
	begin

		select @shell_usage = isnull(count(fsp.print_id),0)
		  from film_shell_print fsp,
				 film_shell fs
		 where fsp.print_id = @print_id and
             fsp.shell_code = fs.shell_code and
				 fs.shell_expired = 'N'

		if(@shell_usage = 0)
		begin
			
			update film_print
				set print_status = 'E'
			 where print_id = @print_id
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				raiserror ('Error : Failed to update film print.', 16, 1)
				close print_csr
				return -1
			end	
	
		end

	end

	/*
	 * Consolidate Print Transactions
	 */

	execute @errorode = p_eom_film_print_consolidation @campaign_no, @print_id, @accounting_period
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Error : Failed to delete film_spot_xref.', 16, 1)
		close print_csr
		return -1
	end	

	/*
    * Fetch Next
    */

	fetch print_csr into @print_id

end
close print_csr
deallocate print_csr

/*
 * Declare Cinelight Print Cursor
 */

 declare print_csr cursor static for
  select distinct print_id
    from cinelight_campaign_print
   where campaign_no = @campaign_no
order by print_id
     for read only

/*
 * Deactivate Campaign Prints
 */

open print_csr
fetch print_csr into @print_id
while(@@fetch_status = 0)
begin

	select @campaign_usage = 0,
          @shell_usage = 0,
          @found = 0

	/*
    * Check Other Campaigns
    */

	select @campaign_usage = isnull(count(fcp.print_id),0)
     from cinelight_campaign_print fcp,
          film_campaign fc
    where fcp.print_id = @print_id and
          fcp.campaign_no = fc.campaign_no and
          fc.campaign_no <> @campaign_no and
          fc.campaign_status in ('P','L','F')

	if(@campaign_usage > 0)
		select @found = 1

	/*
    * Check Shell Usage
    */

	if(@found = 0)
	begin

		update cinelight_print
			set print_status = 'E'
		 where print_id = @print_id

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			raiserror ('Error : Failed to update cinelight print.', 16, 1)
			close print_csr
			return -1
		end	
	end

	/*
	 * Consolidate Print Transactions
	 */

	execute @errorode = p_eom_cinelight_print_consolidation @campaign_no, @print_id, @accounting_period
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Error : Failed to delete film_spot_xref.', 16, 1)
		close print_csr
		return -1
	end	

	/*
    * Fetch Next
    */

	fetch print_csr into @print_id

end
close print_csr
deallocate print_csr

/*
 * Update Close Date
 */

update film_campaign
   set closed_date = getdate()
 where campaign_no = @campaign_no 

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update film campagn.', 16, 1)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
