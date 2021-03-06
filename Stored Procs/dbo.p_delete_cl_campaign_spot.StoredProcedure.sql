/****** Object:  StoredProcedure [dbo].[p_delete_cl_campaign_spot]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_cl_campaign_spot]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_cl_campaign_spot]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_cl_campaign_spot]		@spot_id		int
as

declare @error                  int,
        @errorode                  int,
        @rowcount		        int,
	    @tran_id		    	int,
	    @screening_date	        datetime,
	    @current_date       	datetime,
	    @spot_type	        	char(1),
	    @spot_status    		char(1),
        @dandc                  char(1),
        @delete_charge          int

begin transaction

select @tran_id = tran_id,
       @screening_date = screening_date ,
       @spot_type = spot_type,
       @spot_status = spot_status,
       @dandc = dandc
  from cinelight_spot 
 where spot_id = @spot_id

select @current_date = screening_date
  from film_screening_dates
 where screening_date_status = 'C'
 
 select @delete_charge = count(dcx_id)
   from delete_charge_spots,
        delete_charge
  where delete_charge_spots.delete_charge_id = delete_charge.delete_charge_id
    and delete_charge_spots.spot_id = @spot_id

select @tran_id = isnull(@tran_id, 0)

if @tran_id > 0
begin
	raiserror ('Cinelight Campaign Spot: Spot has already billed. Delete request denied.', 16, 1)
	return -1
end

if @screening_date < @current_date
begin
	raiserror ('Cinelight Campaign Spot: Spot has already screened. Delete request denied.', 16, 1)
	return -1
end

if @spot_status = 'N' or @spot_status = 'U' or @spot_status = 'X'
begin
	raiserror ('Cinelight Campaign Spot: Spots with this status cannot be deleted. Delete request denied.', 16, 1)
	return -1
end

if @spot_status = 'C' and @dandc = 'Y'
begin
    raiserror ('Cinelight Campaign Spot: Cancelled Spots with their DandC flag set "Yes" cannot be deleted. Delete request denied.', 16, 1)
	return -1
end


if @delete_charge > 0
begin
	raiserror ('Cinelight Campaign Spot: Spot has been linked to a Cancelled Spot. Delete request denied.', 16, 1)
	return -1
end

delete from cinelight_playlist_spot_xref
 where spot_id = @spot_id
 
 select @error = @@error
if ( @error !=0 )
begin
	raiserror ('Cinelight Campaign playlist Spot: Error Deleting Spot.' , 16, 1)
	rollback transaction
	return -1
end

delete cinelight_spot
 where spot_id = @spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ('Cinelight Campaign Spot: Error Deleting Spot.' , 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
