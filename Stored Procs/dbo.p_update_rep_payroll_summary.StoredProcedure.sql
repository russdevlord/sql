/****** Object:  StoredProcedure [dbo].[p_update_rep_payroll_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_rep_payroll_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_update_rep_payroll_summary]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_rep_payroll_summary]	@salary						money,
														@days_absent				integer,
														@commission_percentage	decimal(10,6),
														@entry_level				money,
														@payroll_id					integer

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

update payroll
   set salary = @salary,
		 days_absent = @days_absent,
		 commission_percentage	= @commission_percentage,
		 entry_level = @entry_level
 where payroll_id = @payroll_id

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to update the payroll table.', 16, 1)
	return -1
end

/*
 * Commit Transaction
 */

commit transaction
return 0
GO
