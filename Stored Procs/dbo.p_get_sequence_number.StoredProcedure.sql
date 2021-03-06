/****** Object:  StoredProcedure [dbo].[p_get_sequence_number]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_sequence_number]
GO
/****** Object:  StoredProcedure [dbo].[p_get_sequence_number]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_get_sequence_number] ( @table_name 		char(255),
                                    @retry 				smallint,
                                    @next_value 		int OUTPUT )
as
set nocount on 

/* Proc name:   p_get_sequence_number
 * Author:      
 * Date:        
 * Description: This procedure gets the next sequence number from the 
 *              sequence_no table for a given table in the database.
 *
 * Changes:     10/3/2004, Added self-initialisation code if entry does not exist
 *
*/ 

declare @error			int,
        @count			smallint,
        @rowcount		int,
        @new_value	int,
        @exit_loop	smallint,
        @tstamp		timestamp,
        @keycnt smallint,
        @indexid smallint,
        @key_column  varchar(50),
        @resync_flag char(1),
        @tmp_str    varchar(10)


/*
 * Initialize Count
 */

select @count = 1
select @exit_loop = 0

/*
 * Loop Until Error, Sucess or Retries have been exceeded
 */

begin transaction

while @count <= @retry and @exit_loop = 0
begin 

	/*
    * Get Next Value
    */

	select @next_value = next_value,
          @tstamp = timestamp
     from sequence_no
    where table_name = @table_name

	select @error = @@error,
          @rowcount = @@rowcount

	if (@error != 0)
	begin
		rollback transaction
		raiserror (@error, 11, 1)
	   return @error
	end

	if (@rowcount = 0)
	begin
--        select @next_value = 1
        
        /* if there is only 1 col in PK then set key_column to this */
--	    select @keycnt = keycnt, @indexid = indid
--	    from   sysindexes
--	    where  id = object_id(@table_name)
--	    and indid > 0 /* make sure it is an index */
--	    and status2 & 2 = 2 /* make sure it is a declarative constr */
--	    and status & 2048 = 2048 /* make sure it is a primary key */

--	    if (@indexid >= 2)
--	    begin
--		    select @keycnt = @keycnt - 1
--	    end

--        if @keycnt = 1
	    /* returns index column_name */	
--            select  @key_column = index_col(@table_name, @indexid, 1),
--                    @resync_flag = 'Y'
--        else
--            select  @key_column = @table_name,
--                    @resync_flag = 'N'
        
--        INSERT INTO dbo.sequence_no
--	        (table_name,
--	         next_value,
--	         key_column,
--	         resync_flag)
--        VALUES
--	        (@table_name,
--	         @next_value,
--	         @key_column,
--	         @resync_flag)    

--	    select @error = @@error
--        if @error != 0
--        begin
--		    rollback transaction
--		    raiserror (@error, 11, 1)
--		    return -1
--        end
		rollback transaction
		raiserror('p_get_sequence_number: Failed to obtain next sequence number for %s', 16, 1, @table_name)
		return -1
	end

	/*
    * Determine New Value
    */

	if(@next_value = 2147483647)
		select @new_value = 1
	else
		select @new_value = @next_value + 1
	
	/*
    * Update Sequence Number Table
    */

	update sequence_no
      set next_value = @new_value
    where table_name = @table_name and
          next_value = @next_value

	select @error = @@error,
           @rowcount = @@rowcount

   if ( @error !=0 )
   begin
		begin
			rollback transaction
			raiserror('p_get_sequence_number: Failed to update next sequence number for %s', 16, 1, @table_name)
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
	raiserror (50001, 11, 1)
	return -1
end

/*
 * Commit and Return
 */

commit transaction

-- select @tmp_str = convert(varchar(10),@next_value)
-- print @tmp_str

return 0
GO
