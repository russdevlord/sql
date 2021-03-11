USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_update_rep_comm_tran]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_rep_comm_tran]		@comm_tran_id			integer,
												   @comm_amount				money,
												   @comm_rate				numeric(6,4)

as
set nocount on 
declare  @error						integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Payroll table from input variables
 */

update commission_transaction
   set comm_amount = @comm_amount,
		 comm_rate = @comm_rate
 where comm_tran_id = @comm_tran_id

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to update the commission transaction table.', 16, 1)
	return -1
end


/*
 * Commit Transaction
 */

commit transaction
return 0
GO
