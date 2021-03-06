/****** Object:  StoredProcedure [dbo].[p_delete_inclusion_spot]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_inclusion_spot]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_inclusion_spot]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_delete_inclusion_spot]		@spot_id		int
as

declare @error                  int,
        @errorode                  int,
        @rowcount		        int,
	    @tran_id		    	int,
	    @screening_date	        datetime,
	    @current_date       	datetime,
	    @spot_type	        	char(1),
	    @spot_status    		char(1),
        @delete_charge          int,
        @spot_redirect          int,
        @redirect_from          int

select @tran_id = tran_id,
       @screening_date = screening_date ,
       @spot_type = spot_type,
       @spot_status = spot_status,
       @spot_redirect = spot_redirect
  from inclusion_spot 
 where spot_id = @spot_id

select @current_date = screening_date
  from film_screening_dates
 where screening_date_status = 'C'
 
select @redirect_from = spot_id
  from inclusion_spot
 where spot_redirect = @spot_id
 
select @tran_id = isnull(@tran_id, 0)
select @spot_redirect = isnull(@spot_redirect, 0)
select @redirect_from = isnull(@redirect_from, 0)

if @tran_id > 0
begin
	raiserror ('Inclusion Spot: Spot has already billed. Delete request denied.', 16, 1)
	return -1
end

if @screening_date < @current_date
begin
	raiserror ('Inclusion Spot: Spot has already screened. Delete request denied.', 16, 1)
	return -1
end

if @spot_status = 'N' or @spot_status = 'U' or @spot_status = 'X'
begin
	raiserror ('Inclusion Spot: Spots with this status cannot be deleted. Delete request denied.', 16, 1)
	return -1
end

if @spot_redirect > 0
begin
	raiserror ('Inclusion Spot: Unallocated Spot has been Made Up. Delete request denied.', 16, 1)
	return -1
end

begin transaction

if @redirect_from > 0
begin
    execute @errorode = p_inclusion_unallocate_makeup @spot_id
    if @errorode <> 0 
    begin
	    raiserror ('Film Campaign Spot: Failed to transfer spot liability. Delete request denied.', 16, 1)
	    return -1
    end
end

delete inclusion_spot
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
