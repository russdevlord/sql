USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_update_rep_payroll_figures]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_rep_payroll_figures]	@figure_id				integer,
														@payroll_options		char(1)

as
set nocount on 
declare  @error						integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Slide Figures table from input variables
 */

update slide_figures
   set payroll_options = @payroll_options
 where figure_id = @figure_id

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to update the slide figures table.', 16, 1)
	return -1
end

/*
 * Commit Transaction
 */

commit transaction
return 0
GO
