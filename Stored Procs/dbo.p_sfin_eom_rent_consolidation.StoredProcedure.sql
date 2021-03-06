/****** Object:  StoredProcedure [dbo].[p_sfin_eom_rent_consolidation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_rent_consolidation]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_rent_consolidation]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_eom_rent_consolidation] @accounting_period		datetime,
                                          @include_slide			char(1)
with recompile as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @country_code				char(1),
        @complex_id					int,
        @cinema_rent					money,
        @film_billing				money,
		@film_commission			money,
        @film_billing_weighted		money,
		@film_commission_weighted	money,
        @slide_billing				money,
        @film_csr_open				tinyint,
        @slide_csr_open				tinyint,
        @new_rent_id             int,
        @cinema_rent_id          int

/*
 * Initialise Variables
 */

select @film_csr_open = 0,
       @slide_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Cinema Rent Records
 */

delete cinema_rent
 where accounting_period = @accounting_period

select @error = @@error
if @error != 0 
begin
	rollback transaction
	goto error
end

/*
 * Declare Cursors
 */

 declare film_csr cursor static for
  select b.country_code,
         fss.complex_id,
         sum(fss.rent_released),
		 sum(fss.billing_total),
		 sum(fss.commission_total),
         sum(fss.weighted_billings),
         sum(fss.weighted_commission)
    from film_spot_summary fss,
         film_campaign fc,   
         branch b
   where fss.accounting_period = @accounting_period and
         (fss.rent_released <> 0 or
			fss.billing_total <> 0) and
         fss.campaign_no = fc.campaign_no and
         fc.branch_code = b.branch_code
group by b.country_code,
         fss.complex_id
  having sum(fss.rent_released) <> 0 or
			sum(fss.billing_total) <> 0
order by b.country_code ASC,
         fss.complex_id ASC
     for read only

/*
 * Create Film Cinema Rent Consolidated Records
 */

open film_csr
select @film_csr_open = 1
fetch film_csr into @country_code, @complex_id, @cinema_rent, @film_billing, @film_commission, @film_billing_weighted, @film_commission_weighted
while(@@fetch_status = 0)
begin

	/*
    * Get Sequence No
    */

	execute @errorode = p_get_sequence_number 'cinema_rent',5,@new_rent_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Create Cinema Rent
    */

	insert into cinema_rent(
          cinema_rent_id,
          complex_id,
          country_code,
          accounting_period,
          slide_amount,
          film_amount,
			 film_billing_amount,
			 film_billing_weighted,
			 slide_billing_amount ) values (
	       @new_rent_id,
          @complex_id,
          @country_code,
          @accounting_period,
          0,
          isnull(@cinema_rent,0),
			 isnull(@film_billing,0) + isnull(@film_commission, 0),
			 isnull(@film_billing_weighted,0) + isnull(@film_commission_weighted, 0),
			 0 )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next
    */

	fetch film_csr into @country_code, @complex_id, @cinema_rent, @film_billing, @film_commission, @film_billing_weighted, @film_commission_weighted
	
end
close film_csr
deallocate film_csr
select @film_csr_open = 0

/*
 * Create Slide Cinema Rent Consolidated Records
 */

if(@include_slide = 'Y')
begin

	 declare slide_csr cursor static for
	  select b.country_code,
	         rd.complex_id,
	         sum(rdp.amount)
	    from rent_distribution_pool rdp,
	         rent_distribution rd, 
	         slide_campaign sc,   
	         branch b
	   where rdp.release_period = @accounting_period and
	         rdp.amount <> 0 and
	         rdp.rent_distribution_id = rd.rent_distribution_id and
	         rd.campaign_no = sc.campaign_no and
	         sc.branch_code = b.branch_code
	group by b.country_code,
	         rd.complex_id
	  having sum(rdp.amount) <> 0
	order by b.country_code ASC,
	         rd.complex_id ASC
	     for read only

	open slide_csr
	select @slide_csr_open = 1
	fetch slide_csr into @country_code, @complex_id, @cinema_rent
	while(@@fetch_status = 0)
	begin
	
		/*
		 * Check if the Film Creation has already created a record
		 */
		
		select @cinema_rent_id = null
	
		select @cinema_rent_id = cinema_rent_id
		  from cinema_rent
		 where country_code = @country_code and
				 accounting_period = @accounting_period and
				 complex_id = @complex_id
	
		select @cinema_rent_id = isnull(@cinema_rent_id,0)

		select @slide_billing = sum(total_amount)
		  from slide_spot_pool,
				 slide_campaign_spot,
             slide_campaign,
				 branch
		 where release_period = @accounting_period and
				 complex_id = @complex_id and
				 slide_spot_pool.spot_id = slide_campaign_spot.spot_id and
				 slide_campaign_spot.campaign_no = slide_campaign.campaign_no and
				 slide_campaign.branch_code = branch.branch_code and
				 branch.country_code = @country_code

		/*
		 * Create or Update Slide Cinema Rent
		 */
	
		if(@cinema_rent_id = 0)
		begin
	
			/*
			 * Get Sequence No
			 */
		
			execute @errorode = p_get_sequence_number 'cinema_rent',5,@new_rent_id OUTPUT
			if (@errorode !=0)
			begin
				rollback transaction
				goto error
			end
	
			/*
			 * Create Cinema Rent
			 */
		
			insert into cinema_rent(
					 cinema_rent_id,
					 complex_id,
					 country_code,
					 accounting_period,
					 slide_amount,
					 film_amount,
					 film_billing_amount,
					 film_billing_weighted,
					 slide_billing_amount ) values (
					 @new_rent_id,
					 @complex_id,
					 @country_code,
					 @accounting_period,
					 isnull(@cinema_rent,0),
					 0,
					 0,
					 -1,
					 isnull(@slide_billing,0) )
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end
	
		end
		else
		begin
	
			update cinema_rent
				set slide_amount = isnull(@cinema_rent,0),
					 slide_billing_amount = isnull(@slide_billing,0)
			 where cinema_rent_id = @cinema_rent_id
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end
	
		end
	
		/*
		 * Fetch Next
		 */
	
		fetch slide_csr into @country_code, @complex_id, @cinema_rent
		
	end
	close slide_csr
	deallocate slide_csr
	select @slide_csr_open = 0

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

	if (@film_csr_open = 1)
   begin
		close film_csr
		deallocate film_csr
	end

	if (@slide_csr_open = 1)
   begin
		close slide_csr
		deallocate slide_csr
	end
	raiserror ('Error : Failed to process rent consolidation.', 16, 1)
	return -1
GO
