/****** Object:  StoredProcedure [dbo].[p_update_rep_comm_tran]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_rep_comm_tran]
GO
/****** Object:  StoredProcedure [dbo].[p_update_rep_comm_tran]    Script Date: 12/03/2021 10:03:50 AM ******/
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
