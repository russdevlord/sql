/****** Object:  StoredProcedure [dbo].[p_sfin_payment_adjustment]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_payment_adjustment]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_payment_adjustment]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_payment_adjustment] @tran_id				integer,
                                      @tran_date			datetime,
                                      @tran_adjust			money,
												  @payment_source		integer
as

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
        @payment_credit				money

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
       @campaign_no = st.campaign_no
  from slide_transaction st,
       transaction_type tt
 where st.tran_id = @tran_id and
       st.tran_type = tt.trantype_id


if (@tran_cat <> 'C' or @gross_amount > 0)
begin
	raiserror ('p_sfin_payment_adjustment : Transaction Category <> C or Gross Amount > 0', 16, 1)
	return -1
end

if (@reversal = 'Y')
begin
	raiserror ('p_sfin_payment_adjustment : reversal = Y', 16, 1)
	return -1
end

/*
 * Check Amount of Adjustments already applied to Payment.
 */

select @payment_credit = isnull(sum(sa.gross_amount),0)
  from slide_allocation sa,
		 slide_transaction st
 where sa.from_tran_id = @tran_id and
		 sa.to_tran_id = st.tran_id and
		 st.tran_category = 'C'

if((@payment_credit + @tran_adjust) > abs(@gross_amount))
begin
	raiserror ('p_sfin_payment_adjustment: Payment Credit + Tran Adjustment more then Gross Amount', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Payment Adjustment Transaction
 */

select @new_tran_desc = 'Payment Adjustment (' + convert(varchar(10), @tran_id) + ')'

execute @errorode = p_sfin_create_transaction @tran_type_code,
                                           @campaign_no,
                                           NULL,
                                           @tran_date,
                                           @new_tran_desc,
                                           @tran_adjust,
                                           NULL,
                                           null,
														 @payment_source,
                                           @new_tran_id OUTPUT
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 *	Check if transaction also has a corresponding non trading transaction to adjust.
 */

select @non_trading_id = non_trading_id
  from non_trading
 where tran_id = @tran_id

if @non_trading_id is not null
begin
	
	/*
 	 *	Create a reversed non trading transaction.
	 */
	
	execute @errorode = p_get_sequence_number 'non_trading', 5, @non_trading_id OUTPUT
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
				 currency_code,
				 payment_source_id,
				 comment,
				 entry_date,
				 held_active ) 
		select @non_trading_id,
				 campaign_no,
				 cost_centre_code,
				 gl_code,
				 @new_tran_id,
				 @tran_date,
				 @tran_adjust * -1,
				 currency_code,
				 6, --Debtors
				 'Payment Adjustment',
				 getdate(),
				 'N' -- Held active FALSE
		  from non_trading
		 where non_trading.tran_id = @tran_id

	if(@@error !=0)
	begin
		rollback transaction
		return -1
	end	

end
	
/*
 * Reverse any Allocations
 */

execute @errorode = p_sfin_transaction_unallocate @tran_id, 'N', @tran_adjust
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Allocate Payment to Adjustment
 */ 

select @from_tran = @tran_id
select @to_tran = @new_tran_id
select @alloc_amount = @tran_adjust * -1

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
