/****** Object:  StoredProcedure [dbo].[p_sfin_payment_allocation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_payment_allocation]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_payment_allocation]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_payment_allocation] @campaign_no		char(7)
as

/*
 * Declare Variables
 */

declare @error              	integer,
        @errorode              	integer,
        @tran_amount				money,
        @pay_date					datetime,
        @pay_tran					integer,
        @pay_amount				money,
        @pay_remaining			money,
        @alloc_priority			smallint,
        @alloc_age				smallint,
        @alloc_date				datetime,
        @alloc_tran				integer,
        @alloc_amount			money,
        @pay_csr_flg 			tinyint,
        @alloc_csr_flg 			tinyint,
        @exit_loop				tinyint




/* 
 * Begin Transaction
 */

begin transaction

/*
 * Initialise Cursor Flags
 */

select @pay_csr_flg = 0
select @alloc_csr_flg = 0

/*
 * Declare Payment Cursor
 */ 
 
 declare pay_csr cursor static for
  select st.tran_date,
         st.tran_id,
         sum( sa.gross_amount )
    from slide_transaction st,   
         slide_allocation sa  
   where st.campaign_no = @campaign_no and
         st.tran_category = 'C' and
         st.tran_id = sa.from_tran_id
group by st.tran_date,
         st.tran_id
  having sum( sa.gross_amount ) > 0
order by st.tran_date ASC,
         st.tran_id ASC
     for read only

/*
 * Loop through Payments
 */

open pay_csr
select @pay_csr_flg = 1
fetch pay_csr into @pay_date, @pay_tran, @pay_amount
while (@@fetch_status = 0)
begin

	/*
    * Initialise
    */

	select @pay_remaining = @pay_amount
	select @exit_loop = 0

	/*
	 * Declare Allocation Cursor
	 */ 

	 declare alloc_csr cursor static for
	  select tc.tran_priority,
	         st.tran_age,
	         st.tran_date,
	         st.tran_id,
	         sum( sa.gross_amount )
	    from slide_transaction st,
	         transaction_category tc,   
	         slide_allocation sa  
	   where st.campaign_no = @campaign_no and
	         st.tran_id = sa.to_tran_id and
	         st.tran_category = tc.tran_category_code
	group by tc.tran_priority,
	         st.tran_age,
	         st.tran_date,
	         st.tran_id
	  having sum( sa.gross_amount ) > 0
	order by st.tran_age DESC,
	         tc.tran_priority ASC,
	         st.tran_date ASC,
	         st.tran_id ASC
	     for read only

	/*
    * Open Unalloc Cursor
    */

	open alloc_csr
	select @alloc_csr_flg = 1
	fetch alloc_csr into @alloc_priority, @alloc_age, @alloc_date, @alloc_tran, @alloc_amount
	while (@@fetch_status = 0 and @exit_loop = 0)
	begin
		
		/*
       * Calculate Tran Amount
       */

		if(@alloc_amount > @pay_remaining)
			select @tran_amount = @pay_remaining
		else
			select @tran_amount = @alloc_amount

		if(@tran_amount = 0)
			select @exit_loop = 1
		else
		begin

			/*
			 * Call Allocation Function
			 */
	
			select @tran_amount = 0 - @tran_amount
			execute @errorode = p_sfin_allocate_transaction @pay_tran, @alloc_tran, @tran_amount
			if (@errorode !=0)
				goto error
	
			/*
			 * Update Pay Amount Remaining
			 */
	
			select @pay_remaining = @pay_remaining + @tran_amount

			/*
			 * Fetch Next
			 */
		
			fetch alloc_csr into @alloc_priority, @alloc_age, @alloc_date, @alloc_tran, @alloc_amount

		end
	
	end

	close alloc_csr
	deallocate alloc_csr
	select @alloc_csr_flg = 0

	/*
    * Fetch Next
    */

	fetch pay_csr into @pay_date, @pay_tran, @pay_amount

end
close pay_csr
select @pay_csr_flg = 0
deallocate pay_csr


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
		close alloc_csr
		deallocate alloc_csr
	end

	return -1
GO
