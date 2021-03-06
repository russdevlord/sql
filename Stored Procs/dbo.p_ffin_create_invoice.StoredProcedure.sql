/****** Object:  StoredProcedure [dbo].[p_ffin_create_invoice]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_create_invoice]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_create_invoice]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE    PROC [dbo].[p_ffin_create_invoice] 	@inclusion_id		int,
	                                  			@tran_id			int OUTPUT,
	                                  			@invoice_id			int OUTPUT
as

/*==============================================================*
 * DESC:- creates an invoice for a selected inclusion           *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   5-Mar-2008 DH  Initial Build                            *
 *                                                              *
 *==============================================================*/

set nocount on

declare 	@errorode				int,
			@error					int,
			@campaign_no			int,
			@accounting_period		datetime,
			@inclusion_desc			varchar(255),
			@inclusion_qty			int,
			@inclusion_charge		money,
			@tran_code				char(5),
			@commission				numeric(6,4),
			@nett_charge			money,
			@child_tran_id			int,
			@account_no				int,
			@next_invoice			int,
			@company_id				int,
			@error_string			varchar(255),
			@alloc_date				datetime,
			@trantype_code			char(5)


begin transaction

select			@campaign_no = inc.campaign_no,
				@accounting_period = inc.billing_period,
				@inclusion_desc = inc.inclusion_desc,
				@inclusion_qty = inc.inclusion_qty,
				@inclusion_charge = inc.inclusion_charge,
				@tran_code = tt.trantype_code,
				@commission = inc.commission,
				@account_no = inc.account_no
from 			inclusion inc,
				inclusion_type_category_xref inc_xref,
				transaction_type tt
where 			inc.inclusion_id = @inclusion_id 
and				inc_xref.trantype_id = tt.trantype_id 
and				inc_xref.inclusion_type = inc.inclusion_type 
and				inc_xref.inclusion_category = inc.inclusion_category
		
select @alloc_date = getdate()		

-- get the Campaign Billing Account No. when the inclusion is not re-assigned to another account
-- and get Company ID based on film campaign
select	@account_no = onscreen_account_id
from	film_campaign
where	campaign_no = @campaign_no
and		@account_no is null

--Calculate Nett Total
select @nett_charge = @inclusion_qty * @inclusion_charge
 
--Create Transaction
exec @errorode = p_ffin_create_transaction @tran_code,
										@campaign_no,
										@account_no,
										@accounting_period,
										@inclusion_desc,
										null,
										@nett_charge,
										null,
										'Y',
										@tran_id OUTPUT

if(@errorode !=0)
begin
	rollback transaction
	goto error
end

--create the invoice record
exec p_get_sequence_number 'invoice', 10, @next_invoice OUTPUT

select	@company_id = (	CASE	branch_code when 'Z' then case  business_unit_id when 11 then 9 when 9 then 7 when 8 then 6 else 2 end
						else	case business_unit_id 
								when 6 then 3 
								when 7 then 4 
								when 9 then 5
								when 11 then 8
								else 1 
							end 
						end)
from	film_campaign
where	campaign_no = @campaign_no

insert	invoice (invoice_id, account_id, invoice_date, invoice_total, company_id )
select	@next_invoice, @account_no, getdate(), gross_amount, @company_id
from	campaign_transaction 
where	tran_id = @tran_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to insert invoice record', 16, 1)
	rollback transaction
	return -1
end

select @invoice_id = @next_invoice

--update campaign_transaction with invoice id
update	campaign_transaction 
set		invoice_id = @next_invoice, 
		account_id = @account_no
where	tran_id = @tran_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to update campaign transaction record', 16, 1)
	rollback transaction
	return -1
end

--update inclusion to point to new campaign_transaction
update	inclusion 
set		tran_id = @tran_id 
where	inclusion_id = @inclusion_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to update inclusion', 16, 1)
	rollback transaction
	return -1
end

--commission
if @commission > 0
begin

	select @trantype_code = 'KTACM'

	if @tran_code = 'FANBI' 
		select @trantype_code = 'FANAC'
	if @tran_code = 'LLABI' 
		select @trantype_code = 'LLAAC'
	if @tran_code = 'TLABI' 
		select @trantype_code = 'TLAAC'
	if @tran_code = 'PLABI' 
		select @trantype_code = 'PLAAC'

	select @inclusion_desc = @inclusion_desc + ' A\Comm' 
	select @nett_charge = @nett_charge * @commission * -1
	--Create Transaction
	exec @errorode = p_ffin_create_transaction @trantype_code,
											@campaign_no,
											@account_no,
											@accounting_period,									
											@inclusion_desc ,
											null,
											@nett_charge,
											null,
											'Y',
											@child_tran_id OUTPUT

	if(@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	if( @account_no <> Null ) 
		BEGIN
			--underlying transaction was assigned to a different account - assign this commission record to that account as well
			update	campaign_transaction 
			set		invoice_id = @next_invoice, 
					account_id = @account_no
			where	tran_id = @child_tran_id

			select @error = @@error
			if @error <> 0 
			begin
				raiserror ('Error: Failed to update commision transaction', 16, 1)
				rollback transaction
				return -1
			end

		END

	 --Allocate Agency Commision to Billing
	 exec @errorode = p_ffin_allocate_transaction @child_tran_id, @tran_id, @nett_charge, @alloc_date
	 
	 if(@errorode !=0)
	 begin
		 rollback transaction
		 goto error
	 end
 end
 
--Allocate Advanced Payments
exec @errorode = p_ffin_payment_allocation @campaign_no

if(@errorode !=0)
begin
	rollback transaction
	goto error
end

commit transaction
return 0

error:
	 raiserror ('Error: Failed to Generate Inclusion Billings for Campaign %1!', 11, 1, @campaign_no)
	 return -1
GO
