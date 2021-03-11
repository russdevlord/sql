USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_confirm_attendance]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_confirm_attendance] @screening_date datetime,
											@complex_id		 integer
as

declare @error			integer,
        @count			smallint

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Movies Confirmed on Complex Date Table
 */

update complex_date
	set movies_confirmed = 1
 where screening_date = @screening_date and
		 complex_id = @complex_id and
		 movies_confirmed = 0

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return @error
end	

/*
 * Update Attendance
 */

update cinema_attendance
	set confirmed = 'Y'
 where screening_date = @screening_date and
		 complex_id = @complex_id and
		 confirmed = 'N'

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return @error
end	


/*
 * Commit and Return
 */

commit transaction
return 0
GO
