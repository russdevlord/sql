/****** Object:  StoredProcedure [dbo].[p_target_film_rep_create]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_film_rep_create]
GO
/****** Object:  StoredProcedure [dbo].[p_target_film_rep_create]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_film_rep_create] @rep_id			   int,
                                     @fin_year			datetime,
                                     @branch_code		char(2),
												 @remove_only		char(1)

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

delete film_rep_year
 where rep_id = @rep_id and
       finyear_end = @fin_year and
       branch_code = @branch_code

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete rep_film_targets
  from film_reporting_period frp
 where rep_film_targets.rep_id = @rep_id and
       rep_film_targets.branch_code = @branch_code and
       rep_film_targets.report_period = frp.report_period_end and
       frp.finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Insert Year Record
 */

if @remove_only = 'N'
begin
	insert into film_rep_year (
			 finyear_end,
			 rep_id,
			 branch_code,
			 annual_target,
			 monthly_target,
			 periods,
			 setup_complete )
			 values (
			 @fin_year,
			 @rep_id,
			 @branch_code,
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
	
	insert into rep_film_targets (
			 report_period,
			 rep_id,
			 branch_code,
			 target_amount )
	select frp.report_period_end,
			 @rep_id,
			 @branch_code,
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
