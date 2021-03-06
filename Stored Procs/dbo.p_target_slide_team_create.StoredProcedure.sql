/****** Object:  StoredProcedure [dbo].[p_target_slide_team_create]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_slide_team_create]
GO
/****** Object:  StoredProcedure [dbo].[p_target_slide_team_create]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_slide_team_create] @team_id			int,
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

delete team_year
 where team_id = @team_id and
       finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete team_slide_targets
  from team_slide_targets tst,
       sales_period sp
 where tst.team_id = @team_id and
       tst.sales_period = sp.sales_period_end and
       sp.finyear_end = @fin_year

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
	
	insert into team_year (
			 finyear_end,
			 team_id,
			 rep_quota,
			 annual_target,
			 weekly_target,
			 weeks,
			 setup_complete )
			 values (
			 @fin_year,
			 @team_id,
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
	
	insert into team_slide_targets (
			 team_id,
			 sales_period,
			 target_amount,
			 weeks )
	select @team_id,
			 sp.sales_period_end,
			 0,
			 round((datediff(day, sp.sales_period_start, sp.sales_period_end) / 7) + 1 ,0)       
	  from sales_period sp
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
