/****** Object:  StoredProcedure [dbo].[p_eom_spot_allocation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_spot_allocation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_spot_allocation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[p_eom_spot_allocation] @allocation_id			int,
										  @accounting_period		datetime,
										  @session_id               int
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode						int,
        @alloc_amount				numeric(20,4),
        @spot_csr_open				tinyint,
        @spot_id					int,
        @spot_count					int,
        @cinelight_spot_count		int,
        @inclusion_spot_count		int,
        @outpost_spot_count			int,
        @tran_id					int,
        @to_tran_type				int,
        @from_tran_type				int,
        @spot_weight				float,
        @cinema_weight				float,
        @complex_id					int,
        @spot_row					int,
        @spot_calc					numeric(20,4),
        @cinema_calc				numeric(20,4),
        @new_spot_total				numeric(20,4),
        @new_cinema_total			numeric(20,4),
        @cinema_rent				numeric(20,4),
        @liability_id				int,
        @ltype						smallint,
        @sqlstat					int,
        @spot_rem					numeric(20,4),
        @spot_work					numeric(20,4),
        @cinema_rem					numeric(20,4),
        @cinema_work				numeric(20,4),
        @spot_type                  char(1),
        @spot_redirect              int,
        @sr_spot_id                 int,
        @sr_complex_id				int,
        @dandc                      char(1),
        @destination_campaign       int,
        @record_exists              int,
        @source_campaign            int,
        @origin_period              datetime,
        @spot_cancelled             int,
		@reversal					char(1)


/*
 * Get Allocation Amount
 */

select @alloc_amount = alloc_amount
  from transaction_allocation
 where allocation_id = @allocation_id

if (@@error !=0)
begin
  	raiserror ('Error: Failed to Create Spot Allocations for Allocation ID %1!',11,1, @allocation_id)
	return -1
end	

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Transaction Allocation
 */

update transaction_allocation
   set process_period = @accounting_period
 where allocation_id = @allocation_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	goto error
end	

/*
 * If not allocating to spots then commit transaction and return success
 */

if(@alloc_amount = 0)
begin
	commit transaction
	return 0
end

/*
 * Retrieve Transaction Allocation Details
 */

select @tran_id = ta.to_tran_id,
       @to_tran_type = ctto.tran_type,
       @from_tran_type = ctfrom.tran_type,
	   @reversal = ctfrom.reversal	
  from transaction_allocation ta,
       campaign_transaction ctto,
       campaign_transaction ctfrom
 where ta.allocation_id = @allocation_id and
       ta.to_tran_id = ctto.tran_id and
       ta.from_tran_id = ctfrom.tran_id

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0 or @rowcount=0)
begin
	rollback transaction
	raiserror ('Error', 16, 1)
	goto error
end	

/*
 * Count number of spots in the Cursor
 */

select @spot_count = IsNull(count(cs.spot_id),0)
  from film_spot_xref fsx,
       campaign_spot cs
 where fsx.tran_id = @tran_id and
       fsx.spot_id = cs.spot_id and
       cs.spot_weighting > 0

select @cinelight_spot_count = IsNull(count(cs.spot_id),0)
  from cinelight_spot_xref fsx,
       cinelight_spot cs
 where fsx.tran_id = @tran_id and
       fsx.spot_id = cs.spot_id and
       cs.spot_weighting > 0

select @outpost_spot_count = IsNull(count(cs.spot_id),0)
  from outpost_spot_xref fsx,
       outpost_spot cs
 where fsx.tran_id = @tran_id and
       fsx.spot_id = cs.spot_id and
       cs.spot_weighting > 0

select @inclusion_spot_count = IsNull(count(cs.spot_id),0)
  from inclusion_spot_xref fsx,
       inclusion_spot cs
 where fsx.tran_id = @tran_id and
       fsx.spot_id = cs.spot_id and
       cs.spot_weighting > 0

select @spot_work = @alloc_amount
select @cinema_work = @alloc_amount

/*
 * Setup Liability Type
 */

select @ltype = @from_tran_type

if(@from_tran_type = 1) -- Film Billing
begin
    if(@alloc_amount < 0 and @reversal = 'N')
        select @ltype = 7 -- Film Billing Credit
        
end

if(@from_tran_type = 40) -- Cineads Billing
begin
    if(@alloc_amount < 0 and @reversal = 'N')
        select @ltype = 40 -- Cineads Billing Credit
	else
		select @ltype = 38 --Cinelight Billing
end

if(@from_tran_type = 41) --CINEads Acomm
	select @ltype = 39 -- CINEads Acomm

if(@from_tran_type = 5) -- DMG Billing
begin
    if(@alloc_amount < 0 and @reversal = 'N')
        select @ltype = 8 -- DMG Billing Credit
end

if(@from_tran_type = 73) --Cinelight Billing
begin
	if(@alloc_amount < 0  and @reversal = 'N')
		select @ltype = 13 -- Cinelight Billing Credit
	else
		select @ltype = 11 --Cinelight Billing
end

if(@from_tran_type = 74) --Cinelight Acomm
	select @ltype = 12 -- Cinelight Cinelight Acomm
	
if(@from_tran_type = 36) --TAP Acomm
	select @ltype = 35 -- Tap Acomm

	
if(@from_tran_type = 37) --TAP Billing Credit
	select @ltype = 36 -- Tap Billing Credit


if(@from_tran_type = 75) --Cinelight Billing Credit
	select @ltype = 13 -- Cinelight Cinelight Acomm

if(@from_tran_type = 88) --Cinemarketing Billing
begin
	if(@alloc_amount < 0  and @reversal = 'N')
		select @ltype = 16 -- Cinemarketing Billing Credit
	else
		select @ltype = 14 -- Cinemarketing Billings
end

if(@from_tran_type = 90) --Cinemarketing Billing Credit
	select @ltype = 16 -- Cinemarketing Billing Credit

if(@from_tran_type = 42) --Cineads Billing Credit
	select @ltype = 40 -- Cineads Billing Credit

if(@from_tran_type = 89) --Cinemarketing Acomm
	select @ltype = 15 -- Cinemarketing Cinelight Acomm

if(@from_tran_type = 77) --Film Takeout
	select @ltype = 17 -- Film Takeout

if(@from_tran_type = 79) --DMG Takeout
	select @ltype = 18 -- DMG Takeout

if(@from_tran_type = 44) --Cineads Takeout
	select @ltype = 41 --Cineads Takeout
	
if(@from_tran_type = 81) --Cinelight Takeout
	select @ltype = 19 -- Cinelight Takeout

if(@from_tran_type = 83) --Cinemarketing Takeout
	select @ltype = 20 --Cinemarketing Takeout

if(@from_tran_type = 173) --FANDOM Takeout
	select @ltype = 173 --FANDOM Takeout
if(@from_tran_type = 178) --THE LATCH Takeout
	select @ltype = 178 --THE LATCH Takeout
if(@from_tran_type = 183) --THRILLIST Takeout
	select @ltype = 183 --THRILLIST Takeout
if(@from_tran_type = 188) --POPSUGAR Takeout
	select @ltype = 188 --POPSUGAR Takeout

if(@from_tran_type = 172) --FANDOM Billing Credit
	select @ltype = 172 --FANDOM Billing Credit
if(@from_tran_type = 177) --THE LATCH Billing Credit
	select @ltype = 177 --THE LATCH Billing Credit
if(@from_tran_type = 182) --THRILLIST Billing Credit
	select @ltype = 182 --THRILLIST Billing Credit
if(@from_tran_type = 187) --POPSUGAR Billing Credit
	select @ltype = 187 --POPSUGAR Billing Credit

if(@from_tran_type = 84) --Media Proxy
	select @ltype = 1 -- Film Billing

if(@from_tran_type = 85) --Media Proxy Acom
	select @ltype = 2 --Film  A/comm

if(@from_tran_type = 86) --Media Proxy
	select @ltype = 5 -- DMG Billing

if(@from_tran_type = 87) --Media Proxy Acom
	select @ltype = 6 --DMG  A/comm

if(@from_tran_type = 101) --Retail Billing
begin
	if(@alloc_amount < 0  and @reversal = 'N')
		select @ltype = 152 -- Retail Billing Credit
	else
		select @ltype = 150 -- Retail Billing	
end

if(@from_tran_type = 107) --Retail Wall Billing
begin
	if(@alloc_amount < 0  and @reversal = 'N')
		select @ltype = 156 -- Retail Wall Billing Credit
	else
		select @ltype = 154 -- Retail Wall Billing
end

if(@from_tran_type = 102) --Retail Acomm
	select @ltype = 151 -- Retail Cinelight Acomm

if(@from_tran_type = 108) --Retail Acomm
	select @ltype = 155 -- Retail Cinelight Acomm

if(@from_tran_type = 104) --Retail Takeout
	select @ltype = 153 --Retail Takeout

if(@from_tran_type = 103) --Retail Billing Credit
	select @ltype = 152 --Retail Billing Credit

if(@from_tran_type = 109) --Retail Wall Billing Credit
	select @ltype = 156 --Retail Wall Billing Credit
	
if(@from_tran_type = 134) --Retail Wall Billing Credit
	select @ltype = 153 --Retail Wall Billing Credit	

if(@from_tran_type = 67) --Retail Wall Billing Credit
	select @ltype = 153 --Retail Wall Billing Credit	
	

/*
 * Loop Through Spots
 */

if @spot_count > 0 
begin
	select @spot_row = 0
	
	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.spot_redirect,
	         spot.spot_type,
	         spot.spot_weighting,
	         spot.cinema_weighting,
	         spot.complex_id,
	         spot.dandc,
	         spot.campaign_no
	    from campaign_spot spot,
	         film_spot_xref fsx
	   where fsx.tran_id = @tran_id and
	         fsx.spot_id = spot.spot_id and
	         spot.spot_weighting > 0
	order by spot.spot_id,
			 spot.spot_redirect DESC
	     for read only
	
	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @spot_redirect, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	while(@@fetch_status=0)
	begin
	
		select @spot_row = @spot_row + 1
	
	    /*
	     * Calculate Spot Re-Direct
	     */
	
	    select @sr_spot_id = @spot_id,
	           @sr_complex_id = @complex_id
	
	   	while(isnull(@spot_redirect, 0) != 0)
		begin
	
	        select @sr_spot_id = spot_id,
	               @sr_complex_id = complex_id,
	               @spot_redirect = spot_redirect
	          from campaign_spot
	         where spot_id = @spot_redirect
	
	        select @error = @@error,
	               @rowcount = @@rowcount
	        
	        if(@error !=0 or @rowcount=0)
	        begin
	            raiserror ('Error Loading Spot Redirect Info for Spot Id: %1!',11,1, @spot_redirect)
	        	rollback transaction
	        	goto error
	        end	
	
	    end
	
	   	/*
	     * Get Totals Remaining
	     */
		
		select @spot_rem = sum(spot_amount),
	           @cinema_rem = sum(cinema_amount),
	           @origin_period = min(origin_period)
	      from spot_liability
	     where spot_id = @spot_id
	
		/*
	     * Determine Amount to Allocate
	     */
	
		select @spot_calc = round(@spot_weight * @alloc_amount,2)
		select @cinema_calc = round(@cinema_weight * @alloc_amount,2)
	
	--	print 'Calculated Spot Allocation: %1!' , @spot_calc
	--	print 'Calculated Cinema Allocation: %1!' , @cinema_calc
	
		if(@spot_row = @spot_count)	
		begin
			select @new_spot_total = @spot_work
			select @new_cinema_total = @cinema_work
		end
		else
		begin
			select @new_spot_total = @spot_calc
			select @new_cinema_total = @cinema_calc
		end
	
	-- 	print 'New Spot: %1!' , @new_spot_total
	-- 	print 'New Cinema: %1!' , @new_cinema_total
	
		/*
	    * Calculate Cinema Rent
	    */
	
		if(@to_tran_type = 1 and @ltype = 3) or (@to_tran_type = 5 and @ltype = 3)
			select @cinema_rent = 0 - @new_cinema_total
		else
			select @cinema_rent = 0
	        
	    /*
	     * Check if liablity should be cancelled or not
	     */        
	     
	    select @spot_cancelled = count(dcs.spot_id)
	      from delete_charge_spots dcs,
	           delete_charge dc
	     where dcs.delete_charge_id = dc.delete_charge_id
	       and dc.confirmed = 'Y'
	       and dcs.source_dest = 'S'
	       and dcs.spot_id = @spot_id

		select @spot_cancelled = isnull(@spot_cancelled, 0)
	     
		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'spot_liability',5,@liability_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
		 * Insert Liability Record
		 */
		
		insert into spot_liability (
				 spot_liability_id,
				 spot_id,
				 complex_id,
				 liability_type,
	             allocation_id,
				 spot_amount,
				 cinema_amount,
	             cancelled,
	             creation_period,
	             origin_period,
	             cinema_rent,
	             original_liability ) values (
				 @liability_id,
				 @sr_spot_id,
				 @sr_complex_id,
				 @ltype,
	             @allocation_id,
				 isnull(@new_spot_total,0),
				 isnull(@new_cinema_total,0),
	             @spot_cancelled,
	             @accounting_period,
	             @origin_period,
	             isnull(@cinema_rent,0),
	             0 )
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	    
	    if @dandc = 'Y'
	    begin
	        
	        select @destination_campaign = null
	            
	        select @destination_campaign = dc.destination_campaign
	          from delete_charge dc,
	               delete_charge_spots dcs
	         where dcs.spot_id = @spot_id
	           and dcs.delete_charge_id = dc.delete_charge_id 
	           and dcs.source_dest = 'S'
	           and dc.confirmed = 'Y'
	      
	        if @destination_campaign is not null
	        begin
	        
	            select @record_exists = count(destination_campaign)
	              from work_spot_allocation
	             where destination_campaign = @destination_campaign
	               and source_campaign = @source_campaign
	               and allocation_id = @allocation_id
	               and liability_type = @ltype
	               
	            if @record_exists = 0
	            begin
	            
	                insert into work_spot_allocation
	                    (session_id,
	                    source_campaign,
	                    destination_campaign,
	                    allocation_amount,
	                    liability_type,
	                    allocation_id,
						alloc_primary) values
	                    (@session_id,
	                    @source_campaign, 
	                    @destination_campaign,
	                    @new_spot_total,
	                    @ltype,
	                    @allocation_id,
						@allocation_id)
	                    
	            end
	            else if @record_exists > 0
	            begin
	            
	                update work_spot_allocation
	                   set allocation_amount = allocation_amount + @new_spot_total
	                 where destination_campaign = @destination_campaign
	                   and source_campaign = @source_campaign
	                   and allocation_id = @allocation_id
	                   and liability_type = @ltype
	                   and session_id = @session_id
	                   
	            end
	
	        end         
	    end
	
		/*
	    * Decrease Allocated Work Amounts
	    */
	
		select @spot_work = @spot_work - @new_spot_total
		select @cinema_work = @cinema_work - @new_cinema_total
		
		/*
	    * Fetch Next Spot
	    */
	
	    fetch spot_csr into @spot_id, @spot_redirect, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	end
	close spot_csr
	select @spot_csr_open = 0
	deallocate spot_csr
end

if @cinelight_spot_count > 0 
begin
	
	select @spot_row = 0
	
	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.spot_type,
	         spot.spot_weighting,
	         spot.cinema_weighting,
	         (select distinct complex_id from cinelight_spot_liability where spot_id = spot.spot_id and liability_type = 11),
	         spot.dandc,
	         spot.campaign_no
	    from cinelight_spot spot,
	         cinelight_spot_xref fsx
	   where fsx.tran_id = @tran_id and
	         fsx.spot_id = spot.spot_id and
	         spot.spot_weighting > 0
	order by spot.spot_id
	     for read only
	
	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	while(@@fetch_status=0)
	begin

		/*
   		 * If No Billing transaction complex has been found in cursor default to wherever the cinelight is now.
		 */

		if @complex_id is null
		begin
			select 	@complex_id = cl.complex_id
			from	cinelight_spot spot,
					cinelight cl
			where	cl.cinelight_id = spot.cinelight_id
			and 	spot.spot_id = @spot_id
		end
	
		select @spot_row = @spot_row + 1
	
	   	/*
	     * Get Totals Remaining
	     */
		
		select @spot_rem = sum(spot_amount),
	           @cinema_rem = sum(cinema_amount),
	           @origin_period = min(origin_period)
	      from cinelight_spot_liability
	     where spot_id = @spot_id
	
		/*
	     * Determine Amount to Allocate
	     */
	
		select @spot_calc = round(@spot_weight * @alloc_amount,2)
		select @cinema_calc = round(@cinema_weight * @alloc_amount,2)
	
		if(@spot_row = @cinelight_spot_count)	
		begin
			select @new_spot_total = @spot_work
			select @new_cinema_total = @cinema_work
		end
		else
		begin
			select @new_spot_total = @spot_calc
			select @new_cinema_total = @cinema_calc
		end
	
		/*
	     * Calculate Cinema Rent
	     */
	
		if (@to_tran_type = 73 and @ltype = 3)
			select @cinema_rent = 0 - @new_cinema_total
		else
			select @cinema_rent = 0
	        
	    /*
	     * Check if liablity should be cancelled or not
	     */        
	     
	    select @spot_cancelled = count(dcs.spot_id)
	      from delete_charge_cinelight_spots dcs,
	           delete_charge dc
	     where dcs.delete_charge_id = dc.delete_charge_id
	       and dc.confirmed = 'Y'
	       and dcs.source_dest = 'S'
	       and dcs.spot_id = @spot_id
	     
		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'cinelight_spot_liability',5,@liability_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
		 * Insert Liability Record
		 */
		
		insert into cinelight_spot_liability (
				 spot_liability_id,
				 spot_id,
				 complex_id,
				 liability_type,
	             allocation_id,
				 spot_amount,
				 cinema_amount,
	             cancelled,
	             creation_period,
	             origin_period,
	             cinema_rent,
	             original_liability ) values (
				 @liability_id,
				 @spot_id,
				 @complex_id,
				 @ltype,
	             @allocation_id,
				 @new_spot_total,
				 @new_cinema_total,
	             @spot_cancelled,
	             @accounting_period,
	             @origin_period,
	             @cinema_rent,
	             0 )
	
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	    
	    if @dandc = 'Y'
	    begin
	        
	        select @destination_campaign = null
	            
	        select @destination_campaign = dc.destination_campaign
	          from delete_charge dc,
	               delete_charge_cinelight_spots dcs
	         where dcs.spot_id = @spot_id
	           and dcs.delete_charge_id = dc.delete_charge_id 
	           and dcs.source_dest = 'S'
	           and dc.confirmed = 'Y'
	      
	        if @destination_campaign is not null
	        begin
	        
	            select @record_exists = count(destination_campaign)
	              from work_spot_allocation
	             where destination_campaign = @destination_campaign
	               and source_campaign = @source_campaign
	               and allocation_id = @allocation_id
	               and liability_type = @ltype
	               
	            if @record_exists = 0
	            begin
	            
	                insert into work_spot_allocation
	                    (session_id,
	                    source_campaign,
	                    destination_campaign,
	                    allocation_amount,
	                    liability_type,
	                    allocation_id,
						alloc_primary) values
	                    (@session_id,
	                    @source_campaign, 
	                    @destination_campaign,
	                    @new_spot_total,
	                    @ltype,
	                    @allocation_id,
						@allocation_id)
	                    
	            end
	            else if @record_exists > 0
	            begin
	            
	                update work_spot_allocation
	                   set allocation_amount = allocation_amount + @new_spot_total
	                 where destination_campaign = @destination_campaign
	                   and source_campaign = @source_campaign
	                   and allocation_id = @allocation_id
	                   and liability_type = @ltype
	                   and session_id = @session_id
	                   
	            end
	
	        end         
	    end
	
		/*
	     * Decrease Allocated Work Amounts
	     */
	
		select @spot_work = @spot_work - @new_spot_total
		select @cinema_work = @cinema_work - @new_cinema_total
		
		/*
	     * Fetch Next Spot
	     */
	
	    fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	end
	close spot_csr
	select @spot_csr_open = 0
	deallocate spot_csr
end

if @inclusion_spot_count > 0 
begin
	
	select @spot_row = 0
	
	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.spot_type,
	         spot.spot_weighting,
	         spot.cinema_weighting,
	         (select distinct complex_id from inclusion_spot_liability where spot_id = spot.spot_id and liability_type = 14),
	         spot.dandc,
	         spot.campaign_no
	    from inclusion_spot spot,
	         inclusion_spot_xref fsx
	   where fsx.tran_id = @tran_id and
	         fsx.spot_id = spot.spot_id and
	         spot.spot_weighting > 0
	order by spot.spot_id
	     for read only
	
	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	while(@@fetch_status=0)
	begin

		select @spot_row = @spot_row + 1
	
	   	/*
	     * Get Totals Remaining
	     */
		
		select @spot_rem = sum(spot_amount),
	           @cinema_rem = sum(cinema_amount),
	           @origin_period = min(origin_period)
	      from inclusion_spot_liability
	     where spot_id = @spot_id
	
		/*
	     * Determine Amount to Allocate
	     */
	
		select @spot_calc = round(@spot_weight * @alloc_amount,2)
		select @cinema_calc = round(@cinema_weight * @alloc_amount,2)
	
		if(@spot_row = @inclusion_spot_count)	
		begin
			select @new_spot_total = @spot_work
			select @new_cinema_total = @cinema_work
		end
		else
		begin
			select @new_spot_total = @spot_calc
			select @new_cinema_total = @cinema_calc
		end
	
		/*
	     * Calculate Cinema Rent
	     */
	
		if (@to_tran_type = 88 and @ltype = 3)
			select @cinema_rent = 0 - @new_cinema_total
		else
			select @cinema_rent = 0
	        
	    /*
	     * Check if liablity should be cancelled or not
	     */        
	     
	    select @spot_cancelled = 0
	     
		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'inclusion_spot_liability',5,@liability_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
		 * Insert Liability Record
		 */
		
		insert into inclusion_spot_liability (
				 spot_liability_id,
				 spot_id,
				 complex_id,
				 liability_type,
	             allocation_id,
				 spot_amount,
				 cinema_amount,
	             cancelled,
	             creation_period,
	             origin_period,
	             cinema_rent,
	             original_liability ) values (
				 @liability_id,
				 @spot_id,
				 @complex_id,
				 @ltype,
	             @allocation_id,
				 @new_spot_total,
				 @new_cinema_total,
	             @spot_cancelled,
	             @accounting_period,
	             @origin_period,
	             @cinema_rent,
	             0 )
	
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	    
		/*
	     * Decrease Allocated Work Amounts
	     */
	
		select @spot_work = @spot_work - @new_spot_total
		select @cinema_work = @cinema_work - @new_cinema_total
		
		/*
	     * Fetch Next Spot
	     */
	
	    fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	end
	close spot_csr
	select @spot_csr_open = 0
	deallocate spot_csr
end

if @outpost_spot_count > 0 
begin
	
	select @spot_row = 0
	
	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.spot_type,
	         spot.spot_weighting,
	         spot.cinema_weighting,
	         (select distinct outpost_venue_id from outpost_spot_liability where spot_id = spot.spot_id and liability_type = 150),
	         spot.dandc,
	         spot.campaign_no
	    from outpost_spot spot,
	         outpost_spot_xref fsx
	   where fsx.tran_id = @tran_id and
	         fsx.spot_id = spot.spot_id and
	         spot.spot_weighting > 0
	order by spot.spot_id
	     for read only
	
	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	while(@@fetch_status=0)
	begin

		/*
   		 * If No Billing transaction complex has been found in cursor default to wherever the outpost is now.
		 */

		if @complex_id is null
		begin
			select 	@complex_id = cl.outpost_venue_id
			from	outpost_spot spot,
					outpost_panel cl
			where	cl.outpost_panel_id = spot.outpost_panel_id
			and 	spot.spot_id = @spot_id
		end
	
		select @spot_row = @spot_row + 1
	
	   	/*
	     * Get Totals Remaining
	     */
		
		select @spot_rem = sum(spot_amount),
	           @cinema_rem = sum(cinema_amount),
	           @origin_period = min(origin_period)
	      from outpost_spot_liability
	     where spot_id = @spot_id
	
		/*
	     * Determine Amount to Allocate
	     */
	
		select @spot_calc = round(@spot_weight * @alloc_amount,2)
		select @cinema_calc = round(@cinema_weight * @alloc_amount,2)
	
		if(@spot_row = @outpost_spot_count)	
		begin
			select @new_spot_total = @spot_work
			select @new_cinema_total = @cinema_work
		end
		else
		begin
			select @new_spot_total = @spot_calc
			select @new_cinema_total = @cinema_calc
		end
	
		/*
	     * Calculate Cinema Rent
	     */
	
		if (@to_tran_type = 73 and @ltype = 3)
			select @cinema_rent = 0 - @new_cinema_total
		else
			select @cinema_rent = 0
	        
	    /*
	     * Check if liablity should be cancelled or not
	     */        
	     
	    select @spot_cancelled = 0
	     
		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'outpost_spot_liability',5,@liability_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end
	
		/*
		 * Insert Liability Record
		 */
		
		insert into outpost_spot_liability (
				 spot_liability_id,
				 spot_id,
				 outpost_venue_id,
				 liability_type,
	             allocation_id,
				 spot_amount,
				 cinema_amount,
	             cancelled,
	             creation_period,
	             origin_period,
	             cinema_rent,
	             original_liability ) values (
				 @liability_id,
				 @spot_id,
				 @complex_id,
				 @ltype,
	             @allocation_id,
				 @new_spot_total,
				 @new_cinema_total,
	             @spot_cancelled,
	             @accounting_period,
	             @origin_period,
	             @cinema_rent,
	             0 )
	
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	    
/*	    if @dandc = 'Y'
	    begin
	        
	        select @destination_campaign = null
	            
	        select @destination_campaign = dc.destination_campaign
	          from delete_charge dc,
	               delete_charge_outpost_spots dcs
	         where dcs.spot_id = @spot_id
	           and dcs.delete_charge_id = dc.delete_charge_id 
	           and dcs.source_dest = 'S'
	           and dc.confirmed = 'Y'
	      
	        if @destination_campaign is not null
	        begin
	        
	            select @record_exists = count(destination_campaign)
	              from work_spot_allocation
	             where destination_campaign = @destination_campaign
	               and source_campaign = @source_campaign
	               and allocation_id = @allocation_id
	               and liability_type = @ltype
	               
	            if @record_exists = 0
	            begin
	            
	                insert into work_spot_allocation
	                    (session_id,
	                    source_campaign,
	                    destination_campaign,
	                    allocation_amount,
	                    liability_type,
	                    allocation_id,
						alloc_primary) values
	                    (@session_id,
	                    @source_campaign, 
	                    @destination_campaign,
	                    @new_spot_total,
	                    @ltype,
	                    @allocation_id,
						@allocation_id)
	                    
	            end
	            else if @record_exists > 0
	            begin
	            
	                update work_spot_allocation
	                   set allocation_amount = allocation_amount + @new_spot_total
	                 where destination_campaign = @destination_campaign
	                   and source_campaign = @source_campaign
	                   and allocation_id = @allocation_id
	                   and liability_type = @ltype
	                   and session_id = @session_id
	                   
	            end
	
	        end         
	    end
*/	
		/*
	     * Decrease Allocated Work Amounts
	     */
	
		select @spot_work = @spot_work - @new_spot_total
		select @cinema_work = @cinema_work - @new_cinema_total
		
		/*
	     * Fetch Next Spot
	     */
	
	    fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id, @dandc, @source_campaign
	end
	close spot_csr
	select @spot_csr_open = 0
	deallocate spot_csr
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

	 if (@spot_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
	 end
    raiserror ('Error: Failed to Create Spot Allocations for Allocation ID %1!',11,1, @allocation_id)
	return -1
GO
