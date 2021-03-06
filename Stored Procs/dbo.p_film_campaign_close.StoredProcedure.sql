/****** Object:  StoredProcedure [dbo].[p_film_campaign_close]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_close]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_close]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_film_campaign_close] @campaign_no		int,
                                  @close_date		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode					integer,
        @errno					integer,
        @print_id				integer,
        @event_id 				integer,
        @campaign_usage 		integer,
        @shell_usage 			integer,
        @released_value			money,
        @calculated_value		money,
		@spot_value				money,
		@average_rate			money,
		@no_spots				integer,
		@package_id				integer, 
		@campaign_expiry_idc	char(1)

/*
 * Validate Closure
 */

execute @errorode = p_film_campaign_close_check @campaign_no, 'Y'
if (@errorode !=0)
begin
	raiserror ('Close Campaign Error: Close Check Failed', 16, 1)
	return -1
end	

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
	raiserror ('Close Campaign Error: Failed to get seq no', 16, 1)
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
       'X',
       @close_date,
       'N',
       'Campaign Closed',
       getdate() )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error: Failed to insert close event', 16, 1)
	return -1
end	

/*
 * Get Expiry Indicator and archive campaign if not already done
 */

select @campaign_expiry_idc = campaign_expiry_idc
  from film_campaign
 where campaign_no = @campaign_no

if @campaign_expiry_idc = 'N'
begin

	/*
	 * Create Movie Archive
	 */

	execute @errorode = p_arc_film_campaign_movie @campaign_no
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Close Campaign Error: Failed to archive movie allocations', 16, 1)
		return -1
	end
	
	/*
	 * Update Film Campaign Packages - Set the average rate and spot count
	 */
	
	execute @errorode = p_arc_film_campaign_avg_rates @campaign_no
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Close Campaign Error: Failed to archive average rates', 16, 1)
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
		raiserror ('Close Campaign Error: Failed to update certificate summary', 16, 1)
		return -1
	end	

end

exec @errorode = p_statrev_revision_generate @campaign_no, 0, 1
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error: Failed to generate closing Statutory Revision', 16, 1)
	return -1
end

/*
 * Update Film Campaign
 */

update film_campaign
   set campaign_status = 'X', --Closed
	   cinelight_status = 'X',
	   inclusion_status = 'X',
	 	outpost_status = 'X'
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error: Failed to Update Film Campaign to Closed', 16, 1)
	return -1
end	

/*
 * Update Film Figure Status
 */

 update film_figures
	 set figure_status = 'X' 
  where campaign_no = @campaign_no and
		  figure_status = 'P'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error', 16, 1)
	return -1
end	

update campaign_package 
set campaign_package_status = 'X'
where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error', 16, 1)
	return -1
end	

update cinelight_package 
set cinelight_package_status = 'X'
where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error', 16, 1)
	return -1
end	

update outpost_package 
set package_status = 'X'
where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error', 16, 1)
	return -1
end	

update inclusion 
set inclusion_status = 'X'
where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Close Campaign Error', 16, 1)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
