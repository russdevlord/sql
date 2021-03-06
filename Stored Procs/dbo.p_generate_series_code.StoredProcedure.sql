/****** Object:  StoredProcedure [dbo].[p_generate_series_code]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_generate_series_code]
GO
/****** Object:  StoredProcedure [dbo].[p_generate_series_code]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_generate_series_code] @series_id 			integer,
                                   @retry 				smallint,
                                   @new_code 			char(7) OUTPUT
as

declare @error				int,
        @count				smallint,
        @rowcount			int,
        @series_code		char(2),
        @series_key		int,
        @new_value		int,
        @exit_loop		smallint,
        @sno_default		varchar(5),
        @sno_string		varchar(5)

/*
 * Initialize Count
 */

select @count = 1
select @exit_loop = 0

/*
 * Get Series Code
 */

select @series_code = series_code
  from series
 where series_id = @series_id

if (@@error != 0)
begin
	raiserror (50045,11,1)
	return -1
end

/*
 * Loop Until Error, Sucess or Retries have been exceeded
 */

begin transaction

while @count <= @retry and @exit_loop = 0
begin 

	/*
    * Get Next Value
    */

	select @series_key = series_key
     from series
    where series_id = @series_id

	select @error = @@error,
          @rowcount = @@rowcount

	if (@error != 0 or @rowcount = 0)
	begin
		rollback transaction
		raiserror (50045,11,1)
		return -1
	end

	/*
    * Calculate New Value
    */

	if(@series_key = 99999)
		select @new_value = 0
	else
		select @new_value = @series_key + 1

	/*
    * Update Sequence Number Table
    */

	update series
      set series_key = @new_value
    where series_id = @series_id and
          series_key = @series_key

	select @error = @@error,
          @rowcount = @@rowcount

   if ( @error !=0 )
   begin
		begin
			rollback transaction
			raiserror (50045,11,1)
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
	raiserror (50001,11,1)
	return -1
end

/*
 * Setup New Code
 */

select @sno_default = '00000'
select @sno_string = convert(varchar(5), @new_value)
select @sno_string = right(@sno_default, (len(@sno_default) - len(@sno_string))) + @sno_string
select @new_code = @series_code + @sno_string

/*
 * Commit and Return
 */

commit transaction
return 0
GO
