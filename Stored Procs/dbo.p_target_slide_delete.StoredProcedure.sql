/****** Object:  StoredProcedure [dbo].[p_target_slide_delete]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_slide_delete]
GO
/****** Object:  StoredProcedure [dbo].[p_target_slide_delete]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_slide_delete] @fin_year		datetime,
                                  @scope			char(1)
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          int,
        @rowcount			int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Rep Targets
 */

if (@scope = 'R')
begin

	delete rep_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

	delete rep_slide_targets
	  from rep_slide_targets rst,
			 sales_period sp
	 where rst.sales_period = sp.sales_period_end and
			 sp.finyear_end = @fin_year

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Branch Targets
 */

if (@scope = 'B')
begin

	delete branch_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete branch_slide_targets
	  from branch_slide_targets bst,
			 sales_period sp
	 where bst.sales_period = sp.sales_period_end and
			 sp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Team Targets
 */

if (@scope = 'T')
begin

	delete team_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete team_slide_targets
	  from team_slide_targets tst,
			 sales_period sp
	 where tst.sales_period = sp.sales_period_end and
			 sp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Area Targets
 */

if (@scope = 'A')
begin

	delete area_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete area_slide_targets
	  from area_slide_targets ast,
			 sales_period sp
	 where ast.sales_period = sp.sales_period_end and
			 sp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete region Targets
 */

if (@scope = 'S')
begin

	delete region_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete region_slide_targets
	  from region_slide_targets ast,
			 sales_period sp
	 where ast.sales_period = sp.sales_period_end and
			 sp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Complex Targets
 */

if (@scope = 'X')
begin

	delete complex_slide_targets
	  from complex_slide_targets cst,
			 sales_period sp
	 where cst.sales_period = sp.sales_period_end and
			 sp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

	delete complex_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
