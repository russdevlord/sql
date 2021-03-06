/****** Object:  StoredProcedure [dbo].[p_ffin_transaction_reversal]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_transaction_reversal]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_transaction_reversal]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROC [dbo].[p_ffin_transaction_reversal]	@tran_id		 int,
																							@tran_date		 datetime,
																							@check_amount	 money
as

declare @error					int,
		@sqlstatus				int,
		@new_tran_id			int,
		@new_alloc_id			int,
		@errorode					int,
		@allocation_id			int,
		@from_tran				int,
		@to_tran				int,
		@rowcount				int,
		@non_trading_id			int,
		@credit_count			int,
		@reversal				char(1),
		@is_charge				char(1),
		@nett_amount			money,
		@gst_amount				money,
		@reverse_gst			money,
		@gst_rate				numeric(6,4),
		@gross_amount			money,
		@reversal_amount		money,
		@alloc_amount			money,
		@tran_type				smallint,
		@tran_type_code			char(5),
		@tran_desc				varchar(255),
		@new_tran_desc			varchar(255),
		@tran_cat				char(1),
		@can_reverse			char(1),
		@campaign_no			int,
		@payment_credit			money,
		@is_closed				char(1),
		@show_on_statement		char(1),
		@account_id				int,
		@alloc_date				datetime
		
		
select @alloc_date = getdate()		

/*
 * Check Current Reversal Status on Campaign Transaction
 */
 
select @reversal = ct.reversal,
       @nett_amount = ct.nett_amount,
       @gst_amount = ct.gst_amount,
       @gst_rate   = ct.gst_rate,
       @gross_amount = ct.gross_amount,
       @tran_type = ct.tran_type,
       @tran_type_code = tt.trantype_code,
       @can_reverse = tt.can_reverse,
       @tran_cat = ct.tran_category,
       @tran_desc = ct.tran_desc,
       @campaign_no = ct.campaign_no,
       @is_closed = fc.campaign_status,
	   @show_on_statement = ct.show_on_Statement,
	   @account_id = ct.account_id
  from campaign_transaction ct,
       transaction_type tt,
       film_campaign fc
 where ct.tran_id = @tran_id and
       ct.campaign_no = fc.campaign_no and
       ct.tran_type = tt.trantype_id

if (@is_closed = 'X')
begin
	raiserror ('p_ffin_transaction_reversal:Transaction Reversal - Campaign is Closed.', 16, 1)
	return -1
end

if (@reversal = 'Y')
begin
	raiserror (50030,11, 1)
	return -1
end

if (@can_reverse = 'N')
begin
	raiserror (50051, 11, 1)
	return -1
end

if (abs(@check_amount) <> abs(@gross_amount))
begin
	raiserror (50053, 11, 1)
	return -1
end

/*
 * Payment Reversal Check
 */

if(@tran_cat = 'C')
begin

	if(@gross_amount > 0)
	begin
		raiserror (50058, 11, 1)
		return -1
	end

	select @payment_credit = isnull(sum(ta.gross_amount),0)
	  from transaction_allocation ta,
		   campaign_transaction ct
	 where ta.from_tran_id = @tran_id and
		   ta.to_tran_id = ct.tran_id and
		   ct.tran_category = 'C'

	if(@payment_credit < 0)
	begin
		raiserror (50054, 11, 1)
		return -1
	end

end

/*
 * Miscellaneous Charge Check
 */

if(@tran_cat = 'M')
begin

	if exists ( select ta.allocation_id
				  from transaction_allocation ta,
				       campaign_transaction ct
				 where ta.to_tran_id = @tran_id and
				       ta.from_tran_id = ct.tran_id and
                       ct.tran_category = 'D' )
	begin
		raiserror (50060, 11, 1)
		return -1
	end

end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Flag Campaign Transaction as Reversed
 */

update campaign_transaction
   set reversal = 'Y'
 where tran_id = @tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to set transaction as reversed.', 16, 1)
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

execute @errorode = p_ffin_create_transaction 	@tran_type_code,
											@campaign_no,
											@account_id,											
											@tran_date,
											@new_tran_desc,
											null,
											@reversal_amount,
											@gst_rate,
											@show_on_statement,
											@new_tran_id OUTPUT
                                          
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to create reversal  transaction.', 16, 1)
	return -1
end
	
/*
 * Set Reversal Flag on New Transaction
 */

update campaign_transaction
   set reversal = 'Y',
		account_id = @account_id
 where tran_id = @new_tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to set transaction as reversed.', 16, 1)
    return -1
end

/*
 * Reverse any Allocations
 */

execute @errorode = p_ffin_transaction_unallocate @tran_id, 'Y', 0
                                          
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
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

execute @errorode = p_ffin_allocate_transaction @from_tran, @to_tran, @alloc_amount, @alloc_date
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
    return -1
end

/*
 * Call Payment Allocations
 */

execute @errorode = p_ffin_payment_allocation @campaign_no
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
    return -1
end

/*
 * Call Balance Update
 */

execute @errorode = p_ffin_campaign_balances @campaign_no
if (@errorode !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to resync campaign balances.', 16, 1)
    return -1
end

/* 
 * Update Inclusion Items
 */ 

update 	inclusion
set		tran_id = null
where 	tran_id = @tran_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
    raiserror ('p_ffin_transaction_reversal: Failed to resync campaign balances.', 16, 1)
    return -1
end

if  @tran_type = 164
begin
	update 	inclusion_spot
	set			rate = 0, charge_rate = 0
	where 		tran_id = @tran_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('p_ffin_transaction_reversal: Failed to inclusion_spot campaign balances.', 16, 1)
		return -1
	end
end 


/*
 * Commit and Return
 */
 
commit transaction
return 0
GO
