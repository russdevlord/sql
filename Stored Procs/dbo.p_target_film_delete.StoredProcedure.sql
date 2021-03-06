/****** Object:  StoredProcedure [dbo].[p_target_film_delete]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_film_delete]
GO
/****** Object:  StoredProcedure [dbo].[p_target_film_delete]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_film_delete] @fin_year		datetime,
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
 * Delete Film Rep Targets
 */

if (@scope = 'R')
begin

	delete film_rep_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

	delete rep_film_targets
	  from film_reporting_period frp
	 where rep_film_targets.report_period = frp.report_period_end and
			 frp.finyear_end = @fin_year

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Film Branch Targets
 */

if (@scope = 'B')
begin

	delete film_branch_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete branch_film_targets
	  from film_reporting_period frp
	 where branch_film_targets.report_period = frp.report_period_end and
			 frp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Film Branch Targets
 */

if (@scope = 'T')
begin

	delete film_team_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete film_team_targets
	  from film_reporting_period frp
	 where film_team_targets.sales_period = frp.report_period_end and
			 frp.finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Delete Film Area Targets
 */

if (@scope = 'A')
begin

	delete film_area_year
	 where finyear_end = @fin_year
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	
	
	delete film_area_targets
	  from film_reporting_period frp
	 where film_area_targets.sales_period = frp.report_period_end and
			 frp.finyear_end = @fin_year
	
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
