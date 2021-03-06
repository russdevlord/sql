/****** Object:  StoredProcedure [dbo].[p_target_film_branch_create]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_film_branch_create]
GO
/****** Object:  StoredProcedure [dbo].[p_target_film_branch_create]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_film_branch_create]  @branch_code			char(2),
                                         @fin_year				datetime,
													  @remove_only			char(1)
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
 * Delete any existing Records
 */

delete film_branch_year
 where branch_code = @branch_code and
       finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	raiserror ('p_target_film_branch_create: Delete Error', 16, 1)
	rollback transaction
	return -1
end	

delete branch_film_targets
  from film_reporting_period frp
 where branch_film_targets.branch_code = @branch_code and
       branch_film_targets.report_period = frp.report_period_end and
       frp.finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	raiserror ('p_target_film_branch_create: Delete Error(2)', 16, 1)
	rollback transaction
	return -1
end	


/*
 * Insert Year Record
 */

if @remove_only = 'N'
begin
	insert into film_branch_year (
			 finyear_end,
			 branch_code,
			 rep_quota,
			 annual_target,
			 monthly_target,
			 periods,
			 setup_complete )
			 values (
			 @fin_year,
			 @branch_code,
			 0,
			 0,
			 0,
			 0,
			 'N' )
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		return -1
	end	

/*
 * Insert Target Records
 */

	insert into branch_film_targets (
			 branch_code,
			 report_period,
			 target_amount )
	select @branch_code,
			 frp.report_period_end,
			 0       
	  from film_reporting_period frp
	 where frp.finyear_end = @fin_year
	
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
