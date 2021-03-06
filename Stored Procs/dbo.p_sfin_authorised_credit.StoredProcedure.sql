/****** Object:  StoredProcedure [dbo].[p_sfin_authorised_credit]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_authorised_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_authorised_credit]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_authorised_credit] @campaign_no			char(7),
                                     @credit_nett			money,
                                     @tran_date				datetime,
                                     @credit_gst_rate		decimal(6,4),
                                     @batch_item_no		integer
as

/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @outstanding_csr_open		tinyint,
        @spot_csr_open				tinyint,
        @reverse_csr_open			tinyint,
        @discount						numeric(6,4),
        @credit_inc_gst				money,
        @credit_gross				money,
        @credit_disc					money,
        @prev_billed					money,
        @prev_credit					money,
        @unc_tran_id					integer,
        @unc_tran_age				smallint,
        @unc_gst_rate				decimal(6,4),
        @unc_nett_amount			money,
        @billing_tran_id			integer,
        @agency_deal					char(1),
        @new_tran_desc				varchar(255),
        @tran_type_code				char(5),
        @tran_amount					money,
        @control_nett				money,
        @control_disc				money,
        @alloc_nett					money,
        @alloc_gross					money,
        @alloc_gross_gst			money,
        @alloc_disc					money,
        @alloc_disc_gst				money,
        @au_credit_id				integer,
        @au_adjustment_id			integer,
        @spot_id						integer,
        @spot_unc						money,
        @spot_credit					money,
        @pool_credit					money,
        @spot_disc_tran_id			integer,
        @loop_amount					money,
        @is_closed					char(1)






/*
 * Get Campaign Information
 */

select @discount = discount,
       @agency_deal = agency_deal,
       @is_closed = is_closed
  from slide_campaign
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	raiserror ('Authorised Credit - Error Retrieving Campaign Information.', 16, 1)
	return -1
end

/*
 * Return if Campaign is Closed
 */

if(@is_closed = 'Y')
begin
	raiserror ('Authorised Credit - Campaign is Closed.', 16, 1)
	return -1
end

/*
 * Determine Nett Amount and Discount Amount
 */

select @credit_gross = round((@credit_nett / (1 - @discount)),2)
select @credit_inc_gst = round((@credit_gross * (1 + @credit_gst_rate)),2)
select @credit_disc = @credit_gross - @credit_nett
 
/*
 * Check to see how much has already been credited
 */

select @prev_billed = isnull(sum(spot.nett_rate),0),
       @prev_credit = isnull(sum(spot.credit_value),0)
  from slide_campaign_spot spot,
       slide_spot_trans_xref xref,
       slide_transaction stran
 where spot.campaign_no = @campaign_no and
     ( spot.billing_status = 'B' or
       spot.billing_status = 'C' ) and
       spot.spot_id = xref.spot_id and
       xref.billing_tran_id = stran.tran_id and
       stran.gst_rate = @credit_gst_rate

select @error = @@error
if (@error !=0)
begin
	raiserror ('Authorised Credit - Error Retrieving Spot Billing and Credit Information.', 16, 1)
	return -1
end

/*
 * Return if Authorised Credit Request is too Large
 */

if(@credit_nett > (@prev_billed - @prev_credit))
begin
	raiserror ('p_sfin_authorised_credit : Authorised Credit Request is too Large', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Authorised Credit Transaction
 */

select @new_tran_desc = 'Authorised Billing Credit',
       @tran_type_code = 'SAUCR',
       @tran_amount = @credit_gross * -1

execute @errorode = p_sfin_create_transaction @tran_type_code,
                                           @campaign_no,
                                           NULL,
                                           @tran_date,
                                           @new_tran_desc,
                                           @tran_amount,
                                           @credit_gst_rate,
   													 @batch_item_no,
														 NULL,
                                           @au_credit_id OUTPUT
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Create Discount Credit Transaction
 */

if(@credit_disc > 0)
begin

	/*
    * Determine if the Campaign is an Agency Deal or 
    */

	select @agency_deal = agency_deal
     from slide_campaign 
    where campaign_no = @campaign_no

	if @agency_deal = 'Y'
	begin
		select @new_tran_desc = 'Agency Commission Adjustment',
		       @tran_type_code = 'ACADJ'
	end
	else
	begin
		select @new_tran_desc = 'Campaign Discount Adjustment',
		       @tran_type_code = 'SDADJ'
	end

	execute @errorode = p_sfin_create_transaction @tran_type_code,
															 @campaign_no,
															 NULL,
															 @tran_date,
															 @new_tran_desc,
															 @credit_disc,
															 @credit_gst_rate,
															 @batch_item_no,
															 NULL,
															 @au_adjustment_id OUTPUT
                                          
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

end

/*
 * Initialise Variables
 */

select @outstanding_csr_open = 0,
       @spot_csr_open = 0,
       @reverse_csr_open = 0,
       @control_nett = @credit_nett,
       @control_disc = @credit_disc

/*
 * First Pass
 * ----------
 * The first pass will see allocations made to all billings
 * that still have outstanding allocations.
 *
 */

/*
 * Declare Cursor
 */ 
 
 declare outstanding_csr cursor static for
  select st.tran_id,
         st.tran_age,
         st.gst_rate,
         sum(sa.nett_amount)
    from slide_transaction st,   
         slide_allocation sa  
   where st.campaign_no = @campaign_no and
         st.tran_id = sa.to_tran_id and
         st.tran_category = 'B' and
         st.gst_rate = @credit_gst_rate
group by st.tran_id,
         st.tran_age,   
			st.gst_rate
  having sum(sa.nett_amount) > 0
order by st.tran_age DESC,
         st.tran_id ASC
     for read only

open outstanding_csr
select @outstanding_csr_open = 1
fetch outstanding_csr into @unc_tran_id, @unc_tran_age, @unc_gst_rate, @unc_nett_amount
while (@@fetch_status = 0 and @control_nett > 0)
begin
	
	/*
    * Calculate Credit Allocation
    */

	if(@unc_nett_amount < @control_nett)
		select @alloc_nett = @unc_nett_amount
	else
		select @alloc_nett = @control_nett

	select @control_nett = @control_nett - @alloc_nett

	select @alloc_gross = round((@alloc_nett / (1 - @discount)),2)
	select @alloc_disc = @alloc_gross - @alloc_nett

	/*
    * Calculate Discount Allocation
    */

	select @spot_disc_tran_id = 0

	if(@alloc_disc > @control_disc)
		select @alloc_disc = @credit_disc

	/*
    * Reduce Spot Discount Amounts
    */

	select @billing_tran_id = @unc_tran_id
	select @loop_amount = @alloc_nett

	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.nett_rate - spot.credit_value,
	         IsNull(sst.discount_tran_id,0)
	    from slide_campaign_spot spot,
	         slide_spot_trans_xref sst
	   where sst.billing_tran_id = @billing_tran_id and
	         sst.spot_id = spot.spot_id and
	         spot.credit_value < spot.nett_rate
	order by spot.spot_no ASC
	     for read only

	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @spot_unc, @spot_disc_tran_id
	while (@@fetch_status = 0 and @loop_amount > 0)
	begin

		/*
       * Calculate Spot Credit
       */

		if(@spot_unc < @loop_amount)
			select @spot_credit = @spot_unc
		else
			select @spot_credit = @loop_amount
 
		select @loop_amount = @loop_amount - @spot_credit

		/*
       * Update Spot Credit Value
       */

		update slide_campaign_spot
         set credit_value = credit_value + @spot_credit
       where spot_id = @spot_id

		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error updating camapign spot values.', 16, 1)
			goto error
		end

		/*
		 * Update Slide Spot Pool
		 */
	
		select @pool_credit = @spot_credit
		exec @errorode = p_sfin_spot_pool_adj @spot_id, 'N', @pool_credit, 'C'
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
       * Fetch Next
       */

		fetch spot_csr into @spot_id, @spot_unc, @spot_disc_tran_id
	
	end
	close spot_csr
	deallocate spot_csr
	select @spot_csr_open = 0

	/*
    * Error if Money Left Over
    */

	if(@loop_amount > 0)
	begin
		rollback transaction
		raiserror ('Spot Credit Residual Detected. Authorised Credit Failed.', 16, 1)
		goto error
	end

	/*
    * Allocate Discount
    */

	if(@alloc_disc > 0)
	begin

		/*
       * Check Discount Tran Id
       */

		if(@spot_disc_tran_id = 0)
		begin
			rollback transaction
			raiserror ('Unable to find transaction for discount allocation.', 16, 1)
			goto error
		end
	
		/*
		 * Reverse any Allocations from the Discount Transaction
		 */

		select @alloc_disc_gst = round((@alloc_disc * (1 + @credit_gst_rate)),2)
		
		execute @errorode = p_sfin_transaction_unallocate @spot_disc_tran_id, 'N', @alloc_disc_gst
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
		 * Allocate Credit Discount Transaction
		 */

		select @tran_amount = @alloc_disc * -1

		execute @errorode = p_sfin_allocate_transaction @spot_disc_tran_id, @au_adjustment_id, @tran_amount
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
	end

	/*
	 * Reverse any Allocations to the Billing Transaction
	 */
	
	select @alloc_gross = @alloc_gross * -1
	select @alloc_gross_gst = round((@alloc_gross * (1 + @credit_gst_rate)),2)

	execute @errorode = p_sfin_transaction_unallocate @unc_tran_id, 'N', @alloc_gross_gst
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Allocate Credit Billing Transaction
    */

	select @tran_amount = @alloc_gross
	execute @errorode = p_sfin_allocate_transaction @au_credit_id, @unc_tran_id, @tran_amount
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next
    */

	fetch outstanding_csr into @unc_tran_id, @unc_tran_age, @unc_gst_rate, @unc_nett_amount

end
close outstanding_csr
deallocate outstanding_csr
select @outstanding_csr_open = 0

/*
 * Second Pass
 * -----------
 * The second pass will reverse any credits from the billings to 
 * make room for the authorised credit.
 *
 */
 declare reverse_csr cursor static for
  select sto.tran_id,
         sto.tran_age,
         sto.gst_rate,
         sum(sa.nett_amount) * -1
    from slide_transaction sto,
         slide_transaction sta,   
         slide_allocation sa  
   where sto.campaign_no = @campaign_no and
         sto.tran_category = 'B' and
         sto.gst_rate = @credit_gst_rate and
         sto.tran_id = sa.to_tran_id and
         sa.from_tran_id = sta.tran_id and
         sta.tran_category <> 'Z' and --Agency Commission or Discount
         sta.tran_category <> 'D' --Agency Commission or Discount
group by sto.tran_id,
         sto.tran_age,   
			sto.gst_rate
  having sum(sa.nett_amount) < 0
order by sto.tran_age ASC,
         sto.tran_id DESC
     for read only

open reverse_csr
select @reverse_csr_open = 1
fetch reverse_csr into @unc_tran_id, @unc_tran_age, @unc_gst_rate, @unc_nett_amount
while (@@fetch_status = 0 and @control_nett > 0)
begin

	/*
    * Calculate Credit Allocation
    */

	if(@unc_nett_amount < @control_nett)
		select @alloc_nett = @unc_nett_amount
	else
		select @alloc_nett = @control_nett

	select @control_nett = @control_nett - @alloc_nett

	select @alloc_gross = round((@alloc_nett / (1 - @discount)),2)
	select @alloc_disc = @alloc_gross - @alloc_nett

	/*
    * Calculate Discount Allocation
    */

	select @spot_disc_tran_id = 0

	if(@alloc_disc > @control_disc)
		select @alloc_disc = @credit_disc

	/*
    * Reduce Spot Discount Amounts
    */

	select @billing_tran_id = @unc_tran_id
	select @loop_amount = @alloc_nett

	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.nett_rate - spot.credit_value,
	         IsNull(sst.discount_tran_id,0)
	    from slide_campaign_spot spot,
	         slide_spot_trans_xref sst
	   where sst.billing_tran_id = @billing_tran_id and
	         sst.spot_id = spot.spot_id and
	         spot.credit_value < spot.nett_rate
	order by spot.spot_no ASC
	     for read only

	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @spot_unc, @spot_disc_tran_id
	while (@@fetch_status = 0 and @loop_amount > 0)
	begin

		/*
       * Calculate Spot Credit
       */

		if(@spot_unc < @loop_amount)
			select @spot_credit = @spot_unc
		else
			select @spot_credit = @loop_amount
 
		select @loop_amount = @loop_amount - @spot_credit

		/*
       * Update Spot Credit Value
       */

		update slide_campaign_spot
         set credit_value = credit_value + @spot_credit
       where spot_id = @spot_id

		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error updating camapign spot values.', 16, 1)
			goto error
		end

		/*
		 * Update Slide Spot Pool
		 */
	
		select @pool_credit = @spot_credit
		exec @errorode = p_sfin_spot_pool_adj @spot_id, 'N', @pool_credit, 'C'
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
       * Fetch Next
       */

		fetch spot_csr into @spot_id, @spot_unc, @spot_disc_tran_id
	
	end
	close spot_csr
	deallocate spot_csr
	select @spot_csr_open = 0

	/*
    * Error if Money Left Over
    */

	if(@loop_amount > 0)
	begin
		rollback transaction
		raiserror ('Spot Credit Residual Detected. Authorised Credit Failed.', 16, 1)
		goto error
	end

	/*
    * Allocate Discount
    */

	if(@alloc_disc > 0)
	begin

		/*
       * Check Discount Tran Id
       */

		if(@spot_disc_tran_id = 0)
		begin
			rollback transaction
			raiserror ('Unable to find transaction for discount allocation.', 16, 1)
			goto error
		end
	
		/*
		 * Reverse any Allocations from the Discount Transaction
		 */

		select @alloc_disc_gst = round((@alloc_disc * (1 + @credit_gst_rate)),2)
		
		execute @errorode = p_sfin_transaction_unallocate @spot_disc_tran_id, 'N', @alloc_disc_gst
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
		 * Allocate Credit Discount Transaction
		 */

		select @tran_amount = @alloc_disc * -1

		execute @errorode = p_sfin_allocate_transaction @spot_disc_tran_id, @au_adjustment_id, @tran_amount
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
	end

	/*
	 * Reverse any Allocations to the Billing Transaction
	 */
	
	select @alloc_gross = @alloc_gross * -1
	select @alloc_gross_gst = round((@alloc_gross * (1 + @credit_gst_rate)),2)

	execute @errorode = p_sfin_transaction_unallocate @unc_tran_id, 'N', @alloc_gross_gst
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Allocate Credit Billing Transaction
    */

	select @tran_amount = @alloc_gross
	execute @errorode = p_sfin_allocate_transaction @au_credit_id, @unc_tran_id, @tran_amount
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next
    */

	fetch reverse_csr into @unc_tran_id, @unc_tran_age, @unc_gst_rate, @unc_nett_amount

end
close reverse_csr
deallocate reverse_csr
select @reverse_csr_open = 0

/*
 * Error if Credit is Not fully Allocated
 */

if(@control_nett > 0)
begin
	rollback transaction
	raiserror ('Credit Residual Detected. Authorised Credit Failed.', 16, 1)
	goto error
end

/*
 * Call Resync Slide Distribution
 */

execute @errorode = p_resync_campaign_distribution @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Call Payment Allocations
 */

execute @errorode = p_sfin_payment_allocation @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Call Balance Update
 */

execute @errorode = p_sfin_slide_campaign_balance @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@outstanding_csr_open = 1)
   begin
		close outstanding_csr
		deallocate outstanding_csr
	end

	if (@spot_csr_open = 1)
   begin
		close spot_csr
		deallocate spot_csr
	end

	if (@reverse_csr_open = 1)
   begin
		close reverse_csr
		deallocate reverse_csr
	end

	return -1
GO
