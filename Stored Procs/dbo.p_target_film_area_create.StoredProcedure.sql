/****** Object:  StoredProcedure [dbo].[p_target_film_area_create]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_film_area_create]
GO
/****** Object:  StoredProcedure [dbo].[p_target_film_area_create]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_film_area_create] @area_id			int,
                                       @fin_year		datetime,
                                       @remove_only	char(1)
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

delete film_area_year
 where area_id = @area_id and
       finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete film_area_targets
  from film_reporting_period frp
 where film_area_targets.area_id = @area_id and
       film_area_targets.sales_period = frp.report_period_end and
       frp.finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

if(@remove_only = 'N')
begin

	/*
	 * Insert Year Record
	 */
	
	insert into film_area_year (
			 finyear_end,
			 area_id,
			 rep_quota,
			 annual_target,
			 monthly_target,
			 periods,
			 setup_complete )
			 values (
			 @fin_year,
			 @area_id,
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
	
	insert into film_area_targets (
			 area_id,
			 sales_period,
			 target_amount,
			 reps_this_period,
			 weeks )
	select @area_id,
			 sp.report_period_end,
			 0,
			 0,
			 round((datediff(day, sp.report_period_start, sp.report_period_end) / 7) + 1 ,0)       
	  from film_reporting_period sp
	 where sp.finyear_end = @fin_year
	
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
