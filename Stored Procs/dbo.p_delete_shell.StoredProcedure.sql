USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_shell]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_shell]		@shell_code		char(7)

as

declare @error          	int,
        @rowcount			int

/*
 * Begin Transaction
 */
begin transaction

/*
 * Delete shell artworks
 */
delete shell_artwork
 where shell_code = @shell_code

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete shell xrefs
 */
delete shell_xref
 where shell_code = @shell_code
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete shell
 */
delete shell
 where shell_code = @shell_code
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	
/*
 * Commit and Return
 */

commit transaction
return 0
GO
