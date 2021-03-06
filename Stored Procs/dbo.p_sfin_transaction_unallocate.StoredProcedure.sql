/****** Object:  StoredProcedure [dbo].[p_sfin_transaction_unallocate]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_transaction_unallocate]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_transaction_unallocate]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_transaction_unallocate] @tran_id				integer,
                                          @full_reversal		char(1),
                                          @reversal_amount	money
as
set nocount on 
declare @error							integer,
        @errorode							integer,
	     @sqlstatus					integer,
        @rev_csr_open				tinyint,
        @is_charge					char(1),
        @new_alloc_id				integer,
        @tran_amount					money,
        @orig_gross					money,
        @unc_gross					money,
        @unc_gst_rate				numeric(6,4),
	     @unc_id						integer,
	     @unc_alloc					money,
        @alloc_nett					money,
        @alloc_gross					money,
        @alloc_alloc					money,
        @alloc_gst_amount			money,
        @gross_reserve				money,
        @source_tran_id				money

/*
 * Get the Transaction Amount
 */
 
select @orig_gross = st.gross_amount
  from slide_transaction st
 where st.tran_id = @tran_id

select @error = @@error
if (@error !=0)
	return -1

/*
 * Initialise Cursor Flags
 */
 
select @rev_csr_open = 0

/*
 * Determine Charge / Credit and Define Cursors
 */

if(@orig_gross > 0)
begin

	select @is_charge = 'Y'

	/*
    * Declare Unallocate Cursor
    */

	declare rev_csr cursor static for
   select sa.from_tran_id,
          sa.slide_allocation_id,
          sa.gross_amount,
          sa.gst_rate,
          sa.alloc_amount
     from slide_allocation sa,
          slide_transaction st
    where sa.to_tran_id = @tran_id and
          sa.from_tran_id = st.tran_id and
          st.tran_category <> 'Z' and --Agency Commission or Discount
          st.tran_category <> 'D' --Agency Commission or Discount
 group by sa.from_tran_id,
          sa.slide_allocation_id,
          sa.gross_amount,
          sa.gst_rate,
          sa.alloc_amount
   having sum(sa.gross_amount) <> 0
 order by sa.from_tran_id DESC
      for read only

	/*
    * Select Reserve Amount
    */

	select @gross_reserve = sum(gross_amount)
     from slide_allocation sa
    where sa.to_tran_id = @tran_id

	select @error = @@error
	if (@error !=0)
		return -1

	if(@full_reversal = 'N')
	begin
		if(abs(@reversal_amount) <= @gross_reserve)
			select @gross_reserve = 0
		else
			select @gross_reserve = abs(@reversal_amount) - @gross_reserve
	end
	else
		select @gross_reserve = abs(@orig_gross) - @gross_reserve 

end
else
begin

	select @is_charge = 'N'

	/*
    * Declare Unallocate Cursor
    */

	declare rev_csr cursor static for
   select sa.to_tran_id,
          sa.slide_allocation_id,
          sa.gross_amount,
          sa.gst_rate,
          sa.alloc_amount
     from slide_allocation sa,
          slide_transaction st
    where sa.from_tran_id = @tran_id and
          sa.to_tran_id = st.tran_id and
          st.tran_category <> 'Z' and --Agency Commission or Discount
          st.tran_category <> 'D' --Agency Commission or Discount
 group by sa.to_tran_id,
          sa.slide_allocation_id,
          sa.gross_amount,
          sa.gst_rate,
          sa.alloc_amount
   having sum(sa.gross_amount) <> 0
-- order by sa.from_tran_id DESC
      for read only

	/*
    * Select Reserve Amount
    */

	select @gross_reserve = sum(gross_amount)
     from slide_allocation sa
    where sa.from_tran_id = @tran_id

	select @error = @@error
	if (@error !=0)
		return -1

	if(@full_reversal = 'N')
	begin
		if(abs(@reversal_amount) <= @gross_reserve)
			select @gross_reserve = 0
		else
			select @gross_reserve = abs(@reversal_amount) - @gross_reserve
	end
	else
		select @gross_reserve = abs(@orig_gross) - @gross_reserve 

end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Reverse Allocations
 */

open rev_csr
select @rev_csr_open = 1
fetch rev_csr into @source_tran_id, @unc_id, @unc_gross, @unc_gst_rate, @unc_alloc
while(@@fetch_status = 0 and @gross_reserve > 0)
begin

	/*
    * Calculate Amount to Apply
    */
	
	if(abs(@unc_gross) >= @gross_reserve)
	begin
		select @alloc_gross = @gross_reserve * ((@unc_gross / abs(@unc_gross) ) * -1)
		select @gross_reserve = 0
	end
	else
	begin
		select @alloc_gross = @unc_gross * -1
		select @gross_reserve = @gross_reserve - abs(@unc_gross)
	end

	select @alloc_nett = round((@alloc_gross / (1 + @unc_gst_rate)),2)
	select @alloc_gst_amount = @alloc_gross - @alloc_nett

	/*
    * Calculate Allocate Amount
    */

	if(@unc_alloc <> 0)
		select @alloc_alloc = @alloc_nett * -1
	else
		select @alloc_alloc = 0

	/*
    * Get Allocation Id
    */

	execute @errorode = p_get_sequence_number 'slide_allocation',5,@new_alloc_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end
	 
	/*
	 * Insert Reverse Transaction Allocation
	 */

	insert into slide_allocation (
	       slide_allocation_id,   
	       from_tran_id,   
	       to_tran_id,   
	       nett_amount,   
	       gst_amount,   
	       gst_rate,   
	       gross_amount,
          alloc_amount,   
	       pay_gst,   
	       process_period,
          age_code,   
	       entry_date )  
   select @new_alloc_id,
          from_tran_id,
          to_tran_id,
	       @alloc_nett,
	       @alloc_gst_amount,
	       gst_rate,           
	       @alloc_gross,
	       @alloc_alloc,
	       0,
          null,               
          age_code,
          getdate()
     from slide_allocation
    where slide_allocation_id = @unc_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next Allocation
    */

	fetch rev_csr into @source_tran_id, @unc_id, @unc_gross, @unc_gst_rate, @unc_alloc

end   

close rev_csr
select @rev_csr_open = 0
deallocate rev_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@rev_csr_open = 1)
   begin
		close rev_csr
		deallocate rev_csr
	end

	return -1
GO
