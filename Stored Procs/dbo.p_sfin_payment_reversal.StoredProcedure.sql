/****** Object:  StoredProcedure [dbo].[p_sfin_payment_reversal]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_payment_reversal]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_payment_reversal]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_payment_reversal] @tran_id					integer,
                                    @tran_date				datetime,
												@cost_centre_code		char(2),
                                    @gl_code					char(4),
												@tran_comment			varchar(255),
    											@dest_tran_type		char(5),
 												@dest_campaign_no		char(7),
                                    @check_amount			money,
                                    @mode 					integer,
                                    @batch_item_no			integer

as
set nocount on 
/*
 * Declare Variables
 */

declare @error							integer,
	     @sqlstatus					integer,
        @new_tran_id					integer,
        @new_alloc_id				integer,
        @errorode							integer,
	     @allocation_id				integer,
	     @from_tran					integer,
	     @to_tran						integer,
        @rowcount						integer,
		  @non_trading_id				integer,
        @reversal						char(1),
        @is_charge					char(1),
        @nett_amount					money,
        @gst_amount					money,
        @reverse_gst					money,
        @gst_rate						numeric(6,4),
        @gross_amount				money,
        @reversal_amount			money,
        @alloc_amount				money,
        @tran_type					smallint,
        @tran_type_code				char(5),
        @tran_desc					varchar(255),
        @new_tran_desc				varchar(255),
        @tran_cat						char(1),
        @can_reverse					char(1),
        @campaign_no					char(7),
        @payment_credit				money,
        @is_closed					char(1),
        @transfer_tran_id			integer,
        @currency_code				char(3)

/*
 * Check Current Reversal Status on Campaign Transaction
 */
 
select @reversal = st.reversal,
       @nett_amount = st.nett_amount,
       @gst_amount = st.gst_amount,
       @gst_rate   = st.gst_rate,
       @gross_amount = st.gross_amount,
       @tran_type = st.tran_type,
       @tran_type_code = tt.trantype_code,
       @can_reverse = tt.can_reverse,
       @tran_cat = st.tran_category,
       @tran_desc = st.tran_desc,
       @campaign_no = st.campaign_no,
       @is_closed = sc.is_closed,
		 @currency_code = currency_code
  from slide_transaction st,
       transaction_type tt,
       slide_campaign sc
 where st.tran_id = @tran_id and
       st.campaign_no = sc.campaign_no and
       st.tran_type = tt.trantype_id

if (@is_closed = 'Y')
begin
	raiserror ('Transaction Reversal - Campaign is Closed.', 16, 1)
	return -1
end

if (@reversal = 'Y')
begin
	raiserror ('p_sfin_payment_reversal: It is Reversal!', 16, 1)
	return -1
end

if (@can_reverse = 'N')
begin
	raiserror ('p_sfin_payment_reversal: Can Reverce = N', 16, 1)
	return -1
end

if (abs(@check_amount) <> abs(@gross_amount))
begin
	raiserror ('p_sfin_payment_reversal: Check Sum <> Gross Sum', 16, 1)
	return -1
end

/*
 * Payment Reversal Check
 */

if(@tran_cat <> 'C')
begin
	raiserror ('This transaction type cannot be reversed in this way.', 16, 1)
	return -1
end

if(@gross_amount > 0)
begin
	raiserror ('p_sfin_payment_reversal: Gross Amount > 0', 16, 1)
	return -1
end

select @payment_credit = isnull(sum(sa.gross_amount),0)
  from slide_allocation sa,
		 slide_transaction st
 where sa.from_tran_id = @tran_id and
		 sa.to_tran_id = st.tran_id and
		 st.tran_category = 'C'

if(@payment_credit < 0)
begin
	raiserror ('p_sfin_payment_reversal: Credit Payment < 0 !', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Flag Campaign Transaction as Reversed
 */

update slide_transaction
	set reversal = 'Y'
 where tran_id = @tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end

/*
 * Create Reversal Campaign Transaction
 */

if(@tran_cat = 'C')
begin
	select @reversal_amount = @gross_amount * -1 
	select @new_tran_desc = 'Payment/Deposit Reversal (' + convert(varchar(10), @tran_id) + ')'
end
else
begin
	select @reversal_amount = @nett_amount * -1 
	select @new_tran_desc = 'Reversal ( ' + @tran_desc + ' )'
end

execute @errorode = p_sfin_create_transaction @tran_type_code,
                                           @campaign_no,
                                           NULL,
                                           @tran_date,
                                           @new_tran_desc,
                                           @reversal_amount,
                                           NULL,
														 @batch_item_no,
													    NULL, 
                                           @new_tran_id OUTPUT
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Non Trading Transfer
 */

if @mode = 1 --Tranfer to non-trading
begin
	
	/*
 	 *	Create a reversed non trading transaction.
	 */
	
	execute @errorode = p_get_sequence_number 'non_trading',5,@non_trading_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

	insert into non_trading (
          non_trading_id,
          campaign_no,
          cost_centre_code,
          gl_code,
          tran_id,
          tran_date,
          amount,
          batch_item_no,
          currency_code,
          comment,
          payment_source_id,
          entry_date,
			 held_active ) values (
	       @non_trading_id,
			 @campaign_no,
			 @cost_centre_code,
			 @gl_code,
			 @new_tran_id,
			 @tran_date,
			 @reversal_amount,
          @batch_item_no,
			 @currency_code,
			 @tran_comment,
          6, --Debtors
			 getdate(),
			 'Y' )

	if(@@error !=0)
	begin
		rollback transaction
		return -1
	end	

end

/*
 * Transfer to Another Campaign
 */

else if @mode = 2 --Tranfer to another campaign
begin

	/*
	 * Create transaction on other campaign
	 */

	if @dest_tran_type = 'DEPOS'
 		select @new_tran_desc = 'Deposit on signing of contract - Thankyou.'

	if @dest_tran_type = 'SPAY'
		select @new_tran_desc = 'Payment Received - Thankyou.'

	select @reversal_amount = @reversal_amount * -1

	execute @errorode = p_sfin_create_transaction @dest_tran_type,
															 @dest_campaign_no,
															 NULL,
															 @tran_date,
															 @new_tran_desc,
															 @reversal_amount,
															 NULL,
                                              @batch_item_no,
                                              6, --Debtors
															 @transfer_tran_id OUTPUT
															
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

	/*
	 * Call Payment Allocations
	 */
	
	execute @errorode = p_sfin_payment_allocation @dest_campaign_no
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end
	
	/*
	 * Call Balance Update
	 */
	
	execute @errorode = p_sfin_slide_campaign_balance @dest_campaign_no
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

end
	
/*
 * Set Reversal Flag on New Transaction
 */

update slide_transaction
	set reversal = 'Y'
 where tran_id = @new_tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end

/*
 * Reverse any Allocations
 */

execute @errorode = p_sfin_transaction_unallocate @tran_id, 'Y', 0
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Allocate Reversal to the Transaction
 */ 

if(@gross_amount > 0)
begin
	select @from_tran = @new_tran_id
	select @to_tran = @tran_id
	if(@nett_amount = 0)
   	select @alloc_amount = @gross_amount * -1
	else
   	select @alloc_amount = @nett_amount * -1

end
else
begin
	select @from_tran = @tran_id
	select @to_tran = @new_tran_id
	if(@nett_amount = 0)
   	select @alloc_amount = @gross_amount
	else
   	select @alloc_amount = @nett_amount
end

execute @errorode = p_sfin_allocate_transaction @from_tran, @to_tran, @alloc_amount
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Call Payment Allocations
 */

execute @errorode = p_sfin_payment_allocation @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Call Balance Update
 */

execute @errorode = p_sfin_slide_campaign_balance @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
