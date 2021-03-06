/****** Object:  StoredProcedure [dbo].[p_sfin_charge_distribution]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_charge_distribution]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_charge_distribution]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_charge_distribution] @campaign_no	char(7),
                                       @nett_amount	money
with recompile as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @current_accrual			money

/*
 * Get Current Distribution Amount
 */

select @current_accrual = isnull(accrued_alloc,0)
  from slide_distribution
 where campaign_no = @campaign_no and
       distribution_type = 'C'

/*
 * Ensure Accrual will not go below Zero
 */

if(@nett_amount + @current_accrual < 0)
begin
	raiserror ('Negative extra charge on the slide distribution detected. Charge distribution failed.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Slide Distribution
 */

select @current_accrual = @current_accrual + @nett_amount

update slide_distribution
   set actual_alloc = @current_accrual,
       accrued_alloc = @current_accrual
 where campaign_no = @campaign_no and
       distribution_type = 'C'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
