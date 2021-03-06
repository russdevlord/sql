/****** Object:  StoredProcedure [dbo].[p_ffin_split_invoice]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_split_invoice]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_split_invoice]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc	 [dbo].[p_ffin_split_invoice]	@invoice_id			int
as
declare		@new_invoice_id		int,
					@new_total					money,
					@old_total					money,
					@account_id				int,
					@old_account_id		int,
					@error							int
					
declare 		transaction_csr cursor for
select			account_id,
					sum(gross_amount)
from			campaign_transaction 
where		invoice_id = @invoice_id
group by 	account_id
for 				read only

	
select @old_account_id = account_id from invoice where invoice_id = @invoice_id			

begin transaction

open transaction_csr 
fetch transaction_csr into @account_id, @new_total
while(@@fetch_status = 0)
begin

	if @old_account_id <> @account_id
	begin
	
		exec @error = p_get_sequence_number 'invoice', 1, @new_invoice_id OUTPUT
		
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error obtaining new invoice id', 16, 1)
			return -1
		end
		
		insert into invoice
		(invoice_id, account_id, invoice_status, invoice_date, invoice_total, invoice_balance, account_statement_id, company_id)
		select 	@new_invoice_id, @account_id,invoice_status, invoice_date, @new_total, null, account_statement_id, company_id
		from 		invoice 
		where 	invoice_id = @invoice_id
		
		select @error = @@error
		
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error updating inserting new invoice', 16, 1)
			return -1
		end
		
		update campaign_transaction
		set invoice_id = @new_invoice_id
		where invoice_id = @invoice_id
		and	account_id = @account_id
		
		select @error = @@error
		
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error updating inserting new invoice', 16, 1)
			return -1
		end
		
	end
	else
	begin
		update 	invoice
		set 			invoice_total = @new_total
		where	invoice_id = @invoice_id
		
		select @error = @@error
		
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error updating original invoice', 16, 1)
			return -1
		end
	end

	fetch transaction_csr into @account_id, @new_total
end

commit transaction
return 0
GO
