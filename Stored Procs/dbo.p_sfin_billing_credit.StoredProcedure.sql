/****** Object:  StoredProcedure [dbo].[p_sfin_billing_credit]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_billing_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_billing_credit]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_billing_credit] @campaign_no		char(7),
                                  @tran_date			datetime,
                                  @credit_start		datetime,
                                  @credit_end		datetime,
											 @credit_amount	money,
                                  @as_suspension   char(1),
                                  @batch_item_no   integer
as

/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @check_csr_open				tinyint,
        @spot_csr_open				tinyint,
        @tran_csr_open				tinyint,
        @spot_id						integer,
        @billing_tran_id			integer,
        @discount_tran_id			integer,
        @spot_billing_status		char(1),
        @spot_credit_value			money,
        @spot_gst						money,
        @spot_gross					money,
        @spot_nett					money,
        @spot_disc					money,
        @spot_gross_tot				money,
        @spot_nett_tot				money,
        @spot_disc_tot				money,
		  @total_credit_amount		money,
        @spot_gst_rate				numeric(6,4),
        @check_gst_rate				numeric(6,4),
        @loop							integer,
        @new_tran_desc				varchar(255),
        @actual_end_date			datetime,
        @credit_start_str			varchar(11),
        @credit_end_str				varchar(11),
        @credit_tran_id				integer,
        @adjustment_tran_id		integer,
        @agency_deal					char(1),
        @tran_amount					money,
        @tran_type_code				char(5),
        @min_week_adj				smallint,
        @spot_nett_neg				money,
        @is_closed					char(1)



/*
 * Initialise Variables
 */

select @check_csr_open = 0,
       @spot_csr_open = 0,
       @tran_csr_open = 0,
       @spot_gross_tot = 0,
       @spot_nett_tot = 0,
       @spot_disc_tot = 0,
       @loop = 0,
       @total_credit_amount = 0

/*
 * Check Campaign Closed
 */

select @is_closed = is_closed
  from slide_campaign
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	raiserror ('Billing Credit - Error Retrieving Campaign Information.', 16, 1)
	return -1
end

if(@is_closed = 'Y')
begin
	raiserror ('Billing Credit - Campaign is Closed.', 16, 1)
	return -1
end

/*
 * Spot Check
 * ----------
 * Ensure spots have never been credited before and all spots have the same
 * rate of GST.
 *
 */
 declare check_csr cursor static for
  select spot.spot_id,
         spot.billing_status,
         spot.credit_value
    from slide_campaign_spot spot
   where spot.campaign_no = @campaign_no and
         spot.screening_date >= @credit_start and
         spot.screening_date <= @credit_end
order by spot.spot_id
     for read only

open check_csr
select @check_csr_open = 1
fetch check_csr into @spot_id, @spot_billing_status, @spot_credit_value
while (@@fetch_status = 0)
begin

	select @loop = @loop + 1

	/*
    * Check Credit Value
    */

	if(@spot_credit_value > 0)
	begin
		raiserror ('Billing Credit - Some spots have already been Credited. Billing Credit Cancelled.', 16, 1)
		goto error
	end

	/*
    * Check Billing Status
    */

	if(@spot_billing_status <> 'B')
	begin
		raiserror ('Billing Credit - Some spots have not yet been Billed. Billing Credit Cancelled.', 16, 1)
		goto error
	end

	/*
    * Check GST Rate
    */

	select @spot_gst_rate = IsNull(stran.gst_rate,-1)
     from slide_transaction stran,
          slide_spot_trans_xref xref
    where xref.spot_id = @spot_id and
          xref.billing_tran_id = stran.tran_id

	if(@spot_gst_rate = -1)
	begin
		raiserror ('Billing Credit - Error Checking GST Rate on Spots.', 16, 1)
		goto error
	end

	if(@loop = 1)
		select @check_gst_rate = @spot_gst_rate
	else
	begin
		if(@spot_gst_rate <> @check_gst_rate)
		begin
			raiserror ('Billing Credit - Different GST Rates were detected amongst the Spots.', 16, 1)
			goto error
		end
	end

	/*
    * Fetch Next
    */

	fetch check_csr into @spot_id, @spot_billing_status, @spot_credit_value

end
close check_csr
deallocate check_csr
select @check_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Spot Loop
 * ---------
 * Loop through all spots calculating the amount to credit as well as
 * updating the spot billing status and credit values.
 *
 */

 declare spot_csr cursor static for
  select spot.spot_id,
         spot.gross_rate,
         spot.nett_rate
    from slide_campaign_spot spot
   where spot.campaign_no = @campaign_no and
         spot.screening_date >= @credit_start and
         spot.screening_date <= @credit_end
order by spot.spot_id
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_id, @spot_gross, @spot_nett
while (@@fetch_status = 0)
begin

	/*
    * Sum Nett and Gross Rates
    */

	select @spot_gross_tot = @spot_gross_tot + @spot_gross,
          @spot_nett_tot = @spot_nett_tot + @spot_nett,
          @spot_disc_tot = @spot_disc_tot + (@spot_gross - @spot_nett)

	/*
    * Update Spot
    */

	update slide_campaign_spot
      set billing_status = 'C',
          credit_value = @spot_nett
    where spot_id = @spot_id

	select @total_credit_amount = @total_credit_amount + @spot_nett

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

	/*
    * Update Slide Spot Pool
    */

	exec @errorode = p_sfin_spot_pool_adj @spot_id, 'Y', @spot_nett, 'C'
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
	 *	 Update rent and slide_distributions
	 */

	select @spot_nett_neg = @spot_nett * -1

	/*
    * Fetch Next
    */

	fetch spot_csr into @spot_id, @spot_gross, @spot_nett

end
close spot_csr
deallocate spot_csr
select @spot_csr_open = 0

if @total_credit_amount <> @credit_amount
begin
	raiserror ('Billing Credit - Credit amount does not match total amount to Credit on Spots.', 16, 1)
	rollback transaction
	goto error
end

/*
 * Create Billing Credit Transaction
 */

select @actual_end_date = dateadd(dd,6,@credit_end)
select @min_week_adj = datediff(wk,@credit_start,@actual_end_date)
exec p_sfin_format_date @credit_start, 1 , @credit_start_str OUTPUT
exec p_sfin_format_date @actual_end_date, 1 , @credit_end_str  OUTPUT

if @as_suspension = 'N'
begin
	select @new_tran_desc = rtrim(convert(char(3), @min_week_adj ))
								 + ' Week Billing Credit from '
								 + @credit_start_str + ' To '
								 + @credit_end_str

	select @tran_type_code = 'SBCR' 

end
else
begin
	if @min_week_adj > 1
	begin
		select @new_tran_desc = 'Screening of your still commercial has been suspended for a period of '
										+ rtrim(convert(char(3), @min_week_adj )) + ' Weeks from '
									   + @credit_start_str + ' To ' + @credit_end_str 
                              + char(13) + char(10) + 'A credit for the period has been passed.'
	end
	else
	begin
		select @new_tran_desc = 'Screening of your still commercial has been suspended for a period of '
										+ rtrim(convert(char(3), @min_week_adj )) + ' Week from '
									   + @credit_start_str + ' To ' + @credit_end_str 
                              + char(13) + char(10) + 'A credit for the period has been passed.'

	end
	select @tran_type_code = 'SUSCR' 

end

select @tran_amount = @spot_gross_tot * -1

execute @errorode = p_sfin_create_transaction @tran_type_code,
                                           @campaign_no,
                                           NULL,
                                           @tran_date,
                                           @new_tran_desc,
                                           @tran_amount,
                                           @check_gst_rate,
														 @batch_item_no,
														 NULL,
                                           @credit_tran_id OUTPUT
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Create Discount Credit Transaction
 */

if(@spot_disc_tot > 0)
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
															 @spot_disc_tot,
															 @check_gst_rate,
                                              @batch_item_no,
															 NULL,
															 @adjustment_tran_id OUTPUT
                                          
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

end

/*
 * Process Transactions
 */

 declare tran_csr cursor static for
  select sst.billing_tran_id,
         isnull(sst.discount_tran_id,0),
         sum(spot.gross_rate),
         sum(spot.nett_rate)
    from slide_spot_trans_xref sst,
         slide_campaign_spot spot
   where sst.spot_id = spot.spot_id and
         spot.campaign_no = @campaign_no and
         spot.screening_date >= @credit_start and
         spot.screening_date <= @credit_end
group by sst.billing_tran_id,
         isnull(sst.discount_tran_id,0)
order by sst.billing_tran_id DESC
     for read only

open tran_csr
select @tran_csr_open = 1
fetch tran_csr into @billing_tran_id, @discount_tran_id, @spot_gross, @spot_nett
while (@@fetch_status = 0)
begin

	/*
    * Calculate Discount Amount
    */

	select @spot_disc = @spot_gross - @spot_nett

	/*
	 * Reverse any Allocations from the Discount
	 */
	
	if(@discount_tran_id > 0)
	begin

		select @spot_gst = round((@spot_disc * (1 + @check_gst_rate)),2)
		
		/*
		 * Reverse any Allocations from the Discount Transaction
		 */
		
		execute @errorode = p_sfin_transaction_unallocate @discount_tran_id, 'N', @spot_gst
																
		if (@errorode !=0)
		begin
			rollback transaction
			return -1
		end

		/*
		 * Allocate Credit Discount Transaction
		 */

		select @tran_amount = @spot_disc * -1
		execute @errorode = p_sfin_allocate_transaction @discount_tran_id, @adjustment_tran_id, @tran_amount
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

	end

	/*
	 * Reverse any Allocations to the Billing Transaction
	 */
	
	select @spot_gross = @spot_gross * -1
	select @spot_gst = round((@spot_gross * (1 + @check_gst_rate)),2)

	execute @errorode = p_sfin_transaction_unallocate @billing_tran_id, 'N', @spot_gst
															
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end

	/*
    * Allocate Credit Billing Transaction
    */

	select @tran_amount = @spot_gross
	execute @errorode = p_sfin_allocate_transaction @credit_tran_id, @billing_tran_id, @tran_amount
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next
    */

	fetch tran_csr into @billing_tran_id, @discount_tran_id, @spot_gross, @spot_nett

end
close tran_csr
deallocate tran_csr
select @tran_csr_open = 0

/*
 * Update Campaign
 */

update slide_campaign
   set min_campaign_period = min_campaign_period + @min_week_adj
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
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

	if (@check_csr_open = 1)
   begin
		close check_csr
		deallocate check_csr
	end

	if (@spot_csr_open = 1)
   begin
		close spot_csr
		deallocate spot_csr
	end

	if (@tran_csr_open = 1)
   begin
		close tran_csr
		deallocate tran_csr
	end

	return -1
GO
