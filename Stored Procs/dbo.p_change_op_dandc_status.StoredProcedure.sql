USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_change_op_dandc_status]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_change_op_dandc_status]		@spot_id		integer,
                                        @new_dandc      char(1)

as

declare @error          integer,
        @campaign_status			char(1),
		  @tran_id			integer,
		  @screening_date	datetime,
		  @current_date	datetime,
		  @spot_type		char(1),
		  @spot_status		char(1),
          @cnt              int,
          @old_dandc        char(1)

select @tran_id = tran_id ,
       @spot_type = spot_type,
       @spot_status = spot_status,
       @screening_date = screening_date,
       @old_dandc = dandc,
       @campaign_status = film_campaign.campaign_status
  from outpost_spot, film_campaign
 where outpost_spot.spot_id = @spot_id and
       outpost_spot.campaign_no = film_campaign.campaign_no

if @old_dandc = @new_dandc
    return 0

if @spot_status != 'C'
    return 0

if @campaign_status = 'X' or @campaign_status = 'Z'
begin
	raiserror ('outpost_panel Campaign Spot:D&C status cannot be changed for closed campaigns.', 16, 1)
	return -1
end


select @current_date = screening_date
  from film_screening_dates
 where screening_date_status = 'C'


select @tran_id = isnull(@tran_id, 0)

if @tran_id > 0
begin
	raiserror ('outpost_panel Campaign Spot:Spot has already billed.Change D&C status request denied.', 16, 1)
	return -1
end

if @screening_date < @current_date
begin
	raiserror ('outpost_panel Campaign Spot:Spot has already screened.Change D&C status request denied', 16, 1)
	return -1
end

select @cnt = COUNT(spot_id)
from delete_charge_spots
where spot_id = @spot_id

select @cnt = IsNull(@cnt, 0)

if @cnt > 0
begin
	raiserror ('outpost_panel Campaign Spot:Spot linked to another spot.Change D&C status request denied', 16, 1)
	return -1
end


begin transaction

update outpost_spot
   set dandc = @new_dandc
 where spot_id = @spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ('outpost_panel Campaign Spot: Error Changing D&C Spot Status.', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
