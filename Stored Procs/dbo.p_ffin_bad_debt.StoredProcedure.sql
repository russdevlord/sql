/****** Object:  StoredProcedure [dbo].[p_ffin_bad_debt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_bad_debt]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_bad_debt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_ffin_bad_debt]		@campaign_no		int,
										@sum_nett_amount    money OUTPUT

as

/*
 * Declare Variables
 */

declare @error              	int,
        @getunalloc_csr_flg 	int,
        @country_csr_flg 		int,
        @non_billing_cnt    	int,
        @non_alloc_cnt      	int,
        @baddebt_tran_id    	int,
        @tran_id            	int,
        @gross_amount       	money,
        @gst_rate           	numeric(6,4),
        @nett_amount        	money,
        @gst_amount         	money,
        @sum_gst_amount     	money,
        @tran_alloc_id       	int,
        @new_alloc_id       	int,
        @errorode              	int,
        @alloc_amount			money,
        @currency_code			char(3),
        @new_figure_id			int,
        @event_id				int,
		@account_id				int

/* 
 *  Create temporary tables
 */

create table #unalloc
(
	tran_id	  			int,
	tran_type   		int,
	unalloc_sum 		money,
	gst_rate    		numeric(6,4),
	alloc_amount 	    money,
	currency_code		char(3),
	account_id			int
)



/* 
 * Begin Transaction
 */

begin transaction

/*
 * Initialise cursor flags
 */

select @getunalloc_csr_flg = 0
select @country_csr_flg = 0

/*
 * Populate Allocation based on To Tran Id
 */

insert into #unalloc (
				tran_id,
				tran_type,
				unalloc_sum,
				gst_rate, 
				alloc_amount,
				currency_code,
				account_id)
select			ct.tran_id,
				ct.tran_type,   
				sum(ta.gross_amount),
				max(ct.gst_rate),
				sum(ta.gross_amount),
				ct.currency_code,
				ct.account_id
from			campaign_transaction ct
inner join		transaction_allocation ta on ct.tran_id = ta.to_tran_id
where			ct.campaign_no = @campaign_no 
group by		ct.tran_id,   
				ct.tran_type,
				ct.currency_code,
				ct.account_id
having			sum(ta.gross_amount) > 0

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	goto error
end

/*
 * Populate Allocation based on From Tran Id
 */

insert into #unalloc (
				tran_id,
				tran_type,
				unalloc_sum,
				gst_rate,
				alloc_amount,
				currency_code,
				account_id)
select			ct.tran_id,   
				ct.tran_type,   
				sum(ta.gross_amount),
				max(ct.gst_rate),
				sum(ta.gross_amount),
				ct.currency_code,
				ct.account_id
from			campaign_transaction ct
inner join		transaction_allocation ta on ct.tran_id = ta.from_tran_id
where			ct.campaign_no = @campaign_no 
group by		ct.tran_id,   
				ct.tran_type,
				ct.currency_code,
				ct.account_id
having			sum(ta.gross_amount) > 0

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	goto error
end

/*
 * Check for non billing transactions
 */

select			@non_billing_cnt = count(tran_id)
from 			#unalloc
inner join		transaction_type on #unalloc.tran_type = transaction_type.trantype_id
where 			tran_category_code != 'B' 
and				tran_category_code != 'M' 
and				tran_category_code != 'D'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	goto error
end

if (@non_billing_cnt != 0)
begin
	
	rollback transaction
   
	/*
	 * 50032 Msg: Campaign cannot have a Bad Debt applied due to outstanding 
    *            unallocated payments or agency commission.
    */

	raiserror (50032, 11, 1)
	goto error

end

/*
 * Check for unallocated billings
 */

select			@non_alloc_cnt = count(tran_id)
from			#unalloc

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	goto error
end

if (@non_alloc_cnt = 0)
begin

	rollback transaction

   /*
	 * 50033 Msg: Campaign cannot have a Bad Debt applied due to 
    *            no outstanding debts currently present.
    */

   raiserror (50033, 11, 1)
	goto error

end

select @country_csr_flg = 1

declare			country_csr cursor static for
select			sum(unalloc_sum),
				max(gst_rate),
				currency_code,
				account_id
from			#unalloc
where			unalloc_sum > 0
group by		currency_code,
				account_id
for				read only

open country_csr
fetch country_csr into @gross_amount, @gst_rate, @currency_code, @account_id
while(@@fetch_status = 0)
begin

	/*
	 * Get Campaign Transaction Id
	 */
	
	execute @errorode = p_get_sequence_number 'campaign_transaction',5,@baddebt_tran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end
	
	/*
	 * Create Bad Debt Campaign Transaction
	 */
	
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
			 account_id) values ( 
			 @baddebt_tran_id,
			 10,
			 'D',
			 null,
			 @campaign_no,
			 -1,
			 @currency_code,
			 getdate(),
			 'Campaign Bad Debt',
			 -1,
			 0,
			 0,
			 @gst_rate,
			 @gross_amount * -1,
			 null,
			 null,
			 null,
			 'Y',
			 'N',
			 getdate(),
			 @account_id)
	
	select @error = @@error
	if (@error != 0)
	begin
		rollback transaction
		goto error
	end
	
	/*
	 *  Allocate all outstanding debt to bad debt transaction
	 */
	
	select @sum_nett_amount = 0
	select @sum_gst_amount = 0
	select @getunalloc_csr_flg = 1


	declare			getunalloc_csr cursor static for
	select			tran_id,
					unalloc_sum,
					gst_rate,
					alloc_amount
	from			#unalloc
	where			unalloc_sum > 0 
	and				currency_code = @currency_code
	and				account_id = @account_id
	for read only

	
	open getunalloc_csr
	fetch getunalloc_csr into @tran_id, @gross_amount, @gst_rate, @alloc_amount
	while (@@fetch_status = 0)
	begin
	
		/*
		 * Get Allocation Id
		 */
	
		execute @errorode = p_get_sequence_number 'transaction_allocation',5,@new_alloc_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
		 *  Calculate gst amounts
		 */
	
		if (@gst_rate is null or @gst_rate = 0)
		begin
			select @gst_rate = 0
			select @gst_amount = 0
			select @nett_amount = @gross_amount
		end
		else
		begin
			select @nett_amount = round(@gross_amount / (1 + @gst_rate),2)
			select @gst_amount = @gross_amount - @nett_amount
		end
	
		select @sum_nett_amount = @sum_nett_amount + @nett_amount
		select @sum_gst_amount = @sum_gst_amount + @gst_amount
	
		/*
		 *  Insert new row into the Transaction Allocation table
		 */
	
		insert into transaction_allocation (
				 allocation_id,   
				 from_tran_id,   
				 to_tran_id,   
				 nett_amount,   
				 gst_amount,   
				 gst_rate,   
				 gross_amount,   
				 pay_gst,   
				 alloc_amount,   
				 process_period,   
				 entry_date ) values (
				 @new_alloc_id,
				 @baddebt_tran_id,
				 @tran_id,
				 @nett_amount * -1,   
				 @gst_amount * -1,   
				 @gst_rate,   
				 @gross_amount * -1,   
				 @gst_amount * -1,   
				 @nett_amount * -1,   
				 null,
				 getdate() )
	
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end
	
		fetch getunalloc_csr into @tran_id, @gross_amount, @gst_rate, @alloc_amount
	
	end
	close getunalloc_csr
	deallocate getunalloc_csr



	/*
	 * Create Allocation
	 */

	execute @errorode = p_get_sequence_number 'transaction_allocation',5,@tran_alloc_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	insert into transaction_allocation (
				allocation_id,   
				from_tran_id,   
				to_tran_id,   
				nett_amount,   
				gst_amount,   
				gst_rate,   
				gross_amount,   
				pay_gst,   
				alloc_amount,   
				process_period,   
				entry_date ) values (
				@tran_alloc_id,
				@baddebt_tran_id,
				null,
				@nett_amount,   
				@gst_amount,   
				@gst_rate,   
				@gross_amount,   
				0,   
				0,   
				null,
				getdate() )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		return -1
	end

	select @getunalloc_csr_flg = 0
	select @country_csr_flg = 0

	/*
	 *  Set the Bad Debt Campaign Transaction Nett & GST Amounts
	 */

	update			campaign_transaction
	set				nett_amount = @sum_nett_amount * -1,
					gst_amount = @sum_gst_amount * -1
	where			tran_id = @baddebt_tran_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end

	/*
	 *  Set the Transaction Allocation Nett & GST Amounts
	 */

	update			transaction_allocation
	set				nett_amount = @sum_nett_amount ,
					gst_amount = @sum_gst_amount,
					gross_amount = @sum_gst_amount + @sum_nett_amount
	 where			allocation_id = @tran_alloc_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end

	/*
     * Fetch Next
     */

	fetch country_csr into @gross_amount, @gst_rate, @currency_code, @account_id

end
close country_csr

deallocate country_csr


/*
 * Refresh Campaign Balances
 */

execute @errorode = p_ffin_campaign_balances @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Add Bad Debt Campaign Event
 */

execute @errorode = p_get_sequence_number 'film_campaign_event', 5, @event_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

insert into film_campaign_event (
       campaign_event_id,
       campaign_no,
       event_type,
       event_date,
       event_outstanding,
       event_desc,
       entry_date ) values (
       @event_id,
       @campaign_no,
       'B',
       getdate(),
       'N',
       'Campaign Bad Debt',
       getdate() )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit and return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@getunalloc_csr_flg = 1)
   begin
		close getunalloc_csr
		deallocate getunalloc_csr
	end

	if (@country_csr_flg = 1)
   begin
		close country_csr
		deallocate country_csr
	end

	return -1
GO
