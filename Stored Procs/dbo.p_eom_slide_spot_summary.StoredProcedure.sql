/****** Object:  StoredProcedure [dbo].[p_eom_slide_spot_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_slide_spot_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_slide_spot_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_slide_spot_summary] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
		@rowcount     			integer,
		@errorode					integer,
		@errno					integer,
		@country_code			char(1),
		@complex_id				integer,
		@billing_total 			money,
		@payment_total 			money,
		@baddebt_total 			money,
		@rent_allocated 		money,
		@rent_released 			money,
		@rent_cancelled 		money,
		@cplx_csr_open			tinyint,
		@sound_total			money,   
		@cinema_total			money,   
		@slide_total			money,
		@total_amount			money,
		@total_complex			money,
		@campaign_no			char(7)
                                     
/*
 * Begin Transaction
 */

begin transaction

declare 	campaign_csr cursor static forward_only for
select 		distinct sc.campaign_no
from 		rent_distribution_pool rdp,
			rent_distribution rd,
			slide_campaign sc
where 		rdp.rent_distribution_id = rd.rent_distribution_id and
			rd.campaign_no = sc.campaign_no and
			rdp.release_period = @accounting_period  
union
select 		distinct sc.campaign_no
from 		slide_spot_pool ssp,
			slide_campaign_spot spot,
			slide_campaign sc
where 		spot.campaign_no = sc.campaign_no and
			spot.spot_id = ssp.spot_id and
			ssp.release_period = @accounting_period
order by 	sc.campaign_no


open campaign_csr 
fetch campaign_csr into @campaign_no
while(@@fetch_status=0)
begin

	/*
	 * Initialise Cursor Flags
	 */
	
	select @cplx_csr_open = 0
	
	/*
	 * Get Country Code
	 */
	
	select @country_code = c.country_code
	  from slide_campaign fc,
	       branch b,
	       country c 
	 where fc.campaign_no = @campaign_no and
	       fc.branch_code = b.branch_code and
	       b.country_code = c.country_code
	
	select @error = @@error,
	       @rowcount = @@rowcount
	
	if(@error != 0 or @rowcount != 1)
	begin
		raiserror ('Slide Spot Summary: Error retrieving country code.', 16, 1)
		return -1
	end
	
	
	
	/*
	 * Delete Existing Summary Data
	 */
	
	delete slide_spot_summary
	 where campaign_no = @campaign_no and
	       accounting_period = @accounting_period
	
	select @errno = @@error
	if	(@errno != 0)
		goto error
	
	/*
	 * Loop Complexes
	 */
	
	 declare complex_csr cursor static for
	  select distinct complex_id
	    from slide_campaign_complex
	   where campaign_no = @campaign_no 
	order by complex_id
	     for read only
	
	open complex_csr
	select @cplx_csr_open = 1
	fetch complex_csr into @complex_id
	while(@@fetch_status = 0)
	begin
	
		
		/*
	    * Reset Variables
	    */
	
	
		select @billing_total = 0.0,
	          @payment_total = 0.0,
	          @baddebt_total = 0.0,
	          @rent_allocated = 0.0,
	          @rent_released = 0.0,
	          @rent_cancelled = 0.0,
				 @sound_total = 0.0,
			    @cinema_total = 0.0,
			    @slide_total = 0.0
	
		/*
		 * Calculate Payment Total
		 */
		
	  select @payment_total = sum(rdp.amount)
	    from rent_distribution_pool rdp,
	         rent_distribution rd, 
	         slide_campaign sc
	   where rdp.release_period = @accounting_period and
	         rdp.amount <> 0 and
	         rdp.rent_distribution_id = rd.rent_distribution_id and
	         rd.campaign_no = sc.campaign_no and
				rd.complex_id = @complex_id and
	         sc.campaign_no = @campaign_no
	
		select @payment_total = Isnull(@payment_total,0.0) 
	
			
		/*
		 * Calculate Cinema Rent Allocated
		 */
	
		select @rent_allocated = sum(rdp.amount)
		  from rent_distribution rd, 
				 rent_distribution_pool rdp
		 where rd.campaign_no = @campaign_no and
	          rdp.release_period = @accounting_period and
	          rd.complex_id = @complex_id and
				 rd.rent_distribution_id = rdp.rent_distribution_id
	
		select @rent_allocated = Isnull(@rent_allocated,0.0)
	
		select @rent_released = @rent_allocated
	
		/*
		 * Calculate Rent Cancelled
		 */
	
		select @rent_cancelled = Isnull(@rent_cancelled,0.0)
	
		/*
		 * Calculate cinema_total, slide_total, sound_total
		 */
	
		select @slide_total  = sum(ssp.slide_amount),
				 @sound_total = sum(ssp.sound_amount),
				 @cinema_total = sum(ssp.cinema_amount)	
		  from slide_campaign_spot spot,
	          slide_spot_pool ssp
		 where spot.campaign_no = @campaign_no and
	          spot.spot_id = ssp.spot_id and
	          ssp.release_period = @accounting_period and
	          ssp.complex_id = @complex_id and
				 ssp.spot_pool_type <> 'D' 
	
		select @slide_total = Isnull(@slide_total,0.0)
		select @sound_total = Isnull(@sound_total,0.0)
		select @cinema_total = Isnull(@cinema_total,0.0)
	
		/*
		 * Calculate Bad Debt Total
		 */
	
		select @baddebt_total  = sum(ssp.total_amount)
		  from slide_campaign_spot spot,
	          slide_spot_pool ssp
		 where spot.campaign_no = @campaign_no and
	          spot.spot_id = ssp.spot_id and
	          ssp.release_period = @accounting_period and
	          ssp.complex_id = @complex_id and
				 ssp.spot_pool_type = 'D' 
	
		select @baddebt_total = Isnull(@baddebt_total,0.0)
	
		/*
	    * Calculate Billing Total
	    */
	
		select @billing_total = @sound_total + @cinema_total + @slide_total
	
		/*
		 * Create Summary Record
		 */
	
		if( @billing_total <> 0 or 
	       @payment_total <> 0 or
	       @baddebt_total <> 0 or
	       @rent_allocated <> 0 or
	       @rent_released <> 0 or
	       @rent_cancelled <> 0 or
			 @sound_total <> 0 or
			 @cinema_total <> 0 or
			 @slide_total <> 0)
		begin
	
			insert into slide_spot_summary ( 
					 campaign_no,
					 accounting_period,
					 complex_id,
					 billing_total,
	             payment_total,
	             baddebt_total,
	             rent_allocated,
	             rent_released,
	             rent_cancelled,
	             country_code,
					 sound_total,
			       cinema_total,
			       slide_total) values (
					 @campaign_no,
					 @accounting_period,
					 @complex_id,
	             @billing_total,
	             @payment_total,
	             @baddebt_total,
	             @rent_allocated,
	             @rent_released,
	             @rent_cancelled,
	             @country_code,
					 @sound_total,
			       @cinema_total,
			       @slide_total )
	
			select @errno = @@error
			if (@errno != 0)
				goto error
	
		end
	
		/*
	    * Fetch Next
	    */
	
		fetch complex_csr into @complex_id
	
	end
	close complex_csr
	select @cplx_csr_open = 0
	deallocate complex_csr

	fetch campaign_csr into @campaign_no
end

deallocate campaign_csr
/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	 rollback transaction
	 if(@cplx_csr_open = 1)
    begin
		 close complex_csr
		 deallocate complex_csr
	 end
	 raiserror ('Error : Failed to create slide spot aummary for Slide Campaign %1!',11,1, @campaign_no)
	 return -1
GO
