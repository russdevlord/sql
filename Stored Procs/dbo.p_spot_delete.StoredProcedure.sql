/****** Object:  StoredProcedure [dbo].[p_spot_delete]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_delete]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_delete]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_spot_delete] @spot_id	integer
as

/*
 * Declare Procedure Variables
 */

declare @error          integer,
        @errorode              int,
        @rowcount			integer,
		  @spot_type		char(1),
		  @film_plan_id	integer,
		  @charge_rate		money,
		  @rate				money,
		  @current_spend	money,
		  @current_value	money,
          @spot_redirect    integer


select @spot_redirect = spot_redirect
  from campaign_spot
 where spot_id = @spot_id
 
if @spot_redirect is not null
begin
    raiserror ('Error - spot has been linked to another spot and cannot be deleted.', 16, 1)
    return -100
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Film Plans if necassary
 */

select @spot_type = spot_type 
  from campaign_spot
 where spot_id = @spot_id

if @spot_type = 'Y'
begin

	select @film_plan_id = certificate_score
     from campaign_spot
	 where spot_id = @spot_id

	select @charge_rate = charge_rate,
			 @rate = rate,
			 @current_spend = current_spend,
			 @current_value = current_value
	  from film_plan
	 where film_plan_id = @film_plan_id

	select @current_spend = @current_spend - @charge_rate
    select @current_value = @current_value - @rate

	update film_plan
	   set current_spend = @current_spend,
			 current_value = @current_value
    where film_plan_id = @film_plan_id

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('Error updating film plan - spot not deleted', 16, 1)
			return @error
		end	

end

if @spot_type = 'M' or @spot_type = 'V'
begin

    exec @errorode = p_ffin_unallocate_makeup @spot_id
    
    if ( @errorode !=0 )
	begin
		rollback transaction
		raiserror ('Error unallocating makeups', 16, 1)
		return @error
	end	


end

delete inclusion_campaign_spot_xref
where	spot_id = @spot_id

select @error = @@error
if @error != 0
begin
	raiserror ('Failed to remove inclusion_campaign_spot_xref', 16, 1)
	rollback transaction
	return -1
end
/*
 * Delete Spot
 */

delete campaign_spot
 where spot_id = @spot_id
 
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
			raiserror ('Error deleting spot', 16, 1)
	return @error
end	

commit transaction
return 0
GO
