/****** Object:  StoredProcedure [dbo].[p_credit_controller_change]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_credit_controller_change]
GO
/****** Object:  StoredProcedure [dbo].[p_credit_controller_change]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_credit_controller_change] @branch_code		char(2),
                                       @new_controller	integer,
                                       @old_controller   integer,
                                       @new_manager		integer,
                                       @old_manager  		integer,
                                       @new_cut_off		char(1),
                                       @old_cut_off		char(1),
													@cut_off_options	char(1),
                                       @campaign_codes	char(36)
as

declare @error			integer,
        @codes			char(36),
        @search		char(2),
        @action		char(1),
        @code_pos		smallint

/*
 * Initialise Variables
 */

select @codes = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'

/*
 * Begin Transaction
 */

begin transaction

/*
 * Loop Through Codes
 */

select @code_pos = 1
while (@code_pos < 37)
begin

	select @action = substring(@campaign_codes, @code_pos, 1)
	
	if (@action = '1')
	begin

		/*
       * Setup Search String
       */

		select @search = substring(@codes, @code_pos, 1) + '%'

		/*
       * Update Camapigns with Credit Cut - off
       */

		if not (@new_cut_off is null)
		begin
	
			if not (@old_cut_off is null)
			begin

				if @cut_off_options = 'A'
					
					update slide_campaign
						set credit_cut_off = @new_cut_off
					 where is_closed <> 'Y' and
							 branch_code = @branch_code and
							 credit_cut_off = @old_cut_off and
							 sort_key like @search

				if @cut_off_options = 'C'
					
					update slide_campaign
						set credit_cut_off = @new_cut_off
					 where is_closed <> 'Y' and
							 branch_code = @branch_code and
							 credit_cut_off = @old_cut_off and
							 credit_controller = @old_controller and
							 sort_key like @search

				if @cut_off_options = 'M'
					
					update slide_campaign
						set credit_cut_off = @new_cut_off
					 where is_closed <> 'Y' and
							 branch_code = @branch_code and
							 credit_cut_off = @old_cut_off and
							 credit_manager = @old_manager and
							 sort_key like @search
			end
			else
			begin

				if @cut_off_options = 'A'
					
					update slide_campaign
						set credit_cut_off = @new_cut_off
					 where is_closed <> 'Y' and
							 branch_code = @branch_code and
							 sort_key like @search

				if @cut_off_options = 'C'
					
					update slide_campaign
						set credit_cut_off = @new_cut_off
					 where is_closed <> 'Y' and
							 branch_code = @branch_code and
							 credit_controller = @old_controller and
							 sort_key like @search

				if @cut_off_options = 'M'
					
					update slide_campaign
						set credit_cut_off = @new_cut_off
					 where is_closed <> 'Y' and
							 branch_code = @branch_code and
							 credit_manager = @old_manager and
							 sort_key like @search
			end
				 
			select @error = @@error
			if ( @error !=0 )
			begin
				rollback transaction
				return -1
			end	
		end

		/*
       * Update Camapigns with Credit Controller
       */

		if not (@new_controller is null)
		begin
	
			if not (@old_controller is null)
	
				update slide_campaign
					set credit_controller = @new_controller
				 where is_closed <> 'Y' and
						 branch_code = @branch_code and
						 credit_controller = @old_controller and
						 sort_key like @search
			
			else
	
				update slide_campaign
					set credit_controller = @new_controller
				 where is_closed <> 'Y' and
						 branch_code = @branch_code and
						 sort_key like @search
	
				 
			select @error = @@error
			if ( @error !=0 )
			begin
				rollback transaction
				return -1
			end	
		end

		/*
       * Update Camapigns with Credit Manager
       */

		if not (@new_manager is null)
		begin
	
			if not (@old_manager is null)
	
				update slide_campaign
					set credit_manager = @new_manager
				 where is_closed <> 'Y' and
						 branch_code = @branch_code and
						 credit_manager = @old_manager and
						 sort_key like @search
			
			else
	
				update slide_campaign
					set credit_manager = @new_manager
				 where is_closed <> 'Y' and
						 branch_code = @branch_code and
						 sort_key like @search
	
				 
			select @error = @@error
			if ( @error !=0 )
			begin
				rollback transaction
				return -1
			end	
		end
	end

	/*
    * Increment Code Position
    */

	select @code_pos = @code_pos + 1

end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
