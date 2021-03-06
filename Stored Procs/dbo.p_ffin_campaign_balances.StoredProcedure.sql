/****** Object:  StoredProcedure [dbo].[p_ffin_campaign_balances]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_campaign_balances]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_campaign_balances]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_campaign_balances] @campaign_no 	integer
as

/*
 * Declare Variables
 */

declare @balance_curr				money,
        @balance_30					money,
        @balance_60					money,
        @balance_90					money,
        @balance_120				money,
        @balance_credit				money,
        @balance_outstanding		money,
        @error						integer

/*
 * Amount Owing
 */

select @balance_curr = IsNull(sum(ta.gross_amount),0)
    from campaign_transaction ct,
         transaction_allocation ta
   where ct.campaign_no = @campaign_no and
         ct.gross_amount > 0 and
         ct.age_code <= 0 and
         ct.tran_id = ta.to_tran_id 


select @balance_30 = IsNull(sum(ta.gross_amount),0)
    from campaign_transaction ct,
         transaction_allocation ta
   where ct.campaign_no = @campaign_no and
         ct.gross_amount > 0 and
         ct.age_code = 1 and
         ct.tran_id = ta.to_tran_id 


select @balance_60 = IsNull(sum(ta.gross_amount),0)
    from campaign_transaction ct,
         transaction_allocation ta
   where ct.campaign_no = @campaign_no and
         ct.gross_amount > 0 and
         ct.age_code = 2 and
         ct.tran_id = ta.to_tran_id 


select @balance_90 = IsNull(sum(ta.gross_amount),0)
    from campaign_transaction ct,
         transaction_allocation ta
   where ct.campaign_no = @campaign_no and
         ct.gross_amount > 0 and
         ct.age_code = 3 and
         ct.tran_id = ta.to_tran_id 


select @balance_120 = IsNull(sum(ta.gross_amount),0)
    from campaign_transaction ct,
         transaction_allocation ta
   where ct.campaign_no = @campaign_no and
         ct.gross_amount > 0 and
         ct.age_code = 4 and
         ct.tran_id = ta.to_tran_id 

/*
 * Amount in Credit
 */

select @balance_credit = 0 - IsNull(sum(ta.gross_amount),0)
  from campaign_transaction ct,
       transaction_allocation ta
 where ct.campaign_no = @campaign_no and
       ct.gross_amount < 0 and
       ct.tran_id = ta.from_tran_id 


/*
 * Calculate Outstanding
 */

select @balance_outstanding = @balance_curr + @balance_30 + @balance_60	+ @balance_90 + @balance_120 + @balance_credit

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Film Campaign
 */

update film_campaign
   set balance_credit = @balance_credit,
       balance_current = @balance_curr,
       balance_30 = @balance_30,
       balance_60 = @balance_60,
       balance_90 = @balance_90,
       balance_120 = @balance_120,
       balance_outstanding = @balance_outstanding
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
  	raiserror ('p_ffin_campaign_balances: Failed to Update Balances for Campaign %1!', 11, 1, @campaign_no)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
