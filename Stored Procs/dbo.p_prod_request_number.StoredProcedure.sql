/****** Object:  StoredProcedure [dbo].[p_prod_request_number]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prod_request_number]
GO
/****** Object:  StoredProcedure [dbo].[p_prod_request_number]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_prod_request_number] @branch_code   	char(2),
                                  @request_source	char(1),
                                  @retry         	smallint,
                                  @request_no    	char(8) OUTPUT 
as
set nocount on 
declare @error       	int,
        @count       	smallint,
        @rowcount    	int,
        @exit_loop   	smallint,
        @next				int,
        @upper       	int,
        @lower       	int,
        @prefix_one     char(1),
        @prefix_two     char(1),
        @new_value   	int,
        @new_prefix_one	char(1),
        @cno_string		varchar(4),
        @cno_default		char(4)

/*
 * Initialize Counters
 */

select @count = 1
select @exit_loop = 0
select @cno_default = '0000'

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
          seqno_code = 'REQ'

	select @error = @@error,
          @rowcount = @@rowcount

	if (@error != 0)
	begin
		rollback transaction
		raiserror ( 'Error in p_prod_request_number', 16, 1) 
	   return -1
	end

	if (@rowcount = 0)
	begin
		rollback transaction
		raiserror ('Error in p_prod_request_number', 16,1)
		return -1
	end

	/*
    * Set New value
    */
	
	select @new_prefix_one = @prefix_one

	if @next = @upper
	begin
		select @new_value = @lower
		if(@prefix_one = 'Z')
			select @new_prefix_one = 'A'
		else
			select @new_prefix_one = char(ascii(@prefix_one) + 1)
	end
	else
		select @new_value = @next + 1

	/*
    * Calculate Request Number
    */

   select @cno_string = convert(varchar(4), @next)
	select @cno_string = right(@cno_default, (len(@cno_default) - len(@cno_string))) + @cno_string
	select @request_no = convert(char(1),@branch_code) + @request_source + @prefix_two + @prefix_one + @cno_string

	/*
    * Update Table with New Value
    */

	update branch_sequence
		set seqno_next = @new_value,
            seqno_prefix_one = @new_prefix_one
	 where branch_code = @branch_code and
          seqno_code = 'REQ' and
			 seqno_next = @next and
          seqno_prefix_one = @prefix_one and
          seqno_prefix_two = @prefix_two

	select @error = @@error,
          @rowcount = @@rowcount

   if ( @error !=0 )
   begin
		begin
			rollback transaction
			raiserror ('Error in p_prod_request_number', 16, 1)
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
	raiserror ('Error in p_prod_request_number', 16, 1)

	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
