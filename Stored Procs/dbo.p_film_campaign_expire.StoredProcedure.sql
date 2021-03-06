/****** Object:  StoredProcedure [dbo].[p_film_campaign_expire]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_expire]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_expire]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_campaign_expire] @campaign_no		int,
                                   @expiry_date		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode				integer,
        @errno				integer,
        @print_id			integer,
        @event_id 			integer,
        @campaign_usage 		integer,
        @shell_usage 			integer

/*
 * Validate Expiry
 */

execute @errorode = p_film_campaign_expiry_check @campaign_no, 'Y'
if (@errorode !=0)
begin
	return -1
end	

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Expiry Event
 */

execute @errorode = p_get_sequence_number 'film_campaign_event', 5, @event_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
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
       'P',
       @expiry_date,
       'N',
       'Campaign Expired',
       getdate() )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Update Film Campaign
 */

update 	film_campaign
   set 	campaign_status = 'F', --Expired,
	   	cinelight_status = 'F',
	   	inclusion_status = 'F',
	   	outpost_status = 'F',
       	expired_date = getdate()
 where 	campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update 	campaign_package 
set 	campaign_package_status = 'F'
where 	campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update 	cinelight_package 
set 	cinelight_package_status = 'F'
where 	campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update 	outpost_package 
set 	package_status = 'F'
where 	campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update 	inclusion 
set 	inclusion_status = 'F'
where 	campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update	campaign_spot
set			spot_status = 'R'
where		spot_status in ('U','N')
and			spot_redirect is null
and			campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update	cinelight_spot
set			spot_status = 'R'
where		spot_status in ('U','N')
and			spot_redirect is null
and			campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update	outpost_spot
set			spot_status = 'R'
where		spot_status in ('U','N')
and			spot_redirect is null
and			campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update	inclusion_spot
set			spot_status = 'R'
where		spot_status in ('U','N')
and			spot_redirect is null
and			campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
