/****** Object:  StoredProcedure [dbo].[p_eom_spot_allocate_dclibility]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_spot_allocate_dclibility]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_spot_allocate_dclibility]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_eom_spot_allocate_dclibility]      @session_id                int

as

declare @error                          int,
        @errorode                          int,
        @source_campaign                int,
        @destination_campaign           int,
        @allocation_amount              numeric(18,4),
        @liability_type                 int,
        @allocation_id                  int,
        @count                          int,
        @next_destination               int,
        @rowcount     				    int,
        @spot_id					    int,
        @spot_count				    	int,
        @cinelight_spot_count			int,
        @tran_id				    	int,
        @to_tran_type			    	int,
        @from_tran_type			    	int,
        @spot_weight			    	float,
        @cinema_weight			    	float,
        @complex_id				    	int,
        @spot_row			    		int,
        @spot_calc			    		numeric(20,4),
        @cinema_calc		    		numeric(20,4),
        @new_spot_total		    		numeric(20,4),
        @new_cinema_total	    		numeric(20,4),
        @cinema_rent		    		numeric(20,4),
        @liability_id		    		int,
        @ltype				    		smallint,
        @sqlstat				    	int,
        @spot_rem				    	numeric(20,4),
        @spot_work				    	numeric(20,4),
        @cinema_rem				    	numeric(20,4),
        @cinema_work			    	numeric(20,4),
        @spot_type                      char(1),
        @spot_redirect                  int,
        @sr_spot_id                     int,
        @sr_complex_id			    	int,
        @origin_period                  datetime,
        @creation_period                datetime


 declare work_csr cursor static for
  select source_campaign,
         destination_campaign,
         allocation_amount,
         liability_type,
         allocation_id
    from work_spot_allocation
   where session_id = @session_id
order by source_campaign
     for read only
     
/*
 * 1st Cursor run - find all subsequent links and add those campaigns to the work table
 */
 
open work_csr
fetch work_csr into @source_campaign, @destination_campaign, @allocation_amount, @liability_type, @allocation_id 
while(@@fetch_status=0)
begin

    exec @errorode = p_eom_spot_allocate_dclwork @session_id, @source_campaign, @destination_campaign, @allocation_amount, @liability_type, @allocation_id
    
    if @errorode != 0
    begin
        raiserror ('Error determining D & C relationships for spot liabiliity allocatio = ficven.', 16, 1)
        return -100
    end

    fetch work_csr into @source_campaign, @destination_campaign, @allocation_amount, @liability_type, @allocation_id 
end    

close work_csr
deallocate work_csr
 
/*
 * 2nd Cursor run - process all rows 
 */

    
begin transaction
     
 declare work_csr cursor static for
  select source_campaign,
         destination_campaign,
         allocation_amount,
         liability_type,
         allocation_id
    from work_spot_allocation
   where session_id = @session_id
order by source_campaign
     for read only
     
open work_csr
fetch work_csr into @source_campaign, @destination_campaign, @allocation_amount, @liability_type, @allocation_id 
while(@@fetch_status=0)
begin


    /*
     * If not allocating to spots then commit transaction and return success
     */
     

    if(@allocation_amount != 0)
    begin

        /*
         * Count number of spots in the Cursor
         */

		select 	@spot_count = IsNull(count(spot.spot_id),0)
		from 	campaign_spot spot,
				delete_charge_spots dcs,
				delete_charge  dc
		where 	spot.spot_weighting > 0
		and 	spot.spot_id = dcs.spot_id
		and 	dcs.source_dest = 'D'
		and 	dcs.campaign_no = @destination_campaign
		and 	dc.destination_campaign = @destination_campaign
		and 	dc.source_campaign = @source_campaign
		and 	dc.delete_charge_id = dcs.delete_charge_id
		and 	dc.confirmed = 'Y'

		select 	@cinelight_spot_count = IsNull(count(spot.spot_id),0)
		from 	cinelight_spot spot,
				delete_charge_cinelight_spots dcs,
				delete_charge  dc
		where 	spot.spot_weighting > 0
		and 	spot.spot_id = dcs.spot_id
		and 	dcs.source_dest = 'D'
		and 	dcs.campaign_no = @destination_campaign
		and 	dc.destination_campaign = @destination_campaign
		and 	dc.source_campaign = @source_campaign
		and 	dc.delete_charge_id = dcs.delete_charge_id
		and 	dc.confirmed = 'Y'

        select @spot_work = @allocation_amount
        select @cinema_work = @allocation_amount

		if @spot_count > 0 and @cinelight_spot_count = 0
		begin
	        /*
	         * Loop Through Spots
	         */
	
			 declare spot_csr cursor static for
			  select spot.spot_id,
			         spot.spot_redirect,
			         spot.spot_type,
			         spot.spot_weighting,
			         spot.cinema_weighting,
			         spot.complex_id
			    from campaign_spot spot,
			         delete_charge_spots dcs,
			         delete_charge  dc
			   where spot.spot_weighting > 0
			     and spot.spot_id = dcs.spot_id
			     and dcs.source_dest = 'D'
			     and dcs.campaign_no = @destination_campaign
			     and dc.destination_campaign = @destination_campaign
			     and dc.source_campaign = @source_campaign
			     and dc.delete_charge_id = dcs.delete_charge_id
			     and dc.confirmed = 'Y'
			order by spot.spot_id
			     for read only
	
	
	        open spot_csr
	        fetch spot_csr into @spot_id, @spot_redirect, @spot_type, @spot_weight, @cinema_weight, @complex_id
	        while(@@fetch_status = 0)
	        begin
	
	            /*
	             * Calculate Spot Re-Direct
	             */
	
	            select @sr_spot_id = @spot_id,
	                   @sr_complex_id = @complex_id
	
	   	        while(@spot_redirect <> null)
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
	                    deallocate spot_csr
	                    deallocate work_csr
	        	        return -100
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
	
		        select @spot_calc = round(@spot_weight * @allocation_amount,2)
		        select @cinema_calc = round(@cinema_weight * @allocation_amount,2)
	
	-- 	        print 'Calculated Spot Allocation: %1!' , @spot_calc
	-- 	        print 'Calculated Cinema Allocation: %1!' , @cinema_calc
	
		        if(@spot_row = @spot_count)	
		        begin
			        select @new_spot_total = @spot_work
			        select @new_cinema_total = @cinema_work
		        end
		        else
		        begin
			
			        /*
	                 * Calculate New Spot Allocation
	                 */
	
			        if(@spot_calc > @spot_rem)
				        select @new_spot_total = @spot_rem
			        else
				        select @new_spot_total = @spot_calc
	
			        /*
	                 * Calculate New Cinema Allocation
	                 */
	
			        if(@cinema_calc > @cinema_rem)
				        select @new_cinema_total = @cinema_rem
			        else
				        select @new_cinema_total = @cinema_calc
	
		     end
	
	-- 	        print 'New Spot: %1!' , @new_spot_total
	-- 	        print 'New Cinema: %1!' , @new_cinema_total
	
		        /*
		         * Get Liability Id
		         */
		
		        execute @errorode = p_get_sequence_number 'spot_liability',5,@liability_id OUTPUT
		        if (@errorode !=0)
		        begin
	                raiserror ('Error: Failed to get new spot liability id', 16, 1)
			        rollback transaction
	                deallocate spot_csr
	                deallocate work_csr
	        	    return -100
		        end
	
	
	            if @liability_type = 3
	                select @cinema_rent = @new_cinema_total
	            else
	                select @cinema_rent = 0
	
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
	                     origin_period,
	                     cinema_rent,
	                     original_liability ) values (
				         @liability_id,
				         @sr_spot_id,
				         @sr_complex_id,
				         @liability_type,
	                     @allocation_id,
				         @new_spot_total,
				         @new_cinema_total,
	                     0,
	                     @origin_period,
	                     0.0,
	                     1 )
	
		
		        select @error = @@error
		        if (@error !=0)
		        begin
	                raiserror ('Error: Failed to insert new spot liability record.', 16, 1)
			        rollback transaction
	                deallocate spot_csr
	                deallocate work_csr
	        	    return -100
		        end	
	    
		        /*
	            * Decrease Allocated Work Amounts
	            */
	
		        select @spot_work = @spot_work - @new_spot_total
		        select @cinema_work = @cinema_work - @new_cinema_total
		
		        /*
	            * Fetch Next Spot
	            */
	
	            fetch spot_csr into @spot_id, @spot_redirect, @spot_type, @spot_weight, @cinema_weight, @complex_id
	        end
	    
	        close spot_csr
			deallocate spot_csr
		end
		else if @spot_count = 0 and @cinelight_spot_count > 0
		begin
	        /*
	         * Loop Through Spots
	         */
	
			 declare spot_csr cursor static for
			  select spot.spot_id,
			         spot.spot_type,
			         spot.spot_weighting,
			         spot.cinema_weighting,
			         (select max(complex_id) from cinelight_spot_liability where spot_id = spot.spot_id )
			    from cinelight_spot spot,
			         delete_charge_cinelight_spots dcs,
			         delete_charge  dc
			   where spot.spot_weighting > 0
			     and spot.spot_id = dcs.spot_id
			     and dcs.source_dest = 'D'
			     and dcs.campaign_no = @destination_campaign
			     and dc.destination_campaign = @destination_campaign
			     and dc.source_campaign = @source_campaign
			     and dc.delete_charge_id = dcs.delete_charge_id
			     and dc.confirmed = 'Y'
			order by spot.spot_id
			     for read only
	
	
	        open spot_csr
	        fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id
	        while(@@fetch_status = 0)
	        begin
	
				/*
		   		 * If No Billnig transaction complex has been found in cursor default to wherever the cinelight is now.
				 */
		
				if @complex_id is null
				begin
					select 	@complex_id = cl.complex_id
					from	cinelight_spot spot,
							cinelight cl
					where	cl.cinelight_id = spot.cinelight_id
					and 	spot.spot_id = @spot_id
				end

	
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
	
		        select @spot_calc = round(@spot_weight * @allocation_amount,2)
		        select @cinema_calc = round(@cinema_weight * @allocation_amount,2)
	
		        if(@spot_row = @spot_count)	
		        begin
			        select @new_spot_total = @spot_work
			        select @new_cinema_total = @cinema_work
		        end
		        else
		        begin
			
			        /*
	                 * Calculate New Spot Allocation
	                 */
	
			        if(@spot_calc > @spot_rem)
				        select @new_spot_total = @spot_rem
			        else
				        select @new_spot_total = @spot_calc
	
			        /*
	                 * Calculate New Cinema Allocation
	                 */
	
			        if(@cinema_calc > @cinema_rem)
				        select @new_cinema_total = @cinema_rem
			        else
				        select @new_cinema_total = @cinema_calc
	
		        end
	
		        /*
		         * Get Liability Id
		         */
		
		        execute @errorode = p_get_sequence_number 'cinelight_spot_liability',5,@liability_id OUTPUT
		        if (@errorode !=0)
		        begin
	                raiserror ('Error: Failed to get new spot liability id', 16, 1)
			        rollback transaction
	                deallocate spot_csr
	                deallocate work_csr
	        	    return -100
		        end
	
	
	            if @liability_type = 3
	                select @cinema_rent = @new_cinema_total
	            else
	                select @cinema_rent = 0
	
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
	                     origin_period,
	                     cinema_rent,
	                     original_liability ) values (
				         @liability_id,
				         @spot_id,
				         @complex_id,
				         @liability_type,
	                     @allocation_id,
				         @new_spot_total,
				         @new_cinema_total,
	                     0,
	                     @origin_period,
	                     0.0,
	                     1 )
	
		
		        select @error = @@error
		        if (@error !=0)
		        begin
	                raiserror ('Error: Failed to insert new spot liability record.', 16, 1)
			        rollback transaction
	                deallocate spot_csr
	                deallocate work_csr
	        	    return -100
		        end	
	    
		        /*
	            * Decrease Allocated Work Amounts
	            */
	
		        select @spot_work = @spot_work - @new_spot_total
		        select @cinema_work = @cinema_work - @new_cinema_total
		
		        /*
	            * Fetch Next Spot
	            */
	
	            fetch spot_csr into @spot_id, @spot_type, @spot_weight, @cinema_weight, @complex_id
	        end
	    
	        close spot_csr
			deallocate spot_csr
		end
		else
		begin
	        raiserror ('Error determining Media & Cinelight relationships for spot liabiliity allocation.', 16, 1)
	        return -100
		end
    end
        
    /*
     * Fetch Next Work Cursor
     */

    fetch work_csr into @source_campaign, @destination_campaign, @allocation_amount, @liability_type, @allocation_id 
end    

close work_csr
deallocate work_csr

/*
 * Delete all rows from work table and return
 */
 
delete work_spot_allocation
 where session_id = @session_id

select @error = @@error
if @error != 0
begin
    raiserror ('Error determining D & C relationships for spot liabiliity allocation.', 16, 1)
    rollback transaction
    return -100
end

commit transaction
return 0
GO
