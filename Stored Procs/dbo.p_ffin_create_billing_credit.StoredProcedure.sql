/****** Object:  StoredProcedure [dbo].[p_ffin_create_billing_credit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_create_billing_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_create_billing_credit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_ffin_create_billing_credit] @billing_tran_id	    int,
                                  		 @credit_amount	    	money
as

/*
 * Declare Variables
 */

declare @error						int,
		@acomm_tran_id		    	int,
		@sqlstatus			    	int,
        @new_bill_id				int,
        @new_acomm_id				int,
        @acomm_amount				money,
        @errorode						int,
        @tran_type					smallint,
        @tran_desc					varchar(50),
        @rowcount					int,
        @nett_amount				money,
        @gst_amount					money,
        @gst_rate					numeric(6,4),
        @money_pass					money,
		@campaign_no				int,
		@tran_id					int,
		@trantype_code				varchar(5),
		@new_bill_code		    	varchar(5),
		@new_acomm_code	    		varchar(5),
		@tran_date					datetime,
        @tran_cat_code              char(1),
		@agency_comm	    		numeric(6,4),
		@account_id					int,
		@alloc_date					datetime

/*
 * Transform Credit Amount
 */

if(@credit_amount > 0)
	select @credit_amount = (@credit_amount * -1)

/*
 * Get Transaction Information
 */
 
select @tran_date = getdate()



select @gst_rate = ct.gst_rate,
       @nett_amount = ct.nett_amount,
	   @campaign_no = ct.campaign_no, 
	   @tran_type = ct.tran_type,
       @trantype_code = tt.trantype_code,
       @tran_cat_code = tt.tran_category_code,
	   @account_id = ct.account_id
  from campaign_transaction ct,
       transaction_type tt
 where ct.tran_id = @billing_tran_id
   and tt.trantype_id = ct.tran_type

if(@tran_cat_code <> 'B' or @nett_amount < 0)
begin
	raiserror ( 'Transaction is not a Billing and/or is a Reversal', 16, 1)
	return -1
end

select 	@agency_comm = commission
from	film_campaign
where 	campaign_no = @campaign_no

select 	@acomm_tran_id = tran_id
from 	transaction_allocation,
		campaign_transaction 
where	to_tran_id = @billing_tran_id
and		from_tran_id = campaign_transaction.tran_id
and		campaign_transaction.tran_category = 'Z'

/*
 * Begin Transaction
 */

begin transaction

/*
 * Determine Source Transaction Type
 */

if(@trantype_code = 'FBILL')
    select @new_bill_code = 'FBCRD',
           @new_acomm_code = 'FACOM'
else if(@trantype_code = 'DBILL')
    select @new_bill_code = 'DBCRD',
           @new_acomm_code = 'DACOM'
else if(@trantype_code = 'CBILL')
    select @new_bill_code = 'CBCRD',
           @new_acomm_code = 'CACOM'
else if(@trantype_code = 'IBILL')
    select @new_bill_code = 'IBCRD',
           @new_acomm_code = 'IACOM'
else if(@trantype_code = 'RBILL')
    select @new_bill_code = 'RBCRD',
           @new_acomm_code = 'RACOM'
else if(@trantype_code = 'RWLBI')
    select @new_bill_code = 'RWBCD',
           @new_acomm_code = 'RWLAC'
else if(@trantype_code = 'ABILL')
    select @new_bill_code = 'ABCRD',
           @new_acomm_code = 'AACOM'
else if(@trantype_code = 'TBILL')
    select @new_bill_code = 'TBCRD',
           @new_acomm_code = 'TACOM'
else if(@trantype_code = 'FANBI')
    select @new_bill_code = 'FANBC',
           @new_acomm_code = 'FANAC'
else if(@trantype_code = 'LLABI')
    select @new_bill_code = 'LLABC',
           @new_acomm_code = 'LLAAC'
else if(@trantype_code = 'TLABI')
    select @new_bill_code = 'TLABC',
           @new_acomm_code = 'TLAAC'
else if(@trantype_code = 'PLABI')
    select @new_bill_code = 'PLABC',
           @new_acomm_code = 'PLAAC'
           
/*
 * Create Credit Transaction
 */

select @tran_desc = 'Billing Credit - Reference: ' + convert(varchar(10),@billing_tran_id)

execute @errorode = p_ffin_create_transaction @new_bill_code, @campaign_no, @account_id, @tran_date, @tran_desc, null, @credit_amount, @gst_rate, 'Y', @new_bill_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
  	raiserror ('Error: Failed to create transaction', 16, 1)
	return -1
end

/*
 * Process Agency Commission if Necessary
 */

if(@agency_comm > 0) or (@acomm_tran_id is not null)
begin

	if @agency_comm = 0
		if @campaign_no < 900000
			select @agency_comm = .1
		else
			select @agency_comm = .2


	select @acomm_amount = round((@credit_amount * -1) * @agency_comm, 2)

	/*
	 * Create Agency Commission Adjustment
	 */
	
	select @tran_desc = 'A/Comm Adjustment - Reference: ' + convert(varchar(10),@acomm_tran_id)
	
	execute @errorode = p_ffin_create_transaction @new_acomm_code, @campaign_no, @account_id, @tran_date, @tran_desc, null, @acomm_amount, @gst_rate, 'Y', @tran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
  	    raiserror ('Error: Failed to create transaction', 16, 1)
    	return -1
	end

	/*
	 * Reverse Agency Commission Originally Allocated to the Billing Transaction
	 */
	
	select @money_pass = @acomm_amount 
	
	execute @errorode = p_ffin_allocate_transaction @acomm_tran_id, @billing_tran_id, @money_pass, @tran_date
	if (@errorode !=0)
	begin
		rollback transaction
  	    raiserror ('Error: Failed to allocate transaction', 16, 1)
    	return -1
	end

	/*
    * Allocate Agency Commission Reversed Above to the 
    * New Agency Adjustment Adjustment
    */

	select @money_pass = @acomm_amount * -1
	execute @errorode = p_ffin_allocate_transaction @acomm_tran_id, @tran_id, @money_pass, @tran_date
	if (@errorode !=0)
	begin
		rollback transaction
	        raiserror ('Error: Failed to allocate transaction', 16, 1)
		return -1
	end

end

/*
 * Allocate Billing Credit Against Original Billing Transaction 
 */

execute @errorode = p_ffin_allocate_transaction @new_bill_id, @billing_tran_id, @credit_amount,@tran_date
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error: Failed to allocate transaction', 16, 1)
	return -1
end

/*
 * Refresh Campaign Balances
 */

execute @errorode = p_ffin_campaign_balances @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error: Failed to resync campaign balances transaction', 16, 1)
	return -1
end

/*
 * Allocate liability so revenue can be calculated
 */

execute @errorode = p_ffin_allocate_baddebtcredit	@new_bill_id	
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error: Failed to set up liability records', 16, 1)
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
