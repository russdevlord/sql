/****** Object:  StoredProcedure [dbo].[p_ffin_create_transaction]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_create_transaction]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_create_transaction]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_create_transaction]	@tran_type_code     char(5),
										@campaign_no	    int,
										@account_id			int,
										@tran_date 		    datetime,
										@tran_desc          varchar(255),
                                        @tran_notes         varchar(255),
										@nett_amount	    money,
										@opt_gst_rate       decimal(6,4),
										@show_on_statement	char(1),
										@tran_id			int OUTPUT
as

/*
 * Declare Variables
 */
                                                                                                                      
declare @tran_type					int,
        @gst_amount					money,
        @gross_amount				money,
        @errorode						int,
        @allocation_id				int,
        @from_tran_id				int, 
        @to_tran_id					int,
        @pay_gst					money,
        @error						int,
        @gst_rate					decimal(6,4),
        @new_gst_rate				decimal(6,4),
        @changeover_date			datetime,
        @tran_category				char(1),
        @gst_exempt					char(1),
        @currency_code				char(3)

/*
 * Setup Currency and GST
 */

select 	@tran_category = tran_category_code,
	   	@tran_type = trantype_id,
       	@gst_exempt = gst_exempt
from 	transaction_type
where 	trantype_code = @tran_type_code

if (@@error !=0)
begin
    raiserror ('Error initisalising values to create Film Transaction', 16, 1)
	return -1
end	

select	@currency_code = currency_code,
		@gst_rate = gst_rate,
		@new_gst_rate = new_gst_rate,
		@changeover_date = changeover_date
from	country, 
		branch,
		film_campaign
where 	film_campaign.campaign_no = @campaign_no 
and		film_campaign.branch_code = branch.branch_code 
and		branch.country_code = country.country_code

if (@@error !=0)
begin
    raiserror ('Error initisalising values to create Film Transaction', 16, 1)
	return -1
end	

if @opt_gst_rate is not null
	select @gst_rate = @opt_gst_rate

if @opt_gst_rate is null and @tran_date >= @changeover_date
	select @gst_rate = @new_gst_rate		

if @gst_exempt = 'Y'
	select @gst_rate = 0.0

/*
 *	Calculate Gross Amount
 */

if @tran_category = 'C' or @tran_category = 'X' --Active Credit or Cash Transfer
begin
	select @gross_amount = @nett_amount
	select @nett_amount = 0
	select @gst_amount = 0
end
else
begin
	select @gst_amount = (round(@nett_amount * @gst_rate,2))
	select @gross_amount = @nett_amount + @gst_amount
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
    raiserror ('Failed to obtain Film Transaction sequence no', 16, 1)
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
		tran_notes,
		tran_age,
		nett_amount,
		gst_amount,
		gst_rate,
		gross_amount,
		show_on_statement,
		reversal,
		entry_date,
		account_id) values (
		@tran_id,
		@tran_type,
		@tran_category,
		null,
		@campaign_no,
		-1,
		@currency_code,
		@tran_date,
		@tran_desc,
		@tran_notes,
		-1,
		@nett_amount,
		@gst_amount,
		@gst_rate,
		@gross_amount,
		@show_on_statement,
		'N',
		convert(datetime,convert(varchar(12),getdate(),102)),
		@account_id )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('Failed to create Film Transaction', 16, 1)
	return -1
end	

/*
 * Create the Control allocation record for this transaction.	
 */

if @gross_amount >= 0
	select @to_tran_id = @tran_id
else
	select @from_tran_id = @tran_id

/*
 * Pay GST Based on the Allocation Record
 */

select @pay_gst = @gst_amount

/*
 * Create Allocation Header Record
 */

execute @errorode = p_get_sequence_number 'transaction_allocation', 5, @allocation_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('Failed to obtain Film Transaction Allocation sequence no', 16, 1)
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
       abs(@nett_amount),
       abs(@gst_amount),
       @gst_rate,
       abs(@gross_amount),
       0,
       @pay_gst,
       null,
       convert(datetime,convert(varchar(12),getdate(),102)) )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('Failed to create Film Transaction Allocation', 16, 1)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
