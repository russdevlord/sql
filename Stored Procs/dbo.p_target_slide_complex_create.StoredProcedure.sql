/****** Object:  StoredProcedure [dbo].[p_target_slide_complex_create]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_target_slide_complex_create]
GO
/****** Object:  StoredProcedure [dbo].[p_target_slide_complex_create]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_target_slide_complex_create] @complex_id				integer,
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

delete complex_year
 where complex_id = @complex_id and
       finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete complex_slide_targets
  from complex_slide_targets cst,
       sales_period sp
 where cst.complex_id = @complex_id and
       cst.sales_period = sp.sales_period_end and
       sp.finyear_end = @fin_year

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

if (@remove_only = 'N')
begin

	/*
	 * Insert Year Record
	 */
	
	insert into complex_year (
			 complex_id,
			 finyear_end,
			 annual_target,
			 setup_complete )
			 values (
			 @complex_id,
			 @fin_year,
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
	
	insert into complex_slide_targets (
			 complex_id,
			 sales_period,
			 target_amount )
	select @complex_id,
			 sp.sales_period_end,
			 0
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
