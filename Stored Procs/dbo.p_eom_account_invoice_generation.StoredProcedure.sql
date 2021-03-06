/****** Object:  StoredProcedure [dbo].[p_eom_account_invoice_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_account_invoice_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_account_invoice_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

create  proc [dbo].[p_eom_account_invoice_generation]  @accounting_period datetime
as
set nocount on

/*
 * Declare Variables
 */
 
declare			@account_id 				int,
						@invoice_id 				int,
						@company_id				int,
						@campaign_no			int,
						@errorode						int

/*
 * Begin Transaction
 */ 
 
begin transaction

/*
 * Build a temporary table containing outstanding transactions for active campaigns
 */

select 			ct.tran_id, 
   				ct.account_id,
				case fc.business_unit_id 
					when 6 then 3 
					when 7 then 4 
					when 9 then case b.country_code when 'Z' then 7 else 5 end
					when 8 then 6
					when 11 then case b.country_code when 'Z' then 9 else 8 end
					else	case b.country_code 
								when 'Z' then 2 
								else	1 
							end 
				end as 'company_id',
				ct.campaign_no
into 			#tmp_account
from 			campaign_transaction ct, 
				film_campaign fc,
				branch b,
				account ac
where			ct.account_statement_id is null
and  			ct.invoice_id is null
and  			ct.tran_category <> 'C'
and  			ct.campaign_no = fc.campaign_no
and				ct.account_id = ac.account_id
and  			fc.campaign_status IN ('L','F')
and				fc.branch_code = b.branch_code
order by 		ct.account_id,
				ct.tran_id
					
/*
 * create the invoices
 */
 
declare			account_cursor cursor for 
select			distinct account_id,
				company_id,
				campaign_no 
from 			#tmp_account 
order by		account_id,
				company_id
for				read only

open account_cursor
fetch account_cursor into @account_id, @company_id, @campaign_no

while @@fetch_status = 0
begin
	execute @errorode = p_get_sequence_number 'invoice', 5, @invoice_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('p_eom_account_invoice_generation: Get invoice ID failed.', 16, 1)
		return -1
	end
	
	insert 	invoice (
		invoice_id,
		account_id,
		invoice_date,
		invoice_total,
		company_id) 
	SELECT 	@invoice_id,
		@account_id,
		@accounting_period,
		isnull(sum(gross_amount),0),
		@company_id
	from 	campaign_transaction 
	where 	tran_id IN (	select	tran_id 
				from	#tmp_account 
				where 	account_id = @account_id
				and	company_id = @company_id
				and	campaign_no = @campaign_no
				and  show_on_statement = 'Y') 

	select @errorode = @@error				
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('p_eom_account_invoice_generation: Get invoice ID failed.', 16, 1)
		return -1
	end
	
	
	update 	campaign_transaction 
	set 	invoice_id = @invoice_id
	where 	tran_id IN (	select	tran_id 
				from 	#tmp_account 
				where 	account_id = @account_id
				and	company_id = @company_id
				and	campaign_no = @campaign_no) 

	select @errorode = @@error				
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('p_eom_account_invoice_generation: Get invoice ID failed.', 16, 1)
		return -1
	end
	
		insert into invoice_comments
		select @invoice_id, notes
		from film_campaign_standalone_invoice
		where campaign_no = @campaign_no
		and notes is not null
		
	select @errorode = @@error				
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('p_eom_account_invoice_generation: Get invoice ID failed.', 16, 1)
		return -1
	end
	
						

	fetch account_cursor into @account_id, @company_id, @campaign_no 
end

close account_cursor
deallocate account_cursor


/*
 * clean-up
 */
 
 commit transaction
drop table #tmp_account
return 0
GO
