/****** Object:  StoredProcedure [dbo].[p_slide_campaign_number]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_number]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_number]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_campaign_number] @branch_code   	char(2),
                                    @campaign_type		char(1),
                                    @retry         	smallint,
                                    @campaign_no    	char(7) OUTPUT 
as
set nocount on 
declare @error       	integer,
        @count       	smallint,
        @rowcount    	integer,
        @exit_loop   	smallint,
        @next				integer,
        @upper       	integer,
        @lower       	integer,
        @prefix_one     char(1),
        @prefix_two     char(1),
        @new_value   	integer,
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
          seqno_code = 'SCN'

	select @error = @@error,
          @rowcount = @@rowcount

	if (@error != 0)
	begin
		rollback transaction
		raiserror ('p_slide_campaign_number : Select Error', 16, 1)
	   return -1
	end

	if (@rowcount = 0)
	begin
		rollback transaction
		raiserror ('p_slide_campaign_number: 0 Rows Selected', 16, 1)
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
    * Calculate Campaign Number
    */

   select @cno_string = convert(varchar(4), @next)
	select @cno_string = right(@cno_default, (len(@cno_default) - len(@cno_string))) + @cno_string
	select @campaign_no = convert(char(1),@branch_code) + @campaign_type + @prefix_one +  @cno_string 

	/*
    * Update Table with New Value
    */

	update branch_sequence
		set seqno_next = @new_value
	 where branch_code = @branch_code and
          seqno_code = 'SCN' and
			 seqno_next = @next and
          seqno_prefix_one = @prefix_one and
          seqno_prefix_two = @prefix_two

	select @error = @@error,
          @rowcount = @@rowcount

   if ( @error !=0 )
   begin
		begin
			rollback transaction
			raiserror ('p_slide_campaign_number: Update Error', 16, 1)
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
	raiserror ('p_slide_campaign_number: unable to get slide campaign number in the specified number of retries !', 16, 1)
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
