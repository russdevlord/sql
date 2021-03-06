/****** Object:  StoredProcedure [dbo].[p_sfin_non_trading]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_non_trading]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_non_trading]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_non_trading] @campaign_no			char(7),
                               @cost_centre			char(2),
                               @cost_account			char(4),
                               @amount					money,
                               @tran_date				datetime,
										 @comment				varchar(50),
										 @create_trans			char(1),
										 @tran_type				char(5),
                               @batch_item_no		integer,
                               @nt_group_no			integer,
										 @payment_source_id	integer
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @non_trading_id				int,
		  @tran_id						int,
		  @tran_desc					varchar(50),
        @currency_code				char(3),
        @current_allocation		money,
        @is_closed					char(1)

/*
 * Check the Transaction will not send Amounts Negative
 */

select @current_allocation = isnull(sum(amount),0)
  from non_trading
 where campaign_no = @campaign_no and
       cost_centre_code = @cost_centre and
       gl_code = @cost_account

if(@@error !=0)
begin
	raiserror ('Non Trading Transfer - Error Checking Previous Non Trading Allocations.', 16, 1)
	return -1
end	

if((@current_allocation + @amount) < 0)
begin
	raiserror ('Non Trading Transfer - This transaction will overdraw the non-trading account for this campaign.', 16, 1)
	return -1
end	

if((@amount > 0) and (@create_trans = 'Y'))
begin
	raiserror ('Non Trading Transfer - It is invalid to move money out of a campaign using this function.', 16, 1)
	return -1
end	

/*
 * Setup Currency Code
 */

select @currency_code = c.currency_code
  from slide_campaign sc,
       branch b,
       country c
 where sc.campaign_no = @campaign_no and
       sc.branch_code = b.branch_code and
       b.country_code = c.country_code

if(@@error !=0) or (@@rowcount = 0)
begin
	raiserror ( 'Non Trading Transfer - Error Getting Currency Code %1!.' , 11, 1, @campaign_no)
	return -1
end	

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Non Trading Transaction
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
       tran_date,
       amount,
		 currency_code,
		 payment_source_id,
       batch_item_no,
		 comment,
       nt_group_no,
       entry_date,
		 held_active ) values (
       @non_trading_id,
       @campaign_no,
       @cost_centre,
       @cost_account,
       @tran_date,
       @amount,
		 @currency_code,
		 @payment_source_id,
       @batch_item_no,
		 @comment,
		 @nt_group_no,
       getdate(),
		 'Y')

if(@@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Create Slide Transaction
 */

if @create_trans = 'Y'
begin

	/*
    * Check Campaign Closed
    */

	select @is_closed = is_closed
	  from slide_campaign
	 where campaign_no = @campaign_no
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Non Trading Transfer - Error Retrieving Campaign Information.', 16, 1)
		return -1
	end
	
	if(@is_closed = 'Y')
	begin
		rollback transaction
		raiserror ('Non Trading Transfer - Campaign is Closed.', 16, 1)
		return -1
	end

	/*
    * Create Transaction
    */

	if @tran_type = 'SPAY'
		select @tran_desc = 'Payment Received - Thankyou'
	else if @tran_type = 'DEPOS'
		select @tran_desc = 'Deposit on signing of contract - Thankyou'

	exec @errorode = p_sfin_create_transaction @tran_type,
                                           @campaign_no,
														 null,
														 @tran_date,
														 @tran_desc,
														 @amount ,
														 null,
														 @batch_item_no,
														 @payment_source_id,
														 @tran_id OUTPUT

	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

	update non_trading
		set tran_id = @tran_id
	 where non_trading_id = @non_trading_id

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

end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
