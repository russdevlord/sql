/****** Object:  StoredProcedure [dbo].[p_film_campaign_number]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_number]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_number]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_campaign_number] @branch_code   char(2),
                                   @retry         smallint,
                                   @next_value    int OUTPUT 
as

declare @error       	int,
        @count       	smallint,
        @rowcount    	int,
        @exit_loop   	smallint,
        @next				int,
        @upper       	int,
        @lower       	int,
        @prefix_one     char(1),
        @prefix_two     char(1),
        @new_value   	int

/*
 * Initialize Count
 */

select @count     = 1
select @exit_loop = 0

/*
 * Loop Until Error, Success or Retries have been exceeded
 */

begin transaction

while @count <= @retry and @exit_loop = 0
begin 

	/*
    * Get Next Value
    */

	select @next = seqno_next,
          @lower = seqno_start,
          @upper = seqno_end,
          @prefix_one = seqno_prefix_one,
          @prefix_two = seqno_prefix_two
     from branch_sequence
    where branch_code = @branch_code and
          seqno_code = 'FCN'

	select @error = @@error,
          @rowcount = @@rowcount

	if (@error != 0)
	begin
		rollback transaction
		raiserror (@error, 11, 1)
	   return -1
	end

	if (@rowcount = 0)
	begin
		rollback transaction
		raiserror (50005, 11, 1)
		return -1
	end

	/*
    * Set New value
    */
	
	select @next_value = @next
	if @next = @upper
		select @new_value = @lower
	else
		select @new_value = @next + 1

	/*
    * Update Table with New Value
    */

	update branch_sequence
		set seqno_next = @new_value
	 where branch_code = @branch_code and
          seqno_code = 'FCN' and
			 seqno_next = @next and
          seqno_prefix_one = @prefix_one and
          seqno_prefix_two = @prefix_two

	select @error = @@error,
          @rowcount = @@rowcount

	if ( @error !=0 )
  	 begin
		begin
			rollback transaction
			raiserror (@error, 11, 1)
		   	return -1
		end	
	end
	else
	begin
		if @rowcount = 0
			select @count = @count + 1		
		else
			select @exit_loop = 1
	end

end

/*
 * Raise Error if unable to get number in the specified number of retries
 */

if @exit_loop = 0
begin
	rollback transaction
	raiserror (50006, 11, 1)
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
