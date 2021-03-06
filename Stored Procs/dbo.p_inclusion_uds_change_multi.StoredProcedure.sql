/****** Object:  StoredProcedure [dbo].[p_inclusion_uds_change_multi]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_uds_change_multi]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_uds_change_multi]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create PROC [dbo].[p_inclusion_uds_change_multi]  	@campaign_no 		int,
													@complex_id 		int,
													@min_date   		datetime,
													@max_date   		datetime,
													@range_type	    	char(1),
													@spot_status		char(1),
													@spot_type			char(1),
													@inclusion_id 		int,
			  										@no_screens   		int,
			 										@new_rate			money,
													@new_date			datetime,
													@new_pack			int,
													@action				varchar(max),
													@dandc              char(1),
													@message			int OUTPUT

as

declare @error							int,
        @date							datetime,
		@screening_date				    datetime,
        @billing_date				    datetime,
        @spot_id						int,
        @last_date				    	datetime, 
        @updated						int,
        @csr_package					int,
        @last_pack				    	int,
        @csr_open						tinyint,
        @csr_type						char(1),
        @csr_status					    char(1),
        @screened						char(1),
        @billed				    		char(1),
        @billing_period			    	datetime,
        @assoc_billing_period		    datetime,
        @curr_screening_date		    datetime,
        @confirmed					    char(1),
        @new_status				    	char(1),
        @active_weeks				    int,
        @weeks_after			        int,
        @end_date						datetime,
        @screening_status			    char(1),
        @campaign_end_date			    datetime,
        @campaign_start_date		    datetime,
        @new_screen_date			    datetime,
        @new_billing_date			    datetime,
        @change_rate					char(1),
        @change_charge_rate             char(1),
        @move_screen					char(1),
        @move_bill					    char(1),
        @move_period					char(1),
		@move_revenue					char(1),
        @inclusion_status			    char(1),
		@complex_name				    varchar(50),
        @period_status					char(1),
        @dandc_source_dest              char(1),
        @campaign_type                  int,
        @media_product_id_new           smallint,
        @media_product_id_old           smallint,
        @current_charge_rate            money,
        @current_rate                   money,
		@charge_rate					money,
		@allow							char(1),
		@max_screening_date				datetime,
		@screening_end_date				datetime,
		@inclusion_format				char(1),
		@certs_generated				int

/*
 * Initialise Nulls
 */

if @spot_type is null
	select @spot_type = '*'

if @spot_status is null
	select @spot_status = '*'

if @inclusion_id is null
	select @inclusion_id = -1

if @no_screens is null
	select @no_screens = 100000000 /*An absolutely huge number that you would never have this many screenings in a week */

/*
 * Initialise Variables
 */

select @message = 0

select 	@inclusion_status = inclusion_status,
		@inclusion_format = inclusion_format
from 	inclusion
where 	inclusion_id = @inclusion_id

if substring(@action,1,7) = 'm_weeks'
begin
	select			@move_revenue = substring(@action, 11, 1),
					@move_period = substring(@action,10,1),
					@move_bill = substring(@action,9,1),
					@move_screen = substring(@action,8,1),
					@action = substring(@action,1,7)
end

if substring(@action,1,6) = 'c_rate'
begin
	select @change_rate = substring(@action,7,1),
           @change_charge_rate = substring(@action,8,1),
           @action = substring(@action,1,6)
end

if @action = 'a_screen' or @action = 'm_weeks' or @action = 'c_bill'
begin

   select @campaign_end_date = used_by_date,
          @campaign_start_date = start_Date
     from inclusion
    where inclusion_id = @inclusion_id

end



if @action = 'c_bill'
begin
	/*
     * Check new billing period is not closed
	 */

	select @period_status = status
	  from accounting_period
	 where end_date = @new_date
	
	if @period_status <> 'O'
	begin
		raiserror ('New Billing Period is already closed.', 16, 1)
		return -1
	end
end

/*
 * Special processing for Activate Screenings
 * Set Confirmed Flag from campaign. 'Y' if campaign confirmed, 'N' if it isnt.
 */

if @action = 'a_screen'
begin

	if(@inclusion_status = 'P')
		select @new_status = 'P'
	else
		select @new_status = 'A'

	/*
     * Get end date for the period to activate.
	 */

	select @active_weeks = datediff(wk,@min_date,@max_date)
	select @end_date = dateadd(wk,@active_weeks,@new_date)
	
	/* 
     * Check start date is an open screening date.
 	 */

	if @inclusion_format <> 'R'
	begin
		select 	@screening_status = screening_date_status
		from 	film_screening_dates
		where 	screening_date = @new_date
	end
	else
	begin
		select 	@screening_status = screening_date_status
		from 	outpost_screening_dates
		where 	screening_date = @new_date
	end

	if @screening_status = 'X'
	begin
		raiserror ('Start screening date has already screened. Error Activating screenings.', 16, 1)
		return -1
	end

	if @end_date > @campaign_end_date
	begin
		raiserror ('New end date is after Campaign End Date. Error Activating screenings.', 16, 1)
		return -1
	end
end

/*
 * Special Processing for Move weeks
 */

if @action = 'm_weeks'
begin

	/*
     * Get end date for the period to move.
	 */

	select @active_weeks = datediff(wk,@min_date,@max_date)
	select @end_date = dateadd(wk,@active_weeks,@new_date)
	
	if @range_type != 'S' -- cater to the campaigns that have screening dates greater than the billing_date
	begin
 		if @inclusion_format = 'R' 
		begin
			select	@max_screening_date = max(op_screening_date)
			from	inclusion_spot 
			where	campaign_no = @campaign_no and
					outpost_venue_id = @complex_id and
		 		    op_billing_date >= @min_date and
					op_billing_date <= @max_date and
					(@spot_status = '*' or spot_status = @spot_status) and
					(@spot_type = '*' or spot_type = @spot_type) and
					(inclusion_id = @inclusion_id)
		end
		else if @inclusion_format = 'I' 
		begin
			select	@max_screening_date = max(billing_period)
			from	inclusion_spot 
			where	campaign_no = @campaign_no and
					outpost_venue_id = @complex_id and
		 		    billing_period >= @min_date and
					billing_period <= @max_date and
					(@spot_status = '*' or spot_status = @spot_status) and
					(@spot_type = '*' or spot_type = @spot_type) and
					(inclusion_id = @inclusion_id)
		end
		else if @inclusion_format = 'T'
		begin
			select	@max_screening_date = max(screening_date)
			from	inclusion_spot 
			where	campaign_no = @campaign_no and
		 		    billing_date >= @min_date and
					billing_date <= @max_date and
					(@spot_status = '*' or spot_status = @spot_status) and
					(@spot_type = '*' or spot_type = @spot_type) and
					(inclusion_id = @inclusion_id)
		end
		else
		begin
			select	@max_screening_date = max(screening_date)
			from	inclusion_spot 
			where	campaign_no = @campaign_no and
					complex_id = @complex_id and
		 		    billing_date >= @min_date and
					billing_date <= @max_date and
					(@spot_status = '*' or spot_status = @spot_status) and
					(@spot_type = '*' or spot_type = @spot_type) and
					(inclusion_id = @inclusion_id)
		end


	
		select @screening_end_date = dateadd(wk,@active_weeks,@max_screening_date)
		if @screening_end_date > @end_date
			select  @end_date = @screening_end_date
	end


	/*
 	 * Check end date is within campaign period.
	 */

	if @end_date > @campaign_end_date
	begin
		raiserror ('New end date is after Campaign End Date.', 16, 1)
		return -1
	end

end

/*
 * Load Current Screening Date if Changing Complexes
 */

if @action = 'c_complex' 
begin

	if @inclusion_format = 'R'
	begin
		select 	@curr_screening_date = screening_date
		from 	outpost_screening_dates
		where 	screening_date_status = 'C'
	end
	else if @inclusion_format = 'I'
	begin
		select 	@curr_screening_date = min(end_date)
		from 	accounting_period
		where 	status = 'O'
	end
	begin
		select 	@curr_screening_date = screening_date
		from 	film_screening_dates
		where 	screening_date_status = 'C'
	end

	select @error = @@error
    if @error != 0
	begin
		raiserror ('Error: Failed to load Current Screening Date.', 16, 1)
		return -1
	end
end

if @action = 's_dandc' or @action = 'u_dandc'
begin
    select @campaign_type = campaign_type
      from film_campaign
     where campaign_no = @campaign_no
end

if @action = 'u_dandc' and @inclusion_status <> 'F' --expired campaigns only
begin
	raiserror ('Error: Can only Set Unallocated DandC Flag on Expired Campaigns.', 16, 1)
	return -1
end

/*
 * Initialise Variables
 */

select @updated = 0,
       @date = '1-Jan-1900', /*Set to dawn of time, so its different on 1st run through.*/
       @last_pack = -1

/*
 * Begin Transaction
 */

begin transaction


/*
 * Declare Spot cursor static for Range:
 *
 * 1. Screening Dates OR
 * 2. Billing Dates
 *
 */

if @range_type = 'S'
begin

	if @inclusion_format = 'I'
	begin
		declare 	spot_csr  cursor static for
		select 		spot_id,
						screening_date,
						billing_date,
						inclusion_id,
						spot_status,
						spot_type,
						billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			(complex_id = @complex_id or @complex_id = 0)
		and			screening_date >= @min_date 
		and			screening_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	screening_date, 
					spot_id
		for 		read only
	end
	else 	if @inclusion_format = 'R'
	begin
		declare 	spot_csr  cursor static for
		select 		spot_id,
					op_screening_date,
					op_billing_date,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			outpost_venue_id = @complex_id 
		and			op_screening_date >= @min_date 
		and			op_screening_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	op_screening_date, 
					spot_id
		for 		read only
	end
	else if @inclusion_format = 'T'
	begin
		declare 	spot_csr  cursor static for
		select 		spot_id,
					screening_date,
					billing_date,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			screening_date >= @min_date 
		and			screening_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	screening_date, 
					spot_id
		for 		read only
	end
	else
	begin
		declare 	spot_csr  cursor static for
		select 		spot_id,
					screening_date,
					billing_date,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			(complex_id = @complex_id or @complex_id = 0)
		and			screening_date >= @min_date 
		and			screening_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	screening_date, 
					spot_id
		for 		read only
	end

end
else
begin

	if @inclusion_format = 'I'
	begin
		declare 	spot_csr cursor static for
		select 		spot_id,
					billing_period,
					billing_period,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			outpost_venue_id = @complex_id 
		and			billing_period >= @min_date 
		and			billing_period <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	op_billing_date, 
					spot_id
		for 		read only
	end
	else 	if @inclusion_format = 'R'
	begin
		declare 	spot_csr cursor static for
		select 		spot_id,
					op_screening_date,
					op_billing_date,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			outpost_venue_id = @complex_id 
		and			op_billing_date >= @min_date 
		and			op_billing_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	op_billing_date, 
					spot_id
		for 		read only
	end
	else if @inclusion_format = 'T'
	begin
		declare 	spot_csr cursor static for
		select 		spot_id,
					screening_date,
					billing_date,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			billing_date >= @min_date 
		and			billing_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	billing_date, 
					spot_id
		for 		read only
	end
	else
	begin
		declare 	spot_csr cursor static for
		select 		spot_id,
					screening_date,
					billing_date,
					inclusion_id,
					spot_status,
					spot_type,
					billing_period
		from 		inclusion_spot
		where 		campaign_no = @campaign_no 
		and			(complex_id = @complex_id  or @complex_id <> 0)
		and			billing_date >= @min_date 
		and			billing_date <= @max_date 
		and			(@spot_status = '*' or spot_status = @spot_status) 
		and			(@spot_type = '*' or spot_type = @spot_type) 
		and			(inclusion_id = @inclusion_id)
		order by 	billing_date, 
					spot_id
		for 		read only
	end

end

/*
 * Open Cursor
 */
select @csr_open = 1
open spot_csr

/*
 * Fetch Row
 */

fetch spot_csr into @spot_id, @screening_date, @billing_date, @csr_package, @csr_status, @csr_type, @billing_period
while(@@fetch_status=0)
begin

    if @csr_type = 'M' or @csr_type = 'V'
    begin
        if @action = 'm_sched' or (@action = 'm_weeks' and @move_bill = 'Y')
        begin
    	    raiserror ('Error: Cannot move the billing date of a Makeup/Manual Makeup.', 16, 1)
	        return -1
        end
    end
    
   /*
    *    Get spot delete & charge flag
    */

    select @dandc_source_dest = ''    

    select @dandc_source_dest = source_dest
      from delete_charge_spots
     where spot_id = @spot_id

    select @dandc_source_dest = IsNull(@dandc_source_dest, '')

	/*
     * Setup Spot Range
     */

	if @range_type = 'S'
		select @date = @screening_date
	else
		select @date = @billing_date

	if (@date <> @last_date or @last_pack <> @csr_package)
	begin
		select @last_date = @date,
		       @last_pack = @csr_package,
		       @updated = 0
	end

	/*
     * Determine Spot Screening Status
     */

	if @inclusion_format = 'I'
	begin
		select 	@screened = status
		from 	accounting_period
		where 	end_date = @screening_date
	end
	else 	if @inclusion_format = 'R'
	begin
		select 	@screened = screening_date_status
		from 	outpost_screening_dates
		where 	screening_date = @screening_date
	end
	else
	begin
		select 	@screened = screening_date_status
		from 	film_screening_dates
		where 	screening_date = @screening_date
	end

	if @screened = 'X'
		select @screened = 'Y'
	else
	begin
		if(@csr_status = 'X' or @csr_status = 'U' or @csr_status = 'N') /*Allocated, Unallocated, No Show */
			select @screened = 'Y'
		else
		begin
		if @inclusion_format = 'T' and @screened = 'C'
		begin
			select	@certs_generated = count(*)
			from	complex_date 
			where	screening_date = @screening_date
			and		certificate_status = 'G'
			
			select @error = @@error
			if @error != 0
            begin
        		raiserror ('Error checking if anyone has generated this week.', 16, 1)
                rollback transaction
                close spot_csr
                deallocate spot_csr
                return -1
            end			
            
            if @certs_generated = 0
				select @screened = 'N'
			else
				select @screened = 'Y'
		end
		else
			select @screened = 'N'
		end
	end

	/*
     * Determine Spot Billing Status
     */

	select @billed = status
      from accounting_period
     where end_date = @billing_period

	if @billed <> 'O'
		select @billed = 'Y'
	else
		select @billed = 'N'

	/*
     * Only update another spot if we havent already updated enough spots for this date & pack combo
     */

	if @updated < @no_screens
	begin

	  /***************
       * Change Rate *
       ***************/

		if @action = 'c_rate'
		begin

		 /*
          * Not Billed - Bonus, Contra, Delete & Charge, No Charge
          */
            
            select @current_charge_rate = charge_rate,
                   @current_rate = rate 
              from inclusion_spot
             where spot_id = @spot_id
             
			select @error = @@error
			if @error != 0
            begin
        		raiserror ('Error obtaining old spot rates.', 16, 1)
                rollback transaction
                close spot_csr
                deallocate spot_csr
                return -1
            end
			

            if (@change_rate = 'Y' and @change_charge_rate = 'N' and @current_charge_rate > @new_rate) 
            begin
        		raiserror ('Error Charge Rate cannot be more than Rate.', 16, 1)
                rollback transaction
                deallocate spot_csr
                return -1
            end
                             
            if (@change_rate = 'N' and @change_charge_rate = 'Y' and @current_rate < @new_rate) 
            begin
        		raiserror ('Error Charge Rate cannot be more than Rate.', 16, 1)
                rollback transaction
                close spot_csr
                return -1
            end

			if (@billed = 'N') and @change_rate = 'Y' and ((@csr_type = 'B') or (@csr_type = 'N') or (@csr_type = 'D')) /* Bonus, No Charge, Make Good*/
			begin
				update inclusion_spot
				   set rate = @new_rate,
				  	   charge_rate = 0
				 where spot_id = @spot_id

				select @error = @@error
				if @error != 0
					goto error
            end

			/*
             * Not Billed - Scheduled Only
             */

			else if (@billed = 'N') and ((@csr_type = 'S') or (@csr_type = 'C') or (@csr_type = 'F') or (@csr_type = 'K') or (@csr_type = 'T') or (@csr_type = 'A'))
			begin
                if @change_rate = 'Y'
                begin
				    update inclusion_spot
				       set rate = @new_rate
				     where spot_id = @spot_id
		
				    select @error = @@error
				    if @error != 0
					    goto error
                end
                if @change_charge_rate = 'Y'
                begin
				    update inclusion_spot
				       set charge_rate = @new_rate
				     where spot_id = @spot_id
		
				    select @error = @@error
				    if @error != 0
					    goto error
                end
		   end

		end

	  /*************************
       * Change Billing Period *
       *************************/

		else if @action = 'c_bill' /*Change Billing Period  */
		begin

		 /*
          * Spots which are not Billed Only
          */

			if (@billed = 'N')
			begin
			
				if @inclusion_format <> 'R'
				begin
					select 	@assoc_billing_period = billing_period
					from 	film_screening_dates 
					where 	screening_date = @billing_date
				end
				else
				begin
					select 	@assoc_billing_period = billing_period
					from 	outpost_screening_dates 
					where 	screening_date = @billing_date
				end				

                 if @csr_type = 'D'
    				begin
                        /* MakeGood spot(s) are among selected spots. */
	       				raiserror ('Change Billing Period for MakeGood spot(s) manually and run the procedure again.', 16, 1)
                        rollback transaction
		      			return -1
			     	end				

				if @new_date <= @assoc_billing_period 
				begin

					update inclusion_spot
					   set billing_period = @new_date
					 where spot_id = @spot_id
			
					select @error = @@error
					if @error != 0
						goto error

				end
			end
		end

		
	  /*****************************************
       * Delete Screenings - Not Changing Rate *
       *****************************************/		

		else if @action = 'd_screen'
		begin

			/*
 			 * If Spot is:
			 * 
			 * 1. Active Spot, Not Billed and Not Screened
			 * 2. Cancelled Spot and Not Billed
			 * 3. Held Spot and Not Billed
			 * 4. Proposal
			 */

  			if (@csr_status = 'A' and @billed = 'N' /*and @screened = 'N'*/) OR 
               (@csr_status = 'C' and @billed = 'N') OR
               (@csr_status = 'H' and @billed = 'N') OR
			   (@csr_status = 'P')

			/*
			 * These spots are deleted after the cursor is closed.
			 */

 			begin

                IF (@csr_status = 'C' and @dandc_source_dest = 'S') or @csr_type = 'D'
                    select @message = @message + 1
                else            
                begin
        			update inclusion_spot          
        			   set spot_status = 'D'   
        			 where spot_id = @spot_id

    	   			select @error = @@error
           			if @error != 0
    	    			goto error
                end
			end
		end

	  /***********************
       * Activate Screenings *
       ***********************/		

		else if @action = 'a_screen' 
		begin

			/*
			 * Cancelled or Held Spots
			 */

			if (@csr_status = 'C') or (@csr_status = 'H')
			begin

				/*
 				 * Calculate New Screening Date	
				 */

				select @weeks_after = datediff(wk,@min_date,@billing_date)
				select @new_screen_date = dateadd(wk,@weeks_after,@new_date)
				
				/*
 				 * Update the Spot status and Screening Date
				 */					



                IF @csr_status = 'C' and @dandc_source_dest = 'S' 
                    select @message = @message + 1
                else            
                begin         
					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	spot_status = @new_status,
								screening_date = @new_screen_date,
								dandc = 'N'
						where 	spot_id = @spot_id
					end
					else
					begin
						update 	inclusion_spot
						set 	spot_status = @new_status,
								op_screening_date = @new_screen_date,
								dandc = 'N'
						where 	spot_id = @spot_id
					end               

                     /*synchronize screening dates, billing dates and bill.period for make good spots */
                    if @csr_type = 'D' and @billed = 'N'
                    begin
						if @inclusion_format <> 'R'
						begin
							update 		inclusion_spot
							set 		billing_date = @new_screen_date,
										billing_period = f.billing_period
							from 		film_screening_dates f
							where 		spot_id = @spot_id 
							and			f.screening_date = @new_screen_date
						end
						else
						begin
							update 		inclusion_spot
							set 		op_billing_date = @new_screen_date,
										billing_period = f.billing_period
							from 		outpost_screening_dates f
							where 		spot_id = @spot_id 
							and			f.screening_date = @new_screen_date
						end

                   		select @error = @@error
        		        if @error != 0
        				goto error

                    end
	
        			select @error = @@error
        			if @error != 0
        				goto error
                end
			end
			else if @spot_status = 'U' and @csr_status = 'U'
			begin

				if @inclusion_format <> 'R'
				begin
					select 	@screening_status = screening_date_status
					from 	film_screening_dates
					where 	screening_date = @screening_date
				end
				else
				begin
					select 	@screening_status = screening_date_status
					from 	outpost_screening_dates
					where 	screening_date = @screening_date
				end

				select @error = @@error
				if @error != 0
					goto error

				if(@screening_status <> 'X')
				begin

					update inclusion_spot
				       set spot_status = @new_status
					 where spot_id = @spot_id
			
					select @error = @@error
					if @error != 0
						goto error
				end
			end
		end

	  /*********************
       * Cancel Screenings *
       *********************/		

		else if @action = 'c_screen' 
		begin

			/*
			 * If Spot is:
			 *
			 * 1. Active Spot and Not Screened
			 * 2. Proposed Spot
			 * 3. Held Spot
			 */

			if (@csr_status = 'A' and @screened = 'N') OR
               (@csr_status = 'P') OR 
               (@csr_status = 'H') OR
               (@csr_status = 'C')
			begin

                select @dandc = IsNull(@dandc, 'N')    

                IF @csr_status = 'C' and @dandc_source_dest = 'S'
                    select @message = @message + 1
                else
                begin
					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	spot_status = 'C',
								screening_date = null,
								dandc = @dandc
						where 	spot_id = @spot_id
					end
					else
					begin
						update 	inclusion_spot
						set 	spot_status = 'C',
								op_screening_date = null,
								dandc = @dandc
						where 	spot_id = @spot_id
					end
        			select @error = @@error
	          		if @error != 0
	       	      		goto error
                end
			end
		end

  	  /*******************
       * Hold Screenings *
       *******************/		

		else if @action = 'h_screen' 
		begin

			/*
			 * If Spot is:
			 *
			 * 1. Active Spot and Not Screened
			 * 2. Proposed Spot
			 * 3. Cancelled Spot
			 */

			if (@csr_status = 'A' and @screened = 'N') or
               (@csr_status = 'P') or
               (@csr_status = 'C')
            begin

                IF @csr_status = 'C' and @dandc_source_dest = 'S' 
                    select @message = @message + 1
                else
                begin
					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	spot_status = 'H',
								screening_date = null
						where 	spot_id = @spot_id
					end
					else
					begin
						update 	inclusion_spot
						set 	spot_status = 'H',
								op_screening_date = null
						where 	spot_id = @spot_id
					end
	
	       	      	select @error = @@error
    	       		if @error != 0
	       	       		goto error
                end
			end
		end

	  /*************************************
       * Remove Bonus/Contra               *
       *************************************/		

		else if @action = 'r_alloc' 
		begin

			/* 
			 * If Spot has Not Billed OR is a Proposed Spot and
			 * Spot is a Bonus, Contra 
			 */

			if (@billed = 'N' OR @csr_status = 'P') and
               (@csr_type = 'B' or @csr_type = 'C' or @csr_type = 'W')
			begin
	       		update  inclusion_spot
				set     spot_type = 'S',
					    charge_rate = inclusion.inclusion_charge
                from    inclusion                        
		      	where   spot_id = @spot_id
                and     inclusion_spot.inclusion_id = inclusion.inclusion_id
		
				select @error = @@error
				if @error != 0
					goto error
			end
		end

	  /**********************************************************
       * Sets delete & charge status for cancelled spots  *
       ***********************************************************/		
        else if @action = 's_dandc'
        begin
            if (@dandc = 'Y' ) and ( @campaign_type = 3 or @spot_type = 'B' or @spot_type = 'N' or @spot_type = 'Y')
                select @message = @message + 1
            else if @csr_status = 'C' and @dandc_source_dest = 'S'
                select @message = @message + 1
            else
                update inclusion_spot
                set    dandc = @dandc
                where  spot_id = @spot_id and spot_status = 'C'
        end

	  /**************************************************************
       * Sets delete & charge status for unallocated/no show spots  *
       **************************************************************/		
        else if @action = 'u_dandc'
        begin
            if (@dandc = 'Y' ) and ( @campaign_type = 3 or @spot_type = 'B' or @spot_type = 'N' or @spot_type = 'Y')
                select @message = @message + 1
            else if @csr_status = 'C' and @dandc_source_dest = 'S'
                select @message = @message + 1
            else
                update inclusion_spot
                   set dandc = @dandc
                 where spot_id = @spot_id
                   and (spot_status = 'U'
					or spot_status = 'N')
                   and spot_redirect is null
        end

	  /*************************************************
       * Move Weeks, Screening Dates and Billing Dates *
       *************************************************/		

		else if @action = 'm_weeks' 
		begin


			/*
			 * If Spot Not Billed and Not Screened OR
			 * Spot is Proposed.
			 */

			if (@billed = 'N' and @screened = 'N') or @csr_status = 'P'
			begin
                

                /*
                 * Check Screening Dates Will Not Be Before Billing Dates after move
                 */

				select @weeks_after = datediff(wk,@min_date,@screening_date)
                if @move_screen = 'Y'
                    select @new_screen_date = dateadd(wk,@weeks_after,@new_date)
                else if @move_screen = 'N'
                    select @new_screen_date = @screening_date
                    
				select @weeks_after = datediff(wk,@min_date,@billing_date)
                if @move_bill = 'Y'
                    select @new_billing_date = dateadd(wk,@weeks_after,@new_date)
                else if @move_bill = 'N'
                    select @new_billing_date = @billing_date
                    
                if @new_billing_date > @new_screen_date 
				begin
					raiserror ('Billings cannot be after screenings - Move Weeks Failed.', 16, 1)
					return -1
				end				
                
				/*
				 * Move Screening Dates - Yes
				 */


				if @move_screen = 'Y' and @move_bill = 'N'
				begin
					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	screening_date = @new_screen_date
						where 	spot_id = @spot_id 
					end
					else
					begin
						update 	inclusion_spot
						set 	op_screening_date = @new_screen_date
						where 	spot_id = @spot_id 
					end

					select @error = @@error
					if @error != 0
						goto error

				end

				/*
				 * Move Billing Dates - Yes
                 * OR
                 * Screening Date of MakeGood spot has been changed and should be synchronize with bill.dates and bill.period
				 */
                 
				if @move_bill = 'Y' or (@move_screen = 'Y' and  @csr_type = 'D')
				begin

    				if @move_screen = 'Y' 
                        begin
    	       				select @weeks_after = datediff(wk,@min_date,@screening_date)
    		      			select @new_screen_date = dateadd(wk,@weeks_after,@new_date)

							if @inclusion_format <> 'R'
							begin
								update 	inclusion_spot
								set 	screening_date = @new_screen_date
								where 	spot_id = @spot_id 
							end
							else
							begin
								update 	inclusion_spot
								set 	op_screening_date = @new_screen_date
								where 	spot_id = @spot_id 
							end
                        end

					select @error = @@error
					if @error != 0
						goto error

					/*
					 * Move Billing Period - Yes
                     * OR
                     * Screening Date of MakeGood spot has been changed and should be synchronize with bill.dates and bill.period
					 */

					if @move_period = 'Y' or (@move_screen = 'Y' and  @csr_type = 'D')
					begin

						if @inclusion_format <> 'R'
						begin
							update 	inclusion_spot
							set 	billing_date = @new_billing_date,
									billing_period = f.billing_period
							from 	film_screening_dates f
							where 	spot_id = @spot_id 
							and		f.screening_date = @new_billing_date
						end
						else
						begin
							update 	inclusion_spot
							set 	op_billing_date = @new_billing_date,
									billing_period = f.billing_period
							from 	outpost_screening_dates f
							where 	spot_id = @spot_id 
							and		f.screening_date = @new_billing_date
						end

						select @error = @@error
						if @error != 0
							goto error

					end

					/*
					 * Not Moving Billing Period
					 */

					else if @move_period = 'N'
					begin

						if @inclusion_format <> 'R'
						begin
							update 	inclusion_spot
							set 	billing_date = @new_billing_date
							where 	spot_id = @spot_id
						end
						else
						begin
							update 	inclusion_spot
							set 	op_billing_date = @new_billing_date
							where 	spot_id = @spot_id
						end

						select @error = @@error
						if @error != 0
							goto error

					end

					/*
					 * Move Billing Period - Yes
                     * OR
                     * Screening Date of MakeGood spot has been changed and should be synchronize with bill.dates and bill.period
					 */

				end

         end

			if @move_revenue = 'Y' or (@move_screen = 'Y' and  @csr_type = 'D')
			begin

				if @inclusion_format <> 'R'
				begin
					update 	inclusion_spot
					set 	revenue_period = f.billing_period
					from 	film_screening_dates f
					where 	spot_id = @spot_id 
					and		f.screening_date = @new_screen_date
				end
				else
				begin
					update 	inclusion_spot
					set 	revenue_period = f.billing_period
					from 	outpost_screening_dates f
					where 	spot_id = @spot_id 
					and		f.screening_date = @new_screen_date
				end

				select @error = @@error
				if @error != 0
					goto error

			end


			/*
			 * If Spot has Billed and Not Screened 
			 */

			else if (@billed = 'Y') and (@screened = 'N')
			begin
				
				/*
				 * Move Screening Dates - Yes
				 */

				if @move_screen = 'Y'
				begin

					select @weeks_after = datediff(wk,@min_date,@screening_date)
					select @new_screen_date = dateadd(wk,@weeks_after,@new_date)

					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	screening_date = @new_screen_date
						where 	spot_id = @spot_id
					end
					else
					begin
						update 	inclusion_spot
						set 	op_screening_date = @new_screen_date
						where 	spot_id = @spot_id
					end

					select @error = @@error
					if @error != 0
						goto error
				end
				
				/*
				 * Move Billing Dates - Yes
				 * Cannot move a Spot that has Billed - Error.
				 */

				if @move_bill = 'Y'
				begin
					raiserror ('Billing has already occurred - Move Billing Dates Failed.', 16, 1)
					return -1
				end				

			end 

		end

		/******************************************
       * Move Schedule Forwards in time X weeks *
       ******************************************/		

		else if @action = 'm_sched' 
		begin

			/*
			 * If Spot has Not Billed or Screened OR
			 * If Spot is Proposed
			 */

			if (@billed = 'N' and @screened = 'N') or (@csr_status = 'P')
			begin
				
				/*
				 * New Pack is used as a general int value, 
				 * it contains number of weeks to move sched here.
				 */
				
				select @new_screen_date = dateadd(wk,@new_pack,@screening_date) 
				select @new_billing_date = dateadd(wk,@new_pack,@billing_date)

				if @inclusion_format <> 'R'
				begin
					update 	inclusion_spot
					set 	screening_date = @new_screen_date,
							billing_date = @new_billing_date,
							billing_period = f.billing_period,
							revenue_period = f.billing_period
					from 	film_screening_dates f
					where 	spot_id = @spot_id 
					and		f.screening_date = @new_billing_date
				end
				else
				begin
					update 	inclusion_spot
					set 	op_screening_date = @new_screen_date,
							op_billing_date = @new_billing_date,
							billing_period = f.billing_period,
							revenue_period = f.billing_period
					from 	outpost_screening_dates f
					where 	spot_id = @spot_id 
					and		f.screening_date = @new_billing_date
				end
	
				select @error = @@error
				if @error != 0
					goto error

			end

			/*
			 * If Spots have been billed or screened then return 
			 * the count to the calling function. 
			 */
 
            else if @billed = 'Y'
			begin
				select @message = @message + 1
			end	

		    else if @screened = 'Y' 
		    begin
			    select @message = @message + 1
		    end

		end

		/*******************
       * Change Complex. *
       *******************/		

		else if @action = 'c_complex' 
		begin

			if @csr_type = 'B'
			begin
				if @inclusion_format <> 'R'
				begin
					select 	@allow = bonus_allowed
					from	complex
					where	complex_id = @new_pack	
				end
				else
				begin
					select 	@allow = bonus_allowed
					from	outpost_venue
					where	outpost_venue_id = @new_pack	
				end

					if @@error != 0 or @allow = 'N'
					begin
						raiserror ('Error: This complex does not allow bonus spots.', 16, 1)
						goto error
					end
						
			end

			/*
			 * If Spot has Not Screened OR
			 * Spot is Proposed AND
			 * 
			 */

			if ((@screened = 'N') or (@csr_status = 'P'))
			begin

				if @inclusion_format <> 'R'
				begin
					select 	@complex_name = complex_name
					from 	complex
					where 	complex_id = @complex_id
				end
				else
				begin
					select 	@complex_name = outpost_venue_name
					from 	outpost_venue
					where 	outpost_venue_id = @complex_id
				end

				/*
				 * @new_pack is a generic int variable and in 
				 * this situtaion used for to set new complex_id
				 */

				if(@curr_screening_date = @screening_date)
				begin
				
					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	complex_id = @new_pack,
								spot_status = 'U'
						where 	spot_id = @spot_id
					end
					else
					begin
						update 	inclusion_spot
						set 	outpost_venue_id = @new_pack,
								spot_status = 'U'
						where 	spot_id = @spot_id
					end
		
					select @error = @@error
					if @error != 0
						goto error

				end
				else
				begin
		
					if @inclusion_format <> 'R'
					begin
						update 	inclusion_spot
						set 	complex_id = @new_pack
						where 	spot_id = @spot_id
					end
					else
					begin
						update 	inclusion_spot
						set 	outpost_venue_id = @new_pack
						where 	spot_id = @spot_id
					end
		
					select @error = @@error
					if @error != 0
						goto error

				end
			end
		end
	end
	
	/*
	 * Increment Updated Spots Count
	 */

	select @updated = @updated + 1

	/*
	 * Fetch Next
	 */

	fetch spot_csr into @spot_id, @screening_date, @billing_date, @csr_package, @csr_status, @csr_type, @billing_period

end

/*
 * Close spot_csr
 */

deallocate spot_csr

/*
 * Initialise @csr_open Variable to 0
 * ( Cursor not Open )
 */

select @csr_open = 0

/********************
* Delete Screenings *
*********************/		

if @action = 'd_screen'
begin

	delete inclusion_spot
     where campaign_no = @campaign_no and
           spot_status = 'D'

	select @error = @@error
	if @error != 0
		goto error
end

/*
 * Commit Transaction
 */

commit transaction

/*
 * Return
 */

return 0

/*
 * Error Code
 */

error:
	
	/*
     * If Cursor is open then Close spot_csr and 
	 * deallocate.
     */

	if @csr_open = 1
	begin
          close spot_csr
          deallocate  spot_csr
	end
	rollback transaction
    raiserror ('Unable to update/delete screenings', 16, 1)
	return -1
GO
