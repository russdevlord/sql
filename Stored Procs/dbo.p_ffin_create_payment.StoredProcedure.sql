/****** Object:  StoredProcedure [dbo].[p_ffin_create_payment]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_create_payment]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_create_payment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_create_payment] 	@campaign_no	 		int,
									@account_id				int,		
									@tran_date 		 		datetime,
									@tran_desc      		varchar(100),
									@payment_amount	 		money,
									@cheque_payee			varchar(100),
									@cheque_no				char(10),
									@cheque_date			datetime,
									@tran_id			 	int OUTPUT
as

/*
 * Declare Variables
 */

declare @tran_type					int,
        @errorode						int,
        @allocation_id				int,
        @from_tran_id				int, 
        @to_tran_id					int,
        @pay_gst					money,
        @error						int,
        @tran_category				char(1),
        @currency_code				char(3)

/*
 * Setup Currency and GST
 */

select @tran_category = tran_category_code,
	   @tran_type = trantype_id
  from transaction_type
 where trantype_code = 'FPAY'

if (@@error !=0)
begin
    raiserror ('Error: Failed to create payment', 16, 1)
	return -1
end	

select @currency_code = currency_code
  from country, 
       branch,
       film_campaign
 where film_campaign.campaign_no = @campaign_no and
	   film_campaign.branch_code = branch.branch_code and
       branch.country_code = country.country_code

if (@@error !=0)
begin
    raiserror ('Error: Failed to create payment', 16, 1)
	return -1
end	

/*
 *	Begin Transaction
 */

begin transaction

/*
 *	Create Transaction
 */

execute @errorode = p_get_sequence_number 'campaign_transaction', 5, @tran_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('Error: Failed to create payment', 16, 1)
    return -1
end

insert into campaign_transaction (
		tran_id,
		tran_type,
		tran_category,
		statement_id,
		campaign_no,
		age_code,
		currency_code,
		tran_date,
		tran_desc,
		tran_age,
		nett_amount,
		gst_amount,
		gst_rate,
		gross_amount,
		cheque_payee,
		cheque_no,
		cheque_date,
		show_on_statement,
		reversal,
		entry_date,
		account_id ) values (
		@tran_id,
		@tran_type,
		@tran_category,
		null,
		@campaign_no,
		-1,
		@currency_code,
		@tran_date,
		@tran_desc,
		-1,
		0.0,
		0,
		0.0,
		@payment_amount,
		@cheque_payee,
		@cheque_no,
		@cheque_date,
		'Y',
		'N',
		convert(datetime,convert(varchar(12),getdate(),102)) ,
		@account_id)

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('Error: Failed to create payment', 16, 1)
    return -1
end	

/*
 * Create the Control allocation record for this transaction.	
 */

if @payment_amount >= 0
	select @to_tran_id = @tran_id
else
	select @from_tran_id = @tran_id

execute @errorode = p_get_sequence_number 'transaction_allocation', 5, @allocation_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('Error: Failed to allocate payment', 16, 1)
    return -1
end

insert into transaction_allocation (
       allocation_id,
       from_tran_id,
       to_tran_id,
       nett_amount,
       gst_amount,
       gst_rate,
       gross_amount,
       alloc_amount,
       pay_gst,
       process_period,
       entry_date ) values (
       @allocation_id,
       @from_tran_id, 
       @to_tran_id,
       0.0,
       0,
       0.0,
       abs(@payment_amount),
       0,
       0.0,
       null,
       convert(datetime,convert(varchar(12),getdate(),102)) )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('Error: Failed to allocate payment'    , 16, 1)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
