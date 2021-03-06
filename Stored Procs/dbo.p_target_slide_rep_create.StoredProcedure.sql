/****** Object:  StoredProcedure [dbo].[p_target_slide_rep_create]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_slide_rep_create]
GO
/****** Object:  StoredProcedure [dbo].[p_target_slide_rep_create]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_slide_rep_create] @rep_id			int,
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

delete rep_year
 where rep_id = @rep_id and
       finyear_end = @fin_year and
       branch_code = @branch_code

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete rep_slide_targets
  from rep_slide_targets rst,
       sales_period sp
 where rst.rep_id = @rep_id and
       rst.branch_code = @branch_code and
       rst.sales_period = sp.sales_period_end and
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
	
	insert into rep_year (
			 finyear_end,
			 rep_id,
          branch_code,
			 annual_target,
			 weekly_target,
			 weeks,
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
	
	insert into rep_slide_targets (
			 rep_id,
			 sales_period,
          branch_code,
			 target_amount,
			 weeks )
	select @rep_id,
			 sp.sales_period_end,
          @branch_code,
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
