/****** Object:  StoredProcedure [dbo].[p_ffin_create_auth_credit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_create_auth_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_create_auth_credit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_create_auth_credit]  @billing_tran_id	    int,
                                  	   @acomm_tran_id		int,
                                  	   @credit_amount		money,
                                  	   @agency_comm		    numeric(6,4)
as

/*
 * Declare Variables
 */

declare @error				int,
 		@sqlstatus			int,
        @new_bill_id		int,
        @new_acomm_id		int,
        @acomm_amount		money,
        @errorode				int,
        @tran_type			smallint,
        @tran_desc			varchar(50),
        @rowcount			int,
        @nett_amount		money,
        @gst_amount			money,
        @gst_rate			numeric(6,4),
        @money_pass			money,
		@campaign_no		int,
		@tran_id			int,
		@tran_date			datetime,
		@account_id			int

/*
 * Transform Credit Amount
 */

if(@credit_amount > 0)
	select @credit_amount = (@credit_amount * -1)

/*
 * Get Transaction Information
 */
 
select 	@tran_date = getdate()

select 	@gst_rate = ct.gst_rate,
		@nett_amount = ct.nett_amount,
		@campaign_no = ct.campaign_no, 
		@tran_type = ct.tran_type,
		@account_id = ct.account_id
  from 	campaign_transaction ct
 where 	ct.tran_id = @billing_tran_id

if(@tran_type <> 1 or @nett_amount < 0)
begin
	raiserror ('Transaction is not a Billing and/or is a Reversal', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Credit Transaction
 */

select @tran_desc = 'Billing Credit - Reference: ' + convert(varchar(10),@billing_tran_id)

execute @errorode = p_ffin_create_transaction 'FBILL', @campaign_no, @account_id,  @tran_date, @tran_desc, null, @credit_amount, @gst_rate, 'Y', @new_bill_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('Error: Failed to create transaction', 16, 1)
	return -1
end

/*
 * Process Agency Commission if Necassary
 */

if(@agency_comm > 0)
begin

	select @acomm_amount = round((@credit_amount * -1) * @agency_comm, 2)

	/*
	 * Create Agency Commission Adjustment
	 */
	
	select @tran_desc = 'A/Comm Adjustment - Reference: ' + convert(varchar(10),@acomm_tran_id)
	
	execute @errorode = p_ffin_create_transaction 'FACOMM', @campaign_no, @account_id, @tran_date, @tran_desc, null, @acomm_amount, @gst_rate, 'Y',@tran_id OUTPUT
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

execute @errorode = p_ffin_allocate_transaction @new_bill_id, @billing_tran_id, @credit_amount, @tran_date
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
	raiserror ('Error: Failed to resync campaign balances', 16, 1)
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
