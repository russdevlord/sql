/****** Object:  StoredProcedure [dbo].[p_eom_account_statement_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_account_statement_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_account_statement_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  proc [dbo].[p_eom_account_statement_generation]  @accounting_period datetime

as

/*==============================================================*
 * DESC:- creates end-of-month statements.                      *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   5-Mar-2008 DH   Initial Build                           *
 *  2  11-Jun-2009 DH   fix bug with ageing of accounts with no *
 *                      transactions in the month.              *
 *                                                              *
 *==============================================================*/

set nocount on

/*
 * Declare Variables
 */

declare @account_statement_id			int,
        @account_id 					int,
        @invoice_id 					int,
        @balance_forward				money,
        @balance_outstanding			money,
        @balance_current				money,
        @balance_credit					money,
        @balance_30						money,
        @balance_60						money,
        @balance_90						money,
        @balance_120					money,
		@error							int,
		@errorode							int,
		@company_id						int,
		@campaign_no					int

/*
 * Build a temporary table containing invoices that have not appeared on a statement yet
 */

select 	inv.account_id,
		inv.invoice_id,
		inv.invoice_date,
		inv.invoice_total,
		convert(char(1),'I') AS tran_type,
		convert(int,null) AS tran_id,
		company_id
into 	#tmp_invoices
from 	invoice inv
where 	inv.account_statement_id is null

select 	@error = @@error
if @error <> 0
begin
	raiserror ('EOM ACCOUNT STATEMENT Error: Failed to create list of invoices', 16, 1)
	return -1
end 

/*
 * Include any Payments
 */

select 	ct.account_id, 
		convert(int,-1) AS invoice_id, 
		ct.entry_date, 
		ct.gross_amount * -1 as gross_amount, 
		convert(char(1),'P') AS tran_type, 
		ct.tran_id, 
		ct.tran_category, 
		nett_amount * -1 as nett_amount,
		gst_amount * -1 as gst_amount,
						case ac.country_code 
						when 'Z' then case business_unit_id when 11 then 9 else 2 end 
						else	case fc.business_unit_id 
							when 2 then 1
							when 3 then 1
							when 5 then 1
							when 6 then 3 
							when 7 then 4 
							when 8 then 5 
							when 11 then 8
							else 1 
						end 
					end as 'company_id'
into 	#tmp_payments
from 	campaign_transaction ct, 
		film_campaign fc,
		account ac
where 	ct.account_statement_id is null
and  	ct.tran_category = 'C'
and  	fc.campaign_no = ct.campaign_no 
and  	fc.campaign_status IN ('L','F')
and		ct.account_id = ac.account_id

select 	@error = @@error
if @error <> 0
begin
	raiserror ('EOM ACCOUNT STATEMENT Error: Failed to create list of payments', 16, 1)
	return -1
end 

/*
 * Begin Transaction
 */

begin transaction

/*
 * Clear the audits for this accounting_period (if this is a re-run). The audit is just a backup of the account balances prior to the statement run in case a re-run is required.
 * This audit step can be deleted at a later date if no longer required
 */

delete 	account_balance_audit 
where 	accounting_period = @accounting_period

select @error = @@error
if(@error !=0)
begin
	rollback transaction
	raiserror ('Error: Failed to Delete Account Statements ', 16, 1)
	return -1
end

/*
 * merge the payments with the invoices
 */

insert 	#tmp_invoices 
(		account_id,
		invoice_id,
		invoice_date,
		invoice_total,
		tran_type,
		tran_id,
		company_id)
select 	account_id,
		invoice_id,
		entry_date,
		gross_amount,
		tran_type,
		tran_id,
		company_id
from 	#tmp_payments


select @error = @@error
if(@error !=0)
begin
	rollback transaction
	raiserror ('Error: Failed to Merge Payments & Invoices', 16, 1)
	return -1
end

/*
 * Loop through the accounts and create the statements
 */

declare 	account_cursor cursor for 
select 		distinct account_id,
			company_id
from 		#tmp_invoices
group by 	account_id,
			company_id
order by 	account_id,
			company_id
for			read only

open account_cursor
fetch account_cursor into @account_id, @company_id
while (@@fetch_status = 0)
begin

	/*
	 * Get Seq No
	 */

	execute @errorode = p_get_sequence_number 'account_statement', 5, @account_statement_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
	    raiserror ('Failed to obtain Account Statement sequence no', 16, 1)
		return -1
	end
	
	/*
	 * Re-calculate the Account Balances
	 */

	EXECUTE @errorode = p_ffin_account_balances	@account_id,
												@company_id,
												
												@balance_curr = @balance_current OUTPUT,
												@balance_30 = @balance_30 OUTPUT,
												@balance_60 = @balance_60 OUTPUT,
												@balance_90 = @balance_90 OUTPUT,
												@balance_120 = @balance_120 OUTPUT,
												@balance_credit = @balance_credit OUTPUT,
												@balance_outstanding = @balance_outstanding OUTPUT


	if(@errorode !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to Create Account Statements - account balance proc', 16, 1)
		return -1
	end

	/*
	 * Create the Account Statement
	 */

	if @company_id = 1 or @company_id = 2 or @company_id = 5
	begin
		select 	@balance_forward = balance_outstanding
		from	account 
		where 	account_id = @account_id
	end
	else
	begin
		select 	@balance_forward = outpost_balance_outstanding
		from	account 
		where 	account_id = @account_id
	end

	insert into	account_statement 
		(	account_statement_id,
			account_id,
			company_id,
			accounting_period,
			balance_forward,
			balance_outstanding,
			balance_current,
			balance_30,
			balance_60,
			balance_90,
			balance_120,
			balance_credit,
			statement_name,
			address_1,
			address_2,
			town_suburb,
			state_code,
			postcode,
			statement_message,
			entry_date)
	SELECT 		@account_statement_id,
			@account_id,
			@company_id,
			@accounting_period,
			isnull(@balance_forward,0),
			isnull(@balance_outstanding,0),
			isnull(@balance_current,0),
			isnull(@balance_30,0),
			isnull(@balance_60,0),
			isnull(@balance_90,0),
			isnull(@balance_120,0),
			isnull(@balance_credit,0),
			ac.account_name,
			ac.address_1,
			ac.address_2,
			ac.town_suburb,
			ac.state_code,
			ac.postcode,
			NULL AS statement_message,
			getdate()
	FROM 	account ac
	WHERE 	account_id = @account_id

	select @error = @@error
	if(@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to Create Account Statements - INSERT account_statement', 16, 1)
		return -1
	end

	/*
	 * update the invocies
	 */

	update 	invoice 
	set 	account_statement_id = @account_statement_id 
	where 	account_id = @account_id 
	and		company_id = @company_id
	and 	account_statement_id is null

	select @error = @@error
	if(@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to Create Account Statements - UPDATE invoice', 16, 1)
		return -1
	end

	/*
	 * update the transactions
	 */

	update 	campaign_transaction 
	set 	account_statement_id = @account_statement_id 
	where 	account_id = @account_id 
	and 	account_statement_id is null
	and		invoice_id in (select invoice_id from invoice where account_statement_id = @account_statement_id)

	select @error = @@error
	if(@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to Create Account Statements - UPDATE campaign_transaction', 16, 1)
		return -1
	end

	/*
	 * Update the Account Balances
	 */

	if @company_id < 3 or @company_id = 8 or @company_id = 9
	begin
		update 	account
		set 	balance_forward = balance_outstanding,
				balance_outstanding = isnull(@balance_outstanding,0),
				balance_current = isnull(@balance_current,0),
				balance_30 = isnull(@balance_30,0),
				balance_60 = isnull(@balance_60,0),
				balance_90 = isnull(@balance_90,0),
				balance_120 = isnull(@balance_120,0),
				balance_credit = isnull(@balance_credit,0)
		where 	account_id = @account_id

		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror ('Error: Failed to Create Account Statements - Update account cinema balances', 16, 1)
			return -1
		end
	end
	else
	begin
		update 	account
		set 	outpost_balance_forward = outpost_balance_outstanding,
				outpost_balance_outstanding = isnull(@balance_outstanding,0),
				outpost_balance_current = isnull(@balance_current,0),
				outpost_balance_30 = isnull(@balance_30,0),
				outpost_balance_60 = isnull(@balance_60,0),
				outpost_balance_90 = isnull(@balance_90,0),
				outpost_balance_120 = isnull(@balance_120,0),
				outpost_balance_credit = isnull(@balance_credit,0)
		where 	account_id = @account_id

		select @error = @@error
		if(@error!=0)
		begin
			rollback transaction
			raiserror  ('Error: Failed to Create Account Statements - Update account retail balances', 16, 1)
			return -1
		end
	end

	fetch account_cursor into @account_id, @company_id
end

deallocate account_cursor

/*
 * Generate an Account Statement for accounts that had no activity this month but have a non-zero balance
 */

declare 	statement_generation_cursor cursor for 
select 		account_id,
			case country_code when 'A' then 1 else 2 end as company_id
from 		account 
where 		account_id NOT IN (	select 	distinct account_id 
								from 	#tmp_invoices
								where	company_id < 3) 
and 		balance_outstanding <> 0
union all
select 		account_id,
			3 as company_id	
from 		account 
where 		account_id NOT IN (	select 	distinct account_id 
								from 	#tmp_invoices 
								where	company_id = 3)
and 		outpost_balance_outstanding <> 0
union all
select 		account_id,
			4 as company_id	
from 		account 
where 		account_id NOT IN (	select 	distinct account_id 
								from 	#tmp_invoices 
								where	company_id = 4)
and 		outpost_balance_outstanding <> 0
union all
select 		account_id,
			6 as company_id	
from 		account 
where 		account_id NOT IN (	select 	distinct account_id 
								from 	#tmp_invoices 
								where	company_id = 6)
and 		outpost_balance_outstanding <> 0
union all
select 		account_id,
			7 as company_id	
from 		account 
where 		account_id NOT IN (	select 	distinct account_id 
								from 	#tmp_invoices 
								where	company_id = 7)
and 		outpost_balance_outstanding <> 0
union all
select 		account_id,
			case country_code when 'A' then 8 else 9 end as company_id
from 		account 
where 		account_id NOT IN (	select 	distinct account_id 
								from 	#tmp_invoices 
								where	company_id = 8 or company_id = 9)
and 		balance_outstanding <> 0
order by	account_id,
			company_id			
for			read only

open statement_generation_cursor
fetch statement_generation_cursor into @account_id, @company_id
while (@@fetch_status = 0)
begin


	/*
	 * Get Seq No
	 */

	execute @errorode = p_get_sequence_number 'account_statement', 5, @account_statement_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
	    raiserror ('Failed to obtain Account Statement sequence no', 16, 1)
		return -1
	end
	

	if @company_id < 3
	begin
	SELECT 		@balance_outstanding = balance_outstanding,
				@balance_forward = balance_forward,
				@balance_current = balance_current,
				@balance_30 = balance_30,
				@balance_60 = balance_60,
				@balance_90 = balance_90,
				@balance_120 = balance_120,
				@balance_credit = balance_credit 
		FROM 	account 
		WHERE 	account_id = @account_id
	
		/*
		 * Backup the account balances prior to this statement run
		 */
/*	
		insert 	account_balance_audit
		(		account_id,
				accounting_period,
				company_id, 
				balance_forward,
				balance_outstanding,
				balance_current,
				balance_30,
				balance_60,
				balance_90,
				balance_120,
				balance_credit)
		VALUES	(@account_id,
				@accounting_period,
				@company_id,
				@balance_forward,
				@balance_outstanding,
				@balance_current,
				@balance_30,
				@balance_60,
				@balance_90,
				@balance_120,
				@balance_credit)
	
		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror ('Error: Failed to Create Account Statements - INSERT account_balance_audit', 16, 1)
			return -1
		end
*/
		/*
 		 * Update the ageing in the Account
		 */
		
		UPDATE 	account
		SET 	balance_current = 0,
				balance_120 = isnull(@balance_120,0) + isnull(@balance_90,0),
				balance_90 = isnull(@balance_60,0),
				balance_60 = isnull(@balance_30,0),
				balance_30 = isnull(@balance_current,0)
		WHERE 	account_id = @account_id

		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror ('Error: Failed to Create Account Statements - INSERT account_statement 2', 16, 1)
			return -1
		end

		insert 	account_statement 
				(account_statement_id,
				account_id,
				company_id,
				accounting_period,
				balance_forward,
				balance_outstanding,
				balance_current,
				balance_30,
				balance_60,
				balance_90,
				balance_120,
				balance_credit,
				statement_name,
				address_1,
				address_2,
				town_suburb,
				state_code,
				postcode,
				statement_message,
				entry_date)
		SELECT 	@account_statement_id,
				@account_id,
				@company_id,
				@accounting_period,
				isnull(balance_forward,0),
				isnull(balance_outstanding,0),
				0,
				isnull(@balance_current,0),
				isnull(@balance_30,0),
				isnull(@balance_60,0),
				isnull(@balance_120,0) + isnull(@balance_90,0),
				isnull(balance_credit,0),
				account_name,
				address_1,
				address_2,
				town_suburb,
				state_code,
				postcode,
				NULL AS statement_message,
				getdate()
		FROM 	account
		WHERE 	account_id = @account_id
		
		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror ('Error: Failed to Create Account Statements - INSERT account_statement 3', 16, 1)
			return -1
		end
	end
	else
	begin
		SELECT 	@balance_outstanding = outpost_balance_outstanding,
				@balance_forward = outpost_balance_forward,
				@balance_current = outpost_balance_current,
				@balance_30 = outpost_balance_30,
				@balance_60 = outpost_balance_60,
				@balance_90 = outpost_balance_90,
				@balance_120 = outpost_balance_120,
				@balance_credit = outpost_balance_credit 
		FROM 	account 
		WHERE 	account_id = @account_id
		
		/*
		 * Backup the account balances prior to this statement run
		 */
	
/*		insert 	account_balance_audit
		(		account_id,
				accounting_period,
				company_id, 
				balance_forward,
				balance_outstanding,
				balance_current,
				balance_30,
				balance_60,
				balance_90,
				balance_120,
				balance_credit)
		VALUES	(@account_id,
				@accounting_period,
				@company_id,
				@balance_forward,
				@balance_outstanding,
				@balance_current,
				@balance_30,
				@balance_60,
				@balance_90,
				@balance_120,
				@balance_credit)
	
		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror  ('Error: Failed to Create Account Statements - INSERT account_balance_audit 4', 16, 1)
			return -1
		end

*/		/*
 		 * Update the ageing in the Account
		 */
		
		UPDATE 	account
		SET 	outpost_balance_current = 0,
				outpost_balance_120 = isnull(@balance_120,0) + isnull(@balance_90,0),
				outpost_balance_90 = isnull(@balance_60,0),
				outpost_balance_60 = isnull(@balance_30,0),
				outpost_balance_30 = isnull(@balance_current,0)
		WHERE 	account_id = @account_id

		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror ('Error: Failed to Create Account Statements - Update account', 16, 1)
			return -1
		end

		insert 	account_statement 
				(account_statement_id,
				account_id,
				company_id,
				accounting_period,
				balance_forward,
				balance_outstanding,
				balance_current,
				balance_30,
				balance_60,
				balance_90,
				balance_120,
				balance_credit,
				statement_name,
				address_1,
				address_2,
				town_suburb,
				state_code,
				postcode,
				statement_message,
				entry_date)
		SELECT 	@account_statement_id,
				@account_id,
				@company_id,
				@accounting_period,
				isnull(outpost_balance_forward,0),
				isnull(outpost_balance_outstanding,0),
				0,
				isnull(@balance_current,0),
				isnull(@balance_30,0),
				isnull(@balance_60,0),
				isnull(@balance_120,0) + isnull(@balance_90,0),
				isnull(outpost_balance_credit,0),
				account_name,
				address_1,
				address_2,
				town_suburb,
				state_code,
				postcode,
				NULL AS statement_message,
				getdate()
		FROM 	account
		WHERE 	account_id = @account_id
		
		select @error = @@error
		if(@error !=0)
		begin
			rollback transaction
			raiserror ('Error: Failed to Create Account Statements - INSERT account_statement', 16, 1)
			return -1
		end
	end

	fetch statement_generation_cursor into @account_id, @company_id
end

deallocate statement_generation_cursor

/*
 * clean-up
 */

--drop table #tmp_invoices
--drop table #tmp_payments

/*
 * Commit and Return
 */

commit transaction
return 0
GO
