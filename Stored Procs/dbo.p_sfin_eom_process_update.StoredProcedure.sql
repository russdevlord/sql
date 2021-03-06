/****** Object:  StoredProcedure [dbo].[p_sfin_eom_process_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_process_update]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_process_update]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_eom_process_update] @accounting_period		datetime
with recompile as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Non-Trading Transactions
 */

update non_trading
   set process_period = @accounting_period
 where process_period is null

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update process period on non trading.', 16, 1)
	return -1
end	

/*
 * Update Slide Transactions
 */

update slide_transaction
   set accounting_period = @accounting_period
 where accounting_period is null

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update process period on slide transaction.', 16, 1)
	return -1
end	

/*
 * Update Slide Allocations
 * ------------------------
 *
 */

update slide_allocation
   set process_period = @accounting_period
 where process_period is null
			
select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update process period on slide allocation.', 16, 1)
	return -1
end	

/*
 * Update Slide Statements
 */

update slide_statement
   set accounting_period = @accounting_period
 where accounting_period is null

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update process period on slide statement.', 16, 1)
	return -1
end	

/*
 * Update Campaign Spot Pools for Bad Debts
 */

update slide_spot_pool
   set release_period = @accounting_period
 where release_period is null and
       spot_pool_type = 'D' --Bad Debt

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update process period on slide spot pool.', 16, 1)
	return -1
end	

/*
 * Update Campaign Spot Pools for Billings and Credits
 */

update slide_spot_pool
   set release_period = @accounting_period
  from slide_campaign_spot
 where release_period is null and
     ( spot_pool_type = 'B' or --Billing
       spot_pool_type = 'C' ) and --Credit
       slide_spot_pool.spot_id = slide_campaign_spot.spot_id and
       slide_campaign_spot.screening_date <= @accounting_period

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update process period on slide spot pool.', 16, 1)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
