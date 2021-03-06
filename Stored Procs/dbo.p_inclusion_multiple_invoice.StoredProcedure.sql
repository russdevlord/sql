/****** Object:  StoredProcedure [dbo].[p_inclusion_multiple_invoice]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_multiple_invoice]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_multiple_invoice]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_inclusion_multiple_invoice]		@inclusions			varchar(max)

as

declare		@error					int,
			@campaign_no			int,
			@billing_period			datetime,
			@campaign_count			int,
			@account_count			int,
			@invoice_count			int,
			@inclusion_id			int,
			@tran_id				int,
			@invoice_id				int,
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
			@alloc_date				datetime
			
set nocount on

create table #inclusions
(
	inclusion_id			int		not null
)

create table #inclusion_transactions
(
	inclusion_id			int		not null,
	tran_id					int		not null
)

create table #inclusion_commissions
(
	inclusion_id			int		not null,
	tran_id					int		not null
)

if len(@inclusions) > 0                
	insert into #inclusions                
	select * from dbo.f_multivalue_parameter(@inclusions,',')    


--make sure its from only 1 campaign
select			@campaign_count = count(distinct campaign_no)
from			inclusion 
inner join		#inclusions on inclusion.inclusion_id = #inclusions.inclusion_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to correctly determine campaign count of selected inclusions', 16, 1)
	return -1
end

if @campaign_count <> 1
begin
	raiserror ('Error: You can only combine inclusions from the one camapign', 16, 1)
	return -1
end


--make sure its from only 1 account
select			@account_count = count(distinct isnull(account_no, 0))
from			inclusion 
inner join		#inclusions on inclusion.inclusion_id = #inclusions.inclusion_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to correctly determine account count of selected inclusions', 16, 1)
	return -1
end

if @account_count <> 1
begin
	raiserror ('Error: You can only combine inclusions from the one account', 16, 1)
	return -1
end


--make sure not already invoiced
select			@invoice_count = count(*)
from			inclusion 
inner join		#inclusions on inclusion.inclusion_id = #inclusions.inclusion_id
where			tran_id is not null

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to correctly determine invoice status of selected inclusions', 16, 1)
	return -1
end

if @invoice_count <> 0
begin
	raiserror ('Error: You can only combine inclusions that have not invoiced fghfg', 16, 1)
	return -1
end


--determine the billing period to use
select			@billing_period = min(billing_period)
from			inclusion 
inner join		#inclusions on inclusion.inclusion_id = #inclusions.inclusion_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to correctly determine min billing period of selected inclusions', 16, 1)
	return -1
end

if @billing_period is null
begin
	select			@billing_period = min(end_date)
	from			accounting_period 
	where			status = 'O'

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error: Failed to correctly determine min billing period of selected inclusions', 16, 1)
		return -1
	end
end


--determine allocation date
select @alloc_date = getdate()		


--begin transaction
begin transaction


--create transactions for each inclusion
declare			inclusion_csr cursor for
select			inclusion_id
from			#inclusions
order by		inclusion_id

open inclusion_csr
fetch inclusion_csr into @inclusion_id
while(@@FETCH_STATUS=0)
begin
	select	@campaign_no = inc.campaign_no,
			@account_no = inc.account_no,
			@inclusion_desc = inc.inclusion_desc,
			@inclusion_qty = inc.inclusion_qty,
			@inclusion_charge = inc.inclusion_charge,
			@tran_code = tt.trantype_code,
			@commission = inc.commission,
			@account_no = inc.account_no
	from 	inclusion inc,
			inclusion_type_category_xref inc_xref,
			transaction_type tt
	where 	inc.inclusion_id = @inclusion_id and
			inc_xref.trantype_id = tt.trantype_id and
			inc_xref.inclusion_type = inc.inclusion_type and
			inc_xref.inclusion_category = inc.inclusion_category

	-- get the Campaign Billing Account No. when the inclusion is not re-assigned to another account
	-- and get Company ID based on film campaign
	select	@account_no = onscreen_account_id
	from	film_campaign
	where	campaign_no = @campaign_no
	and		@account_no is null

	
	--Calculate Nett Total
	select @nett_charge = @inclusion_qty * @inclusion_charge
 
	
	--Create Transaction
	exec @error = p_ffin_create_transaction @tran_code,
											@campaign_no,
											@account_no,
											@billing_period,
											@inclusion_desc,
											null,
											@nett_charge,
											null,
											'Y',
											@tran_id OUTPUT

	if(@error !=0)
	begin
		raiserror ('Failed to create transaction', 16, 1)
		rollback transaction
		return -1
	end

	 insert into #inclusion_transactions values (@inclusion_id, @tran_id)

	--commission
	if @commission > 0
	begin
		select @inclusion_desc = @inclusion_desc + ' A\Comm' 
		select @nett_charge = @nett_charge * @commission * -1
		--Create Transaction
		exec @error = p_ffin_create_transaction 'KTACM',
												@campaign_no,
												@account_no,
												@billing_period,									
												@inclusion_desc ,
												null,
												@nett_charge,
												null,
												'Y',
												@child_tran_id OUTPUT

		if(@error !=0)
		begin
			raiserror ('Failed to create commision transaction', 16, 1)
			rollback transaction
			return -1
		end

		 --Allocate Agency Commision to Billing
		 exec @error = p_ffin_allocate_transaction @child_tran_id, @tran_id, @nett_charge, @alloc_date
	 
		 if(@error !=0)
		 begin
			raiserror ('Failed to allocate commision transaction', 16, 1)
			rollback transaction
			return -1
		 end

		 insert into #inclusion_commissions values (@inclusion_id, @child_tran_id)
	 end



	fetch inclusion_csr into @inclusion_id
end


--create the invoice record
exec @error = p_get_sequence_number 'invoice', 10, @next_invoice OUTPUT

if @error <> 0
begin
	raiserror ('Error: Failed to correctly determine invoice sequence number', 16, 1)
	return -1
end


select			@company_id = (	CASE	branch_code when 'Z' then case  business_unit_id when 9 then 7 when 8 then 6 else 2 end
								else	case business_unit_id 
										when 6 then 3 
										when 7 then 4 
										when 9 then 5
										when 11 then 8
										else 1 
									end 
								end)
from			film_campaign
where			campaign_no = @campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to correctly determine company of selected inclusions', 16, 1)
	return -1
end

insert into		invoice 
				(invoice_id, 
				account_id, 
				invoice_date, 
				invoice_total, 
				company_id)
select			@next_invoice, 
				@account_no, 
				@alloc_date, 
				sum(gross_amount),
				@company_id
from			campaign_transaction 
inner join		#inclusion_transactions on campaign_transaction.tran_id = #inclusion_transactions.tran_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to insert invoice record', 16, 1)
	rollback transaction
	return -1
end


--update campaign_transaction with invoice id
update			campaign_transaction 
set				invoice_id = @next_invoice, 
				account_id = @account_no
from			campaign_transaction
inner join		#inclusion_transactions on campaign_transaction.tran_id = #inclusion_transactions.tran_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to update campaign transaction record', 16, 1)
	rollback transaction
	return -1
end


--update commission with invoice id
update			campaign_transaction 
set				invoice_id = @next_invoice, 
				account_id = @account_no
from			campaign_transaction
inner join		#inclusion_commissions on campaign_transaction.tran_id = #inclusion_commissions.tran_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to update campaign transaction record', 16, 1)
	rollback transaction
	return -1
end


--update inclusion to point to new campaign_transaction
update			inclusion 
set				tran_id = #inclusion_transactions.tran_id
from			inclusion
inner join		#inclusion_transactions on inclusion.inclusion_id = #inclusion_transactions.inclusion_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Failed to update inclusion', 16, 1)
	rollback transaction
	return -1
end


--Allocate Advanced Payments
exec @error = p_ffin_payment_allocation @campaign_no

if @error <> 0 
begin
	raiserror ('Error: Failed to allocate outstanding payments', 16, 1)
	rollback transaction
	return -1
end


--commit and return
commit transaction
return 0
GO
