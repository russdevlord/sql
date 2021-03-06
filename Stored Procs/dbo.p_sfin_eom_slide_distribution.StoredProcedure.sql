/****** Object:  StoredProcedure [dbo].[p_sfin_eom_slide_distribution]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_slide_distribution]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_slide_distribution]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_eom_slide_distribution] @accounting_period	datetime
as

/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @asc_csr_open				tinyint,
        @desc_csr_open				tinyint,
        @alloc_orig					money,
        @avail_orig					money,
        @avail_work					money,
        @alloc_amount				money,
        @pool_id						integer,
        @sld_id						integer,
        @sld_accrual					money,
        @sld_type						char(1),
        @sld_adjustment				money,
        @sld_over						money,
        @sld_rent						money,
		@campaign_no				char(7)
        
/*
 * Initialise Variables
 */

select @asc_csr_open = 0,
       @desc_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

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

	/*
	 * Calculate Total Available
	 */
	
	select @avail_orig = isnull(sum(sa.alloc_amount),0)
	  from slide_transaction st,
	       slide_allocation sa
	 where st.campaign_no = @campaign_no and
	       st.tran_id = sa.from_tran_id and --makes it payments
	       sa.process_period is not null
	
	select @error = @@error
	if (@error !=0)
		goto error
	
	/*
	 * Calculate Total Allocations
	 */
	
	select @alloc_orig = isnull(sum(sdp.alloc_amount),0)
	  from slide_distribution_pool sdp,
	       slide_distribution sd
	 where sdp.slide_distribution_id = sd.slide_distribution_id and
	       sd.campaign_no = @campaign_no
	
	select @error = @@error
	if (@error !=0)
		goto error
	
	/*
	 * Initialise Available Variable
	 */
	
	select @avail_work = @avail_orig - @alloc_orig
	
	 
	
	 declare desc_csr cursor static for
	  select sd.slide_distribution_id,
	         sd.accrued_alloc,
	         sd.distribution_type
	    from slide_distribution sd,
	         slide_distribution_type sdt
	   where sd.campaign_no = @campaign_no and
	         sd.distribution_type = sdt.distribution_type_code
	order by sdt.priority DESC
	     for read only
	
	   
	/*
	 * Descending Pass
	 * ---------------
	 * This pass goes through the allocations to remove allocations 
	 * if the accrual amounts are below that which has currently 
	 * been allocated.
	 *
	 */
	
	open desc_csr
	select @desc_csr_open = 1
	fetch desc_csr into @sld_id, @sld_accrual, @sld_type
	while (@@fetch_status = 0)
	begin
	
		/*
	    * Adjust Slide Accrual
	    */
	
		if(@sld_accrual < 0)
			select @sld_accrual = 0
	
		/*
	    * Calculate Current Allocated Value
	    */
	
		select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
	     from slide_distribution_pool sdp
	    where slide_distribution_id = @sld_id
	
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
	    * Calculate Adjustment
	    */
	
		select @sld_adjustment = 0
	
		if(@avail_work < 0)
		begin
	
			if((@avail_work + @alloc_amount) < 0)
				select @sld_adjustment = 0 - @alloc_amount
			else
				select @sld_adjustment = @avail_work
	
			select @avail_work = @avail_work - @sld_adjustment
	
		end
	
		if((@alloc_amount + @sld_adjustment) > @sld_accrual)
		begin
	
			select @sld_over = @sld_accrual - (@alloc_amount + @sld_adjustment)
			select @avail_work = @avail_work - @sld_over
			select @sld_adjustment = @sld_adjustment + @sld_over
	
		end
	
		/*
	    * Adjust if Necassary
	    */
	
		if(@sld_adjustment < 0)
		begin
	
			if(@sld_type = 'R')
				select @sld_rent = @sld_adjustment
			else
				select @sld_rent = 0
			
			/*
	       * Get New Distribution Pool Id
	       */
	
			execute @errorode = p_get_sequence_number 'slide_distribution_pool',5,@pool_id OUTPUT
			if (@errorode !=0)
			begin
				rollback transaction
				goto error
			end
	
			/*
	       * Create Adjustment Transaction in the Distribution Pool
	       */
	
			insert into slide_distribution_pool (
	             slide_dts_pool_id,
	             slide_distribution_id,
	             process_period,
	             alloc_amount,
	             rent_amount,
	             entry_date ) values (
	             @pool_id,
	             @sld_id,
	             @accounting_period,
	             @sld_adjustment,
	             @sld_rent,
	             getdate() )
	
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
	
		fetch desc_csr into @sld_id, @sld_accrual, @sld_type
	
	end
	close desc_csr
	deallocate desc_csr
	select @desc_csr_open = 0
	
	/*
	 * Ascending Pass
	 * --------------
	 * This pass goes through the surplus allocations to remove allocations 
	 * if the accrual amounts are below that which has currently 
	 * been allocated.
	 *
	 */
	
	/*
	 * Declare Cursors
	 */ 
	 
	 declare asc_csr cursor static for
	  select sd.slide_distribution_id,
	         sd.accrued_alloc,
	         sd.distribution_type
	    from slide_distribution sd,
	         slide_distribution_type sdt
	   where sd.campaign_no = @campaign_no and
	         sd.distribution_type = sdt.distribution_type_code
	order by sdt.priority ASC
	     for read only
	
	open asc_csr
	select @asc_csr_open = 1
	fetch asc_csr into @sld_id, @sld_accrual, @sld_type
	while (@@fetch_status = 0 and @avail_work > 0)
	begin
	
		/*
	    * Calculate Current Allocated Value
	    */
	
		select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
	     from slide_distribution_pool sdp
	    where slide_distribution_id = @sld_id
	
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
	    * Calculate Adjustnent
	    */
	
		select @sld_adjustment = 0
	
		if(@alloc_amount < @sld_accrual)
		begin
			
			select @sld_over = @sld_accrual - @alloc_amount
	
			if(@sld_over < @avail_work)
				select @sld_adjustment = @sld_over
			else
				select @sld_adjustment = @avail_work
	
			select @avail_work = @avail_work - @sld_adjustment
	
		end
	
		/*
	    * Adjust if Necassary
	    */
	
		if(@sld_adjustment > 0)
		begin
	
			if(@sld_type = 'R')
				select @sld_rent = @sld_adjustment
			else
				select @sld_rent = 0
			
			/*
	       * Get New Distribution Pool Id
	       */
	
			execute @errorode = p_get_sequence_number 'slide_distribution_pool',5,@pool_id OUTPUT
			if (@errorode !=0)
			begin
				rollback transaction
				goto error
			end
	
			/*
	       * Create Adjustment Transaction in the Distribution Pool
	       */
	
			insert into slide_distribution_pool (
	             slide_dts_pool_id,
	             slide_distribution_id,
	             process_period,
	             alloc_amount,
	             rent_amount,
	             entry_date ) values (
	             @pool_id,
	             @sld_id,
	             @accounting_period,
	             @sld_adjustment,
	             @sld_rent,
	             getdate() )
	
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
	
		fetch asc_csr into @sld_id, @sld_accrual, @sld_type
	
	end
	close asc_csr
	deallocate asc_csr
	select @asc_csr_open = 0

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

	if (@desc_csr_open = 1)
   begin
		close desc_csr
		deallocate desc_csr
	end

	if (@asc_csr_open = 1)
   begin
		close asc_csr
		deallocate asc_csr
	end
	raiserror ('Error : Failed to allocate slide distributions.', 16, 1)
	return -1
GO
