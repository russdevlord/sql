/****** Object:  StoredProcedure [dbo].[p_ffin_payment_allocation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_payment_allocation]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_payment_allocation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_ffin_payment_allocation] @campaign_no		integer
as

/*
 * Declare Variables
 */

declare @error              	integer,
        @errorode              	integer,
        @tran_amount			money,
        @pay_date				datetime,
        @pay_tran				integer,
        @pay_amount				money,
        @pay_remaining			money,
        @alloc_priority			smallint,
        @alloc_age				smallint,
        @alloc_date				datetime,
        @alloc_tran				integer,
        @alloc_amount			money,
        @pay_csr_flg 			tinyint,
        @alloc_csr_flg 			tinyint,
        @exit_loop				tinyint,
		@tran_id				integer,
		@account_id				integer

/*
 * Initialise Cursor Flags
 */

select 	@pay_csr_flg = 0,
		@alloc_csr_flg = 0


select	@alloc_date = min(end_date)
from	accounting_period
where	status <> 'X'   

/* 
 * Begin Transaction
 */

begin transaction

declare 	allocation_csr	cursor forward_only static for
select		ct.tran_id,
			ct.gross_amount,
			isnull(sum(ta.gross_amount),0),
			ct.account_id
from		campaign_transaction ct,
	        transaction_allocation ta  
where 		ct.campaign_no = @campaign_no and
         	ct.tran_id = ta.to_tran_id
group by 	ct.tran_id,
			ct.gross_amount,
			ct.account_id,
			ct.tran_date
having		isnull(sum(ta.gross_amount),0) > 0
order by	ct.tran_date,
			ct.gross_amount,
			ct.tran_id
for 		read only

open allocation_csr
select @pay_csr_flg = 1
fetch allocation_csr into @tran_id, @tran_amount, @alloc_amount, @account_id
while(@@fetch_status = 0)
begin



	select @pay_remaining = @alloc_amount


	/*
	 * Loop through Payments
	 */
	
	select @exit_loop = 0
	
	/*
	 * Declare Payment Cursor
	 */ 
	 
	declare 	pay_csr cursor static for
	select 		ct.tran_date,
				ct.tran_id,
				sum(ta.gross_amount)
	from 		campaign_transaction ct,   
				transaction_allocation ta  
	where 		ct.campaign_no = @campaign_no 
	and			ct.tran_category = 'C' 
	and			ct.tran_id = ta.from_tran_id 
	and			ct.account_id = @account_id
	group by 	ct.tran_date,
				ct.tran_id
	having 		sum(ta.gross_amount) > 0
	order by 	ct.tran_date ASC,
				ct.tran_id ASC
	for 		read only
	
	
	
	open pay_csr
	select @pay_csr_flg = 1
	fetch pay_csr into @pay_date, @pay_tran, @pay_amount
	while (@@fetch_status = 0 and @exit_loop = 0)
	begin
	
		/*
	    * Calculate Tran Amount
	    */
	
		if(@pay_amount > @pay_remaining)
			select @tran_amount = @pay_remaining
		else
			select @tran_amount = @pay_amount
	
		if(@tran_amount = 0)
			select @exit_loop = 1
		else
		begin
	
			/*
			 * Call Allocation Function
			 */
	
			select @tran_amount = 0 - @tran_amount
			execute @errorode = p_ffin_allocate_transaction @pay_tran, @tran_id, @tran_amount, @alloc_date
			if (@errorode !=0)
				goto error
		
			/*
			 * Update Pay Amount Remaining
			 */
	
			select @pay_remaining = @pay_remaining + @tran_amount
	
		end
	
		if(@pay_remaining = 0)
			select @exit_loop = 1
	
		/*
	    * Fetch Next
	    */
	
		fetch pay_csr into @pay_date, @pay_tran, @pay_amount
	
	end
	close pay_csr
	select @pay_csr_flg = 0
	deallocate pay_csr

	fetch allocation_csr into @tran_id, @tran_amount, @alloc_amount, @account_id
end

close allocation_csr
deallocate allocation_csr
select @alloc_csr_flg = 0


/*
 * Commit and return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@pay_csr_flg = 1)
	begin
		close pay_csr
		deallocate pay_csr
	end
	
	if (@alloc_csr_flg = 1)
	begin
		close allocation_csr
		deallocate allocation_csr
	end

	rollback transaction
	return -1
GO
