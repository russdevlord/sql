/****** Object:  StoredProcedure [dbo].[p_film_campaign_unconfirm]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_unconfirm]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_unconfirm]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_film_campaign_unconfirm] @campaign_no		integer
as

/*
 * Declare Variables
 */

declare @error   						integer,
        @errorode							integer,
        @count							integer,
        @rowcount						integer,
        @event_id						integer,
        @campaign_status				char(1),
        @cinelight_status				char(1),
        @inclusion_status				char(1),
        @temp                          	varchar(100),
		@outpost_status					char(1)
 
/*
 * Get Campaign Information
 */

select 	@campaign_status = campaign_status,
		@inclusion_status = inclusion_status,
		@cinelight_status = cinelight_status,
		@outpost_status = outpost_status
from 	film_campaign
where 	campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0 or @rowcount != 1)
begin
	raiserror ('Film Unconfirmation - Failure to Retrieve Campaign Information.', 16, 1)
   return -1
end

/*
 * Ensure Campaign is Live
 */

if (@campaign_status <> 'L' and @campaign_status <> 'P') and (@cinelight_status <> 'L' and @cinelight_status <> 'P') and (@inclusion_status <> 'L' and @inclusion_status <> 'P') and (@outpost_status <> 'L' and @outpost_status <> 'P') 
begin
	raiserror ('Film Unconfirmation - Campaign must have all status values set to "Live" or "Proposed" before it can be unconfirmed.', 16, 1)
   	return -1
end

/*
 * Ensure all Spots are Active
 */

select @count = count(spot_id)
  from campaign_spot
where	(spot_status <> 'A'
and      spot_status <> 'P')
and       campaign_no = @campaign_no

select 	@count = @count + count(spot_id)
from 	cinelight_spot
where	(spot_status <> 'A'
and      spot_status <> 'P')
and     campaign_no = @campaign_no

select 	@count = @count + count(spot_id)
from 	inclusion_spot
where	(spot_status <> 'A'
and      spot_status <> 'P')
and     campaign_no = @campaign_no

select 	@count = @count + count(spot_id)
from 	outpost_spot
where	(spot_status <> 'A'
and      spot_status <> 'P')
and     campaign_no = @campaign_no


if(@count > 0)
begin
	raiserror ('Film unconfirmation - All spots must be active or proposed to unconfirm a campaign.', 16, 1)
   return -1
end

/*
 * Ensure Campaign has not billed
 */

select @count = count(spot_id)
  from campaign_spot
 where tran_id is not null and
	   campaign_no = @campaign_no

select @count = @count + count(spot_id)
  from cinelight_spot
 where tran_id is not null and
	   campaign_no = @campaign_no

select @count = @count + count(spot_id)
  from inclusion_spot
 where tran_id is not null and
	   campaign_no = @campaign_no

select @count = @count + count(spot_id)
  from inclusion_spot
 where tran_id is not null and
	   campaign_no = @campaign_no

select @count = @count + count(inclusion_id)
  from inclusion
 where tran_id is not null and
	   campaign_no = @campaign_no
	   
select		@count = @count + count(tran_id)
from		campaign_transaction
where		campaign_no = @campaign_no			   

if(@count > 0)
begin
	raiserror ('Film unconfirmation - Campaign has already billed.', 16, 1)
   return -1
end

/*
 * Ensure that none of the Source Campaigns are closed if this Camapaign contains 'Make Good' spots
 */

select @count = count(spot_id)
  from campaign_spot
 where spot_type = 'D' and
  	   campaign_no = @campaign_no

if @count > 0 
begin

    select @count = max(delete_charge.source_campaign) 
      from delete_charge, 
           film_campaign
     where delete_charge.source_campaign = film_campaign.campaign_no and
         ( film_campaign.campaign_status = 'X' or film_campaign.campaign_status = 'Z') and
            delete_charge.destination_campaign = @campaign_no

    if @count > 0 
    begin
        select @temp = 'Campaign contains MakeGood for D&C spots. The D&C sports source campaign(' + convert(varchar(15), @count) + ') has been closed.'
        raiserror (@temp, 16, 1)
        return -1
    end
                
end        

/*
 * Begin Transaction
 */

begin transaction

/*
 * Add Unconfirmation Event
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
       'U',
       getdate(),
       'N',
       'Campaign Unconfirmed',
       getdate() )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Film Campaign Unconfirmation - Unconfirmation Event failed', 16, 1)
	return -1
end	

/*
 * Update Campaign Spots
 */

update campaign_spot
   set spot_status = 'P',
       cinema_rate = 0.0
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Cinelight Spots
 */

update cinelight_spot
   set spot_status = 'P',
       cinema_rate = 0.0
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Inclusion Spots
 */

update inclusion_spot
   set spot_status = 'P',
       cinema_rate = 0.0
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Outpost Spots
 */

update outpost_spot
   set spot_status = 'P',
       cinema_rate = 0.0
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Inclusions
 */

update inclusion
   set inclusion_status = 'P'
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Campaign Package
 */

update campaign_package
   set campaign_package_status = 'P'
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Cinelight Package
 */

update cinelight_package
   set cinelight_package_status = 'P'
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end

/*
 * Update Cinelight Package
 */

update outpost_package
   set package_status = 'P'
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign Spot Update Failed.', 16, 1)
   return -1
end


/*
 * Update Campaign Status and Confirmation Values
 */

update film_campaign
   set campaign_status = 'P',
	   inclusion_status = 'P',
	   cinelight_status = 'P',
	   outpost_status = 'P',
	   prop_status = 'N'
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Campaign status update failed.', 16, 1)
   return -1
end

/*
 * Update delete_charge
 */
 
update delete_charge
   set confirmed = 'N'
 where destination_campaign = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Delete Charge confirmation status update failed.', 16, 1)
   return -1
end

delete 	statrev_campaign_periods where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
   rollback transaction
	raiserror ('Film unconfirmation - Deletion of Statutory Revenue Periods failed.', 16, 1)
   return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
