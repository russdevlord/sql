/****** Object:  StoredProcedure [dbo].[p_sfin_add_statement_line]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_add_statement_line]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_add_statement_line]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_add_statement_line]	@statement_id	 integer,
													@line_no 		 smallint,
													@line_desc      varchar(255),
													@line_bold		 char(1)
as

/*
 * Declare Variables
 */

declare @line_id		integer,
        @errorode			integer,
        @error			integer

/*
 *	Begin Transaction
 */

begin transaction

/*
 * Get a Transaction Id
 */

execute @errorode = p_get_sequence_number 'slide_statement_line',5,@line_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Insert Line
 */

insert into slide_statement_line (
       statement_line_id,
       statement_id,
       statement_line_no,
       statement_line_desc,
       statement_line_bold ) values (
	    @line_id,
	    @statement_id, 
	    @line_no,
	    @line_desc,
	    @line_bold )

select @error = @@error
if (@error !=0)
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
