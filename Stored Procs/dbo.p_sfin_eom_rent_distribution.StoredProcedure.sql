/****** Object:  StoredProcedure [dbo].[p_sfin_eom_rent_distribution]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_rent_distribution]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_rent_distribution]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_eom_rent_distribution] @accounting_period		datetime
as

/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @rent_csr_open				tinyint,
        @rent_id						integer,
        @rent_actual					money,
        @rent_bill					money,
        @rent_pool					money,
        @slide_pool					money,
        @var_total					money,
        @var_curr						money,
        @alloc_curr					money,
        @alloc_adj					money,
        @pool_id						integer,
        @rent_adj						money,
        @bill_total					money,
        @rent_calc					money,
        @full_allocate				char(1),
		@campaign_no				char(7)


/*
 * Begin Transaction
 */

begin transaction

/*
 * Initialise Variables
 */

select @rent_csr_open = 0,
       @bill_total = 0,
       @full_allocate = 'N'


/*
 * Declare Cursors
 */ 
 
declare 	campaign_csr cursor static forward_only for
select 		campaign_no
from		slide_campaign
where		not exists ( select 1 
                        from campaign_event
                       where campaign_event.campaign_no = slide_campaign.campaign_no and
                             campaign_event.event_type = 'F' )	
order by 	campaign_no

open campaign_csr 
fetch campaign_csr into @campaign_no
while(@@fetch_status=0)
begin

	 declare rent_csr cursor static for
	  select rd.rent_distribution_id,
	         rd.original_allocation,
	         rd.billing_accrual
	    from rent_distribution rd
	   where rd.campaign_no = @campaign_no
	order by rd.complex_id ASC
	     for read only
	
	/*
	 * Adjustment Loop
	 * ---------------
	 * This loops through the rent distribution records creating adjustments 
	 * if the allocated amounts exceed the current billing acrrual levels.
	 *
	 */
	
	open rent_csr
	select @rent_csr_open = 1
	fetch rent_csr into @rent_id, @rent_actual, @rent_bill
	while (@@fetch_status = 0)
	begin
	
		/*
	    * Increment Bill Total
	    */
	
		select @bill_total = @bill_total + @rent_bill
	
		/*
	    * Calculate Current Allocation Level
	    */
	
		select @alloc_curr = isnull(sum(rdp.amount),0)
	     from rent_distribution_pool rdp
	    where rent_distribution_id = @rent_id
	
		/*
	    * Create Adjustment
	    */
	
		if(@rent_bill < @alloc_curr)
		begin
	
			/*
	       * Calculate Adjustment
	       */
	
			select @alloc_adj = @rent_bill - @alloc_curr
	
			/*
	       * Get New Distribution Pool Id
	       */
	
			execute @errorode = p_get_sequence_number 'rent_distribution_pool',5,@pool_id OUTPUT
			if (@errorode !=0)
			begin
				rollback transaction
				goto error
			end
	
			/*
	       * Create Transaction in the Rent Distribution Pool
	       */
	
			insert into rent_distribution_pool (
	             rent_dts_pool_id,
	             rent_distribution_id,
	             release_period,
	             amount ) values (
	             @pool_id,
	             @rent_id,
	             @accounting_period,
	             @alloc_adj )
	
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
		
		fetch rent_csr into @rent_id, @rent_actual, @rent_bill
	
	end
	close rent_csr
	deallocate rent_csr
	select @rent_csr_open = 0
	
	/*
	 * Calculate Total Available
	 */
	
	select @slide_pool = isnull(sum(sdp.rent_amount),0)
	  from slide_distribution_pool sdp,
	       slide_distribution sd
	 where sdp.slide_distribution_id = sd.slide_distribution_id and
	       sd.campaign_no = @campaign_no and
	       sd.distribution_type = 'R' -- Theatre Rent
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end
	
	/*
	 * Calculate Total Allocations
	 */
	
	select @rent_pool = isnull(sum(rdp.amount),0)
	  from rent_distribution_pool rdp,
	       rent_distribution rd
	 where rdp.rent_distribution_id = rd.rent_distribution_id and
	       rd.campaign_no = @campaign_no
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end
	
	/*
	 * Calculate Variance
	 */
	
	select @rent_calc = @slide_pool - @rent_pool
	
	/*
	 * Calculate Variance Totals
	 */
	
	if(@rent_calc < 0)
		select @var_total = @rent_pool
	else
	begin
		select @var_total = @bill_total - @rent_pool
		if(@var_total = 0)
			select @rent_calc = 0
	end
	
	/*
	 * Allocation Loop
	 * ---------------
	 * This loops through the rent distribution records creating transactions
	 * for additions or subtractions. These allocations were calculated above
	 * based on the level of allocations available versus what has already been 
	 * allocated to the cinemas.
	 *
	 */
	
	if(@rent_calc != 0)
	begin
		/*
		 * Declare Cursors
		 */ 
		 
		 declare rent_csr cursor static for
		  select rd.rent_distribution_id,
		         rd.original_allocation,
		         rd.billing_accrual
		    from rent_distribution rd
		   where rd.campaign_no = @campaign_no
		order by rd.complex_id ASC
		     for read only
	
	
		open rent_csr
		select @rent_csr_open = 1
		fetch rent_csr into @rent_id, @rent_actual, @rent_bill
		while (@@fetch_status = 0)
		begin
		
			/*
			 * Calculate Current Allocation Level
			 */
		
			select @alloc_curr = isnull(sum(rdp.amount),0)
			  from rent_distribution_pool rdp
			 where rent_distribution_id = @rent_id
		
			/*
			 * Calculate Adjustment
			 */
		
			select @rent_adj = 0
		
			if(@rent_calc < 0)
			begin
		
				select @var_curr = @alloc_curr
				select @rent_adj = round((@rent_calc * convert(decimal(15,8),(convert(decimal(15,8),@var_curr) / convert(decimal(15,8),@var_total)))),4)
				if((@alloc_curr + @rent_adj) < 0)
					select @rent_adj = 0 - @alloc_curr
		
			end
		
			if(@rent_calc > 0)
			begin
		
				select @var_curr = @rent_bill - @alloc_curr
				select @rent_adj = round((@rent_calc * convert(decimal(15,8),(convert(decimal(15,8),@var_curr) / convert(decimal(15,8),@var_total)))),4)
				if((@alloc_curr + @rent_adj) > @rent_bill)
					select @rent_adj = @var_curr
		
			end
		
			/*
			 * Create Adjustment
			 */
		
			if(@rent_adj != 0)
			begin
		
				/*
				 * Get New Distribution Pool Id
				 */
		
				execute @errorode = p_get_sequence_number 'rent_distribution_pool',5,@pool_id OUTPUT
				if (@errorode !=0)
				begin
					rollback transaction
					goto error
				end
		
				/*
				 * Create Transaction in the Rent Distribution Pool
				 */
		
				insert into rent_distribution_pool (
						 rent_dts_pool_id,
						 rent_distribution_id,
						 release_period,
						 amount ) values (
						 @pool_id,
						 @rent_id,
						 @accounting_period,
						 @rent_adj )
		
				select @error = @@error
				if (@error !=0)
				begin
					rollback transaction
					goto error
				end
		
			end
		
			/*
			 * Update Running Totals
			 */
			
			select @var_total = @var_total - @var_curr
			select @rent_calc = @rent_calc - @rent_adj
		
			/*
			 * Fetch Next
			 */
			
			fetch rent_csr into @rent_id, @rent_actual, @rent_bill
		
		end
		close rent_csr
		select @rent_csr_open = 0
		deallocate rent_csr
	
	end

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

	if (@rent_csr_open = 1)
   begin
		close rent_csr
		deallocate rent_csr
	end
	raiserror ('Error : Failed to process rent distributions', 16, 1)
	return -1
GO
