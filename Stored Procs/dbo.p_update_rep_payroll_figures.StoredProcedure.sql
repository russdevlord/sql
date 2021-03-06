/****** Object:  StoredProcedure [dbo].[p_update_rep_payroll_figures]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_rep_payroll_figures]
GO
/****** Object:  StoredProcedure [dbo].[p_update_rep_payroll_figures]    Script Date: 12/03/2021 10:03:50 AM ******/
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
