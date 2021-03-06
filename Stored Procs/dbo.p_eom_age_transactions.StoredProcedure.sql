/****** Object:  StoredProcedure [dbo].[p_eom_age_transactions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_age_transactions]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_age_transactions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_age_transactions] @campaign_no		integer
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @max_age						int

/*
 * Determine the Maximum Age Balance
 */

select @max_age = max(age_code)
  from aged_balance

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0 or @rowcount=0)
begin
	raiserror ('Error', 16, 1)
	return -1
end	

/*
 * Begin Transaction
 */

begin transaction

/*
 * Age Transactions
 */

update campaign_transaction
   set tran_age = tran_age + 1
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
  	raiserror ('Error: Failed to Age Transactions for Campaign %1!',11,1, @campaign_no)
	return @error
end	

update campaign_transaction
   set age_code = age_code + 1
 where age_code < @max_age and
       campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
  	raiserror ('Error: Failed to Age Transactions for Campaign %1!',11,1, @campaign_no)
	return @error
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
