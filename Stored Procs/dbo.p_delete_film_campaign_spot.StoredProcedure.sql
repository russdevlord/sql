/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign_spot]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_film_campaign_spot]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign_spot]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_delete_film_campaign_spot]		@spot_id		int
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
        @delete_charge          int,
        @spot_redirect          int,
        @redirect_from          int

select @tran_id = tran_id,
       @screening_date = screening_date ,
       @spot_type = spot_type,
       @spot_status = spot_status,
       @dandc = dandc,
       @spot_redirect = spot_redirect
  from campaign_spot 
 where spot_id = @spot_id

select @current_date = screening_date
  from film_screening_dates
 where screening_date_status = 'C'
 
 select @delete_charge = count(dcx_id)
   from delete_charge_spots,
        delete_charge
  where delete_charge_spots.delete_charge_id = delete_charge.delete_charge_id
    and delete_charge_spots.spot_id = @spot_id

select @redirect_from = spot_id
  from campaign_spot
 where spot_redirect = @spot_id
 
select @tran_id = isnull(@tran_id, 0)
select @spot_redirect = isnull(@spot_redirect, 0)
select @redirect_from = isnull(@redirect_from, 0)

if @tran_id > 0
begin
	raiserror ('Film Campaign Spot: Spot has already billed. Delete request denied.', 16, 1)
	return -1
end

if @screening_date < @current_date
begin
	raiserror ('Film Campaign Spot: Spot has already screened. Delete request denied.', 16, 1)
	return -1
end

if @spot_status = 'N' or @spot_status = 'U' or @spot_status = 'X'
begin
	raiserror ('Film Campaign Spot: Spots with this status cannot be deleted. Delete request denied.', 16, 1)
	return -1
end

if @spot_status = 'C' and @dandc = 'Y'
begin
    raiserror ('Film Campaign Spot: Cancelled Spots with their DandC flag set "Yes" cannot be deleted. Delete request denied.', 16, 1)
	return -1
end

if @spot_redirect > 0
begin
	raiserror ('Film Campaign Spot: Unallocated Spot has been Made Up. Delete request denied.', 16, 1)
	return -1
end

if @delete_charge > 0
begin
	raiserror ('Film Campaign Spot: Spot has been linked to a Cancelled Spot. Delete request denied.', 16, 1)
	return -1
end

begin transaction

if @redirect_from > 0
begin
    execute @errorode = p_ffin_unallocate_makeup @spot_id--, @redirect_from
    if @errorode <> 0 
    begin
	    raiserror ('Film Campaign Spot: Failed to transfer spot liability. Delete request denied.', 16, 1)
	    return -1
    end
end

delete campaign_spot
 where spot_id = @spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ('Film Campaign Spot: Error Deleting Spot.' , 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
