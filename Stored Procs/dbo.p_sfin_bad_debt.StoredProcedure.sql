/****** Object:  StoredProcedure [dbo].[p_sfin_bad_debt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_bad_debt]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_bad_debt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_bad_debt] @campaign_no		char(7),
                            @tran_date			datetime,
                            @batch_item_no   integer,
                            @bd_amount			money OUTPUT
as

/*
 * Declare Valiables
 */ 

declare @error							integer,
        @sqlstatus					integer,
        @errorode							integer,
        @balance_credit				money,
        @un_type						char(1),
        @tran_id						integer,
        @tran_type					integer,
        @gross_amount				money,
        @nett_amount					money,
        @gst_amount					money,
        @gst_rate						decimal(6,4),
        @bd_nett_amount				money,
        @bd_gross_amount			money,
        @spot_csr_open				tinyint,
        @unalloc_csr_open			tinyint,
        @gst_rate_csr_open			tinyint,
        @tran_desc					varchar(255),
        @bd_tran_id					integer,
        @spot_id						integer,
        @spot_disc_tran_id			integer,
        @unbilled_spots				integer,
        @is_closed					char(1),
        @spot_unc						money,
		  @pool_credit					money,
        @loop_amount					money,
        @p_desc						varchar(100)






/*
 * Initialise Variables
 */

select @bd_amount = 0,
       @unalloc_csr_open = 0,
       @gst_rate_csr_open = 0

/*
 *	Check Campaign is Ok to Bad Debt
 */

select @balance_credit = balance_credit,
       @is_closed = is_closed
  from slide_campaign
 where campaign_no = @campaign_no

select @unbilled_spots = count(*)
  from slide_campaign_spot
 where campaign_no = @campaign_no and
		 ( billing_status = 'U' or 
         billing_status = 'L' )

/*
 * Error and Return if Cannot Bad Debt
 */

if(@is_closed = 'Y')
begin
	raiserror ('Bad Debt - Campaign is Closed.', 16, 1)
	return -1
end

if(@balance_credit <> 0) --Campaign has a credit value and cannot be bad debted.
begin
	raiserror ('Bad Debt - Campaign is in Credit.', 16, 1)
	return -1
end

if(@unbilled_spots <> 0)
begin
	raiserror ('Bad Debt - Campaign is not Entirely Billed.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 *	Calculate Amount for Bad Debt.
 */
declare gst_rate_csr cursor static for
  select distinct st.gst_rate
    from slide_transaction st,   
         slide_allocation sa  
   where st.tran_id = sa.to_tran_id and
         st.campaign_no = @campaign_no and
         st.tran_type <> 54 --Bad Debt
group by st.tran_id,   
         st.tran_type,
			st.gst_rate
  having sum( sa.nett_amount ) > 0
order by st.gst_rate
	for read only

open gst_rate_csr
select @gst_rate_csr_open = 1
fetch gst_rate_csr into @gst_rate
while (@@fetch_status = 0)
begin

	select @bd_nett_amount = 0
	select @bd_gross_amount = 0

	declare unalloc_csr cursor static for
	  select 'T' as un_type,        --Unallocated To transactions (billings, charges etc)
	         st.tran_id,
	         st.tran_type, 
	         sum( sa.nett_amount ),
	         sum( sa.gross_amount )
	    from slide_transaction st,   
	         slide_allocation sa  
	   where st.tran_id = sa.to_tran_id and
	         st.campaign_no = @campaign_no and
	         st.tran_type <> 54 and --Bad Debt
				st.gst_rate = @gst_rate
	group by st.tran_id,   
	         st.tran_type,
				st.gst_rate
	  having sum( sa.nett_amount ) > 0
	union
	  select 'F' as un_type,		--Unallocated From transactions (payments, credits etc)
	         st.tran_id,   
	         st.tran_type,   
	         sum( sa.nett_amount ),
	         sum( sa.gross_amount )
	    from slide_transaction st,   
	         slide_allocation sa  
	   where st.tran_id = sa.from_tran_id and
	         st.campaign_no = @campaign_no and
	         st.tran_type <> 54 and --Bad Debt
				st.gst_rate = @gst_rate
	group by st.tran_id,   
	         st.tran_type,
				st.gst_rate
	  having sum( sa.nett_amount ) > 0
	order by un_type,st.tran_id
	for read only

	open unalloc_csr
	select @unalloc_csr_open = 1
	fetch unalloc_csr into @un_type,	@tran_id, @tran_type, @nett_amount, @gross_amount
	while (@@fetch_status = 0)
	begin

		if @un_type = 'F'
		begin
			rollback transaction
			raiserror ('Bad Debt - Campaign has Unallocated Payments or Credits.', 16, 1)
			goto error
		end
	
		select @bd_nett_amount = @bd_nett_amount + @nett_amount
		select @bd_gross_amount = @bd_gross_amount + @gross_amount

		/*
       * Fetch Next
       */

		fetch unalloc_csr into @un_type,	@tran_id, @tran_type, @nett_amount, @gross_amount

	end
	close unalloc_csr
	deallocate unalloc_csr
	select @unalloc_csr_open = 0	
	
	if @bd_nett_amount = 0
	begin
		rollback transaction
		raiserror ('Bad Debt - Campaign has no Unallocated Charges to Bad Debt.', 16, 1)
		goto error
	end
	
	/*
	 *	Insert Bad Debt Transaction.
	 */

	select @bd_nett_amount = @bd_nett_amount * -1
	select @bd_gross_amount = @bd_gross_amount * -1

	select @tran_desc =  'Campaign Bad Debt'
	exec @errorode = p_sfin_create_trans_gross 'SDEBT',
														 @campaign_no,
														 null,
														 @tran_date,
														 @tran_desc,
														 @bd_nett_amount,
														 @bd_gross_amount,
 														 @gst_rate,
                                           @batch_item_no,
														 @bd_tran_id OUTPUT

	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end
	
	/*
	 *	Loop over unalloced trans again, this time assigning any unalloced 
    * portion to the bad debt.
    *
	 */

	declare unalloc_csr cursor static for
	  select 'T' as un_type,        --Unallocated To transactions (billings, charges etc)
	         st.tran_id,
	         st.tran_type, 
	         sum( sa.nett_amount ),
	         sum( sa.gross_amount )
	    from slide_transaction st,   
	         slide_allocation sa  
	   where st.tran_id = sa.to_tran_id and
	         st.campaign_no = @campaign_no and
	         st.tran_type <> 54 and --Bad Debt
				st.gst_rate = @gst_rate
	group by st.tran_id,   
	         st.tran_type,
				st.gst_rate
	  having sum( sa.nett_amount ) > 0
	union
	  select 'F' as un_type,		--Unallocated From transactions (payments, credits etc)
	         st.tran_id,   
	         st.tran_type,   
	         sum( sa.nett_amount ),
	         sum( sa.gross_amount )
	    from slide_transaction st,   
	         slide_allocation sa  
	   where st.tran_id = sa.from_tran_id and
	         st.campaign_no = @campaign_no and
	         st.tran_type <> 54 and --Bad Debt
				st.gst_rate = @gst_rate
	group by st.tran_id,   
	         st.tran_type,
				st.gst_rate
	  having sum( sa.nett_amount ) > 0
	order by un_type,st.tran_id
	for read only

	open unalloc_csr
	select @unalloc_csr_open = 1
	fetch unalloc_csr into @un_type,	@tran_id, @tran_type, @nett_amount, @gross_amount
	while (@@fetch_status = 0)
	begin

		select @nett_amount = @nett_amount * -1,
             @gross_amount = @gross_amount * -1
	
		exec @errorode = p_sfin_allocate_trans_gross @bd_tran_id,@tran_id, @nett_amount, @gross_amount
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
       *  Adjust slide spot pool records if transaction is a billing.
       */
		if (@tran_type = 50) --Slide billings.
		begin
			select @nett_amount = @nett_amount * -1

			 declare spot_csr cursor static for
			  select spot.spot_id,
			         spot.nett_rate - spot.credit_value,
			         IsNull(sst.discount_tran_id,0)
			    from slide_campaign_spot spot,
			         slide_spot_trans_xref sst
			   where sst.billing_tran_id = @tran_id and
			         sst.spot_id = spot.spot_id and
			         spot.credit_value < spot.nett_rate
			order by spot.spot_no ASC
			     for read only

			open spot_csr
			select @spot_csr_open = 1
			fetch spot_csr into @spot_id, @spot_unc, @spot_disc_tran_id
			while (@@fetch_status = 0)
			begin
				/*
				 * Update Slide Spot Pool
				 */

				if @nett_amount > @spot_unc
					select @pool_credit = @spot_unc
				else
					select @pool_credit = @nett_amount

				select @nett_amount = @nett_amount - @pool_credit

				if @pool_credit <> 0 
				begin
					exec @errorode = p_sfin_spot_pool_adj @spot_id, 'N', @pool_credit, 'D'
					if (@errorode !=0)
					begin
						rollback transaction
						goto error
					end
				end
		
				/*
				 * Fetch Next
				 */
		
				fetch spot_csr into @spot_id, @spot_unc, @spot_disc_tran_id
			end
			close spot_csr
			deallocate spot_csr
			select @spot_csr_open = 0		

			if @nett_amount <> 0
			begin
				rollback transaction
				raiserror ('Bad Debt - Spot residual detected. Cannot continue.', 16, 1)
				goto error
			end

		end


		/*
       * Fetch Next
       */
	
		fetch unalloc_csr into @un_type,	@tran_id, @tran_type, @nett_amount, @gross_amount

	end
	close unalloc_csr
	deallocate unalloc_csr
	select @unalloc_csr_open = 0	

	/*
    * Sum all the nett amounts bad debted to return to the calling procedure.
    */

	select @bd_amount = @bd_amount + @bd_nett_amount

	/*
    * Fetch Next
    */

	fetch gst_rate_csr into @gst_rate

end
close gst_rate_csr
deallocate gst_rate_csr
select @gst_rate_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@unalloc_csr_open = 1)
   begin
		close unalloc_csr
		deallocate unalloc_csr
	end

	if (@gst_rate_csr_open = 1)
   begin
		close gst_rate_csr
		deallocate gst_rate_csr
	end

	return -1
GO
