/****** Object:  StoredProcedure [dbo].[p_ffin_delete_payment]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_delete_payment]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_delete_payment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_delete_payment] @tran_id 		integer,
											 @campaign_no	integer
as

/*
 * Declare Variables
 */

declare @errorode		integer,
        @error		integer,
	@tran_count	integer,
        @statement_id	integer,
	@tran_category	char(1),
	@process_period	datetime,
	@reversal	char(1)
		  
/*
 * Initialise Variables
 */

select @tran_count = 0

/*
 * Check if the Transaction is on a Statement
 */

select @statement_id = statement_id,
       @tran_category = tran_category,
       @reversal = reversal
  from campaign_transaction
 where tran_id = @tran_id

if(@tran_category <> 'C')
begin
	raiserror ('p_ffin_delete_payment:Tansaction is not a Payment - Delete Failed.', 16, 1)
	return -1
end

if(@reversal = 'Y')
begin
	raiserror ('p_ffin_delete_payment:Tansaction has already been Reversed - Delete Failed.', 16, 1)
	return -1
end

if(@statement_id is not null)
begin
	raiserror ('p_ffin_delete_payment:Transaction appears on a Statement - Delete Failed.', 16, 1)
	return -1
end

/*
 * Check Allocations
 */

select @tran_count = isnull(count(from_tran_id),0)
  from transaction_allocation ta
 where ta.from_tran_id = @tran_id and
		 ta.process_period <> null

if(@tran_count > 0)
begin
	raiserror ('p_ffin_delete_payment: Transaction has already been processed - Delete Failed.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */
	
begin transaction

/*
 * Delete Transaction
 */

delete transaction_allocation
 where from_tran_id = @tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

delete campaign_transaction
 where tran_id = @tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Refresh Campaign Balances
 */

execute @errorode = p_ffin_campaign_balances @campaign_no
if (@errorode !=0)
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
