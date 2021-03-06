/****** Object:  StoredProcedure [dbo].[p_ffin_account_balances]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_account_balances]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_account_balances]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_account_balances]		@account_id 			integer,
												@company_id				int,
												@balance_curr			money OUTPUT,
												@balance_30				money OUTPUT,
												@balance_60				money OUTPUT,
												@balance_90				money OUTPUT,
												@balance_120			money OUTPUT,
												@balance_credit			money OUTPUT,
												@balance_outstanding	money OUTPUT
as

declare					@error			integer



/*
 * Amount Owing
 */

select 		@balance_curr = IsNull(sum(ta.gross_amount),0)
from 		campaign_transaction ct,
			transaction_allocation ta,
			film_campaign fc,
			account acc
where 		ct.account_id = @account_id
and			ct.gross_amount > 0 
and			ct.age_code <= 0 
and			ct.tran_id = ta.to_tran_id 
and			fc.campaign_no = ct.campaign_no 
and			fc.campaign_status IN ('L','F')
and			ct.account_id = acc.account_id
and			((acc.country_code = 'A'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 1)
or 			(acc.country_code = 'Z'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 2)
or			(fc.business_unit_id = 6 
and			@company_id  = 3)
or			(fc.business_unit_id = 7 
and			@company_id  = 4)
or			(fc.business_unit_id = 8 
and			@company_id  = 6)
or			(fc.business_unit_id = 9
and			@company_id  = 5))

select 		@balance_30 = IsNull(sum(ta.gross_amount),0)
from 		campaign_transaction ct,
			transaction_allocation ta,
			film_campaign fc,
			account acc
where 		ct.account_id = @account_id 
and			ct.gross_amount > 0 
and			ct.age_code = 1 
and			ct.tran_id = ta.to_tran_id 
and			fc.campaign_no = ct.campaign_no 
and			fc.campaign_status IN ('L','F')
and			ct.account_id = acc.account_id
and			((acc.country_code = 'A'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 1)
or 			(acc.country_code = 'Z'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 2)
or			(fc.business_unit_id = 6 
and			@company_id  = 3)
or			(fc.business_unit_id = 7 
and			@company_id  = 4)
or			(fc.business_unit_id = 8 
and			@company_id  = 6)
or			(fc.business_unit_id = 9
and			@company_id  = 5))


select 		@balance_60 = IsNull(sum(ta.gross_amount),0)
from 		campaign_transaction ct,
			transaction_allocation ta,
			film_campaign fc,
			account acc
where 		ct.account_id = @account_id 
and			ct.gross_amount > 0 
and			ct.age_code = 2 
and			ct.tran_id = ta.to_tran_id 
and			fc.campaign_no = ct.campaign_no 
and			fc.campaign_status IN ('L','F')
and			ct.account_id = acc.account_id
and			((acc.country_code = 'A'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 1)
or 			(acc.country_code = 'Z'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 2)
or			(fc.business_unit_id = 6 
and			@company_id  = 3)
or			(fc.business_unit_id = 7 
and			@company_id  = 4)
or			(fc.business_unit_id = 8 
and			@company_id  = 6)
or			(fc.business_unit_id = 9
and			@company_id  = 5))


select 		@balance_90 = IsNull(sum(ta.gross_amount),0)
from 		campaign_transaction ct,
			transaction_allocation ta,
			film_campaign fc,
			account acc
where 		ct.account_id = @account_id 
and			ct.gross_amount > 0 
and			ct.age_code = 3 
and			ct.tran_id = ta.to_tran_id 
and			fc.campaign_no = ct.campaign_no 
and			fc.campaign_status IN ('L','F')
and			ct.account_id = acc.account_id
and			((acc.country_code = 'A'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 1)
or 			(acc.country_code = 'Z'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 2)
or			(fc.business_unit_id = 6 
and			@company_id  = 3)
or			(fc.business_unit_id = 7 
and			@company_id  = 4)
or			(fc.business_unit_id = 8 
and			@company_id  = 6)
or			(fc.business_unit_id = 9
and			@company_id  = 5))


select 		@balance_120 = IsNull(sum(ta.gross_amount),0)
from 		campaign_transaction ct,
			transaction_allocation ta,
			film_campaign fc,
			account acc
where 		ct.account_id = @account_id 
and			ct.gross_amount > 0 
and			ct.age_code = 4 
and			ct.tran_id = ta.to_tran_id 
and			fc.campaign_no = ct.campaign_no 
and			fc.campaign_status IN ('L','F')
and			ct.account_id = acc.account_id
and			((acc.country_code = 'A'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 1)
or 			(acc.country_code = 'Z'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 2)
or			(fc.business_unit_id = 6 
and			@company_id  = 3)
or			(fc.business_unit_id = 7 
and			@company_id  = 4)
or			(fc.business_unit_id = 8 
and			@company_id  = 6)
or			(fc.business_unit_id = 9
and			@company_id  = 5))


/*
* Amount in Credit
*/

select 		@balance_credit = 0 - IsNull(sum(ta.gross_amount),0)
from 		campaign_transaction ct,
			transaction_allocation ta,
			film_campaign fc,
			account acc
where 		ct.account_id = @account_id 
and			ct.gross_amount < 0 
and			ct.tran_id = ta.to_tran_id 
and			fc.campaign_no = ct.campaign_no 
and			fc.campaign_status IN ('L','F')
and			ct.account_id = acc.account_id
and			((acc.country_code = 'A'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 1)
or 			(acc.country_code = 'Z'
and			fc.business_unit_id not in (6,7,8,9)
and			@company_id  = 2)
or			(fc.business_unit_id = 6 
and			@company_id  = 3)
or			(fc.business_unit_id = 7 
and			@company_id  = 4)
or			(fc.business_unit_id = 8 
and			@company_id  = 6)
or			(fc.business_unit_id = 9
and			@company_id  = 5))


/*
 * Calculate Outstanding
 */

select @balance_outstanding = @balance_curr + @balance_30 + @balance_60	+ @balance_90 + @balance_120 + @balance_credit

return 0
GO
