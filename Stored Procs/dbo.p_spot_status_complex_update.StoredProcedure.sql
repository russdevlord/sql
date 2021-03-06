/****** Object:  StoredProcedure [dbo].[p_spot_status_complex_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_status_complex_update]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_status_complex_update]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_spot_status_complex_update] @spot_id				integer,
																								@new_status			char(1),
																								@new_complex		integer
as

/*
 * Declare Procedure Variables
 */

declare	@error          integer,
				@rowcount	    integer,
				@spot_type		char(1),
				@charge_rate 	decimal,
				@cert_score		integer,
				@spot_redirect  integer

select 		@spot_type = spot_type,
				@charge_rate = charge_rate,
				@cert_score = certificate_score,
				@spot_redirect = spot_redirect
from		campaign_spot 
where		spot_id = @spot_id
 
 if @new_status <> 'U' and @spot_redirect is not null
 begin
    raiserror ('Cannot allocate spot as its unallocation has already been directed to a new allocated spot', 16, 1)
    return -100
  end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Spot
 */
if (@new_status = 'U')
begin
	if (@spot_type = 'Y')
	begin
		update campaign_spot
			set spot_status = @new_status,
				 spot_instruction = 'Manual Unallocation',
				onscreen = 'N'		
		 where spot_id = @spot_id
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error', 16, 1)
			return @error
		end	

		update film_plan
			set current_spend = current_spend - @charge_rate
		 where film_plan_id = @cert_score
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error(2)', 16, 1)
			return -1
		end	

	end
	else
	begin
		update campaign_spot
			set spot_status = @new_status,
				 certificate_score = 10,
				 spot_instruction = 'Manual Unallocation',
				onscreen = 'N'
		 where spot_id = @spot_id
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error(3)', 16, 1)
			return -1
		end	
	end
end
else if (@new_status = 'X')
begin
	if (@spot_type = 'Y') 
	begin
		update	campaign_spot
		set			spot_status = @new_status,
						complex_id = @new_complex,
						spot_instruction = 'No Errors',
						onscreen = 'Y'
		where		spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error(4)', 16, 1)
			return -1
		end	

		update	film_plan
			set		current_spend = current_spend + @charge_rate
		 where		film_plan_id = @cert_score
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error(5)', 16, 1)
			return -1
		end	
	end
	else
	begin
		update	campaign_spot
		set			spot_status = @new_status,
						complex_id = @new_complex,
						certificate_score = 0,
						spot_instruction = 'No Errors',
						onscreen = 'Y'
		where		spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error (6)', 16, 1)
			return -1
		end	
	end
end
else 
begin
	if (@spot_type = 'Y') 
	begin
		update campaign_spot
			set	spot_status = @new_status,
				 spot_instruction = 'No Errors'
		 where spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error(4)', 16, 1)
			return -1
		end	

		update film_plan
			set current_spend = current_spend + @charge_rate
		 where film_plan_id = @cert_score
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error(5)', 16, 1)
			return -1
		end	
	end
	else
	begin
		update campaign_spot
			set spot_status = @new_status,
				 certificate_score = 0,
				 spot_instruction = 'No Errors'
		 where spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_complex_update: Update Error (6)', 16, 1)
			return -1
		end	
	end
end

commit transaction
return 0
GO
