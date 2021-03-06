/****** Object:  StoredProcedure [dbo].[p_spot_weight_generation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_weight_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_weight_generation]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_spot_weight_generation] @session           int,
                                     @bill_total        numeric(18,4) OUTPUT
                                            
as
set nocount on 
/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @billing_date                       datetime,
        @liability_id						int,
        @check_count						int,
        @pack_id							int,
        @metro_count						int,
        @region_count						int,
        @country_count						int,
        @loop_metro							int,
        @loop_region						int,
        @loop_country						int,
        @spot_id							int,		
        @complex_id							int,
        @loop_count							int,
        @exists								int,
        @spot_count							int,
        @loop_package						int,
        @fwb_id								int,
        @campaign_csr_open					tinyint,
        @spot_csr_open						tinyint,
        @package_csr_open					tinyint,
        @spot_pack_csr_open					tinyint,
        @pack_weight						float,
        @cinema_weight						float,
        @spot_weight						float,
        @rent_distribution_weighting	    float,
        @metro_cin_weight					float,		
        @regional_cin_weight				float,	
        @country_cin_weight				    float,
        @metro_weight						float,		
        @regional_weight					float,	
        @country_weight						float,
        @liability_amount					numeric(18,4),
        @pack_amount						numeric(18,4),
        @rate								numeric(18,4),
        @metro_remaining					numeric(18,4),
        @region_remaining					numeric(18,4),
        @country_remaining					numeric(18,4),
        @metro_alloc						numeric(18,4),
        @region_alloc						numeric(18,4),
        @country_alloc						numeric(18,4),
        @alloc_amount						numeric(18,4),
        @alloc_nett							numeric(18,4),
        @billing_total						numeric(18,4),
        @billing_remaining					numeric(18,4),
        @tran_desc     						varchar(255),
        @period_desc    					varchar(255),
        @spot_type							varchar(50),
        @status								char(1),
        @campaign_country					char(1),
        @country_code						char(1),
        @month_name							char(3),
        @region_class						char(1),
        @tran_code							char(1),
        @metro_weight_tot					numeric(18,4),
        @region_weight_tot					numeric(18,4),
        @country_weight_tot			    	numeric(18,4),
        @metro_vm_weight_tot				numeric(18,4),
        @region_vm_weight_tot				numeric(18,4),
        @country_vm_weight_tot		    	numeric(18,4),
        @weighting							numeric(6,4),			
        @acomm								numeric(6,4),
        @accc_weight_tot					numeric(18,4),
        @finyear							datetime,
        @campaign_no                        int,
        @tran_id                            int,
        @loop_remaining                     numeric(18,4)
      
   declare campaign_csr cursor static for
    select distinct campaign_no,
           tran_id 
      from work_spot_list
     where session_id = @session
  order by campaign_no,
           tran_id
       for read only
      
/*
 * Loop Campaigns and Transactions
 */

open campaign_csr
select @campaign_csr_open = 1
fetch campaign_csr into @campaign_no, @tran_id
while(@@fetch_status=0)
begin

    /*
     * Get Country Information about the Campaign
     */
     
    select @country_code = b.country_code
      from film_campaign fc,
           branch b
     where fc.campaign_no = @campaign_no and
           fc.branch_code = b.branch_code 
     
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

    /*
     * Delete Work Pack Totals
     */
     
    delete work_pack_totals
     where session_id = @session

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

    /*
     * Inialise Pack Table
     */
    
    insert into work_pack_totals
    select distinct @session,
           package_id,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0
      from work_spot_list
     where campaign_no = @campaign_no and
           tran_id = @tran_id and
           session_id = @session

    if(@@error !=0)
	    goto error

    /*
     * Initialise Total Variables
     */

    select @bill_total = 0,
           @spot_count = 0,
	       @metro_weight_tot = 0,
           @region_weight_tot = 0,
           @country_weight_tot = 0,
           @metro_vm_weight_tot = 0,
           @region_vm_weight_tot = 0,
           @country_vm_weight_tot = 0,
           @metro_count = 0,
           @region_count = 0,
           @country_count = 0,
           @campaign_csr_open = 0,
           @spot_csr_open = 0,
           @package_csr_open = 0,
           @spot_pack_csr_open = 0

    /*
     * Pass 1 - Loop Spots
     */
     
	   declare spot_csr cursor static for
	    select spot_id,
	           spot_status,
	           charge_rate,
	           weighting,
	           complex_id,
	           package_id,
	           screening_date,
	           country_code,
	           complex_region_class,
	           rent_dist_weighting    
	      from work_spot_list
	     where campaign_no = @campaign_no and
	           tran_id = @tran_id and
	           session_id = @session
	  order by country_code,
	           package_id,
	           spot_id
	       for read only
       
	open spot_csr
	select @spot_csr_open = 1
	fetch spot_csr into @spot_id, @status, @rate, @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting
	while(@@fetch_status = 0)
	begin

        /*
         * Increment Rate and Weighting totals
         */
       
		if(@status != 'D' and @rate != 0)
		begin

          	select @spot_count = @spot_count + 1
         	select @bill_total = @bill_total + @rate
    	 
 	         /*
              * Update Pack Totals
              */

			if @region_class = 'M'
				 update Work_pack_totals
					set pack_weight = pack_weight + @weighting,
						pack_amount = pack_amount + @rate,
						metro_weight = metro_weight + @rent_distribution_weighting,
						metro_cin_weight = metro_cin_weight + @weighting,
						metro_count = metro_count + 1
				  where pack_id = @pack_id and
                        session_id = @session
	
			if @region_class = 'R'
				 update work_pack_totals
					set pack_weight = pack_weight + @weighting,
						pack_amount = pack_amount + @rate,
						regional_weight = regional_weight + @rent_distribution_weighting,
						regional_cin_weight = regional_cin_weight + @weighting,
						regional_count = regional_count + 1
				  where pack_id = @pack_id and
                        session_id = @session
		
			if @region_class = 'C'
				 update work_pack_totals
					set pack_weight = pack_weight + @weighting,
						pack_amount = pack_amount + @rate,
						country_weight = country_weight + @rent_distribution_weighting,
						country_cin_weight = country_cin_weight + @weighting,
						country_count = country_count + 1
				  where pack_id = @pack_id and
                        session_id = @session

		end

        /*
         * Fetch Next Spot
         */

    	fetch spot_csr into @spot_id, @status, @rate, @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting

	end
	close spot_csr
	deallocate spot_csr
	select @spot_csr_open = 0
    
    /*
     * Initialise Bill Remaining
     */
     
    select @loop_remaining = @bill_total,
           @loop_count = @spot_count
    
	declare	package_csr cursor static for
	select	pack_id 
	from	work_pack_totals
	where	session_id = @session
	order by pack_id
	for read only

   /*
     * Loop Packages
     */
	open package_csr
    select @spot_pack_csr_open = 1
	fetch package_csr into @loop_package
	while(@@fetch_status=0)
	begin

		/*
		 * Initialise ACCC weightings and toals
		 */

		select @pack_amount = pack_amount,
               @pack_weight = pack_weight,
			   @metro_weight = metro_weight,
			   @regional_weight = regional_weight,
			   @country_weight = country_weight,
			   @metro_cin_weight = metro_cin_weight,
			   @regional_cin_weight =	regional_cin_weight,
			   @country_cin_weight = country_cin_weight,
			   @metro_count = metro_count,
			   @region_count = regional_count,								 
			   @country_count = country_count
		  from work_pack_totals
		 where pack_id = @loop_package and
               session_id = @session

		select @accc_weight_tot = @metro_weight + @regional_weight + @country_weight

		if(@pack_amount = 0)
			select @metro_alloc = 0, 
				   @region_alloc = 0,
				   @country_alloc = 0
		else
		begin
			select @metro_alloc = ((@metro_weight / @accc_weight_tot) * @pack_amount),
				   @region_alloc = ((@regional_weight / @accc_weight_tot) * @pack_amount)

			select @country_alloc = @pack_amount - @metro_alloc - @region_alloc
		end

		select @metro_remaining = @metro_alloc,          	
			   @region_remaining = @region_alloc,          
			   @country_remaining = @country_alloc
        
		   declare spot_package_csr cursor static for
		    select spot_id,
		           spot_status,
		           charge_rate,
		           weighting,
		           complex_id,
		           package_id,
		           screening_date,
		           country_code,
		           complex_region_class,
		           rent_dist_weighting    
		      from work_spot_list
		     where campaign_no = @campaign_no and
		           tran_id = @tran_id and
		           package_id = @loop_package and
		           session_id = @session
		  order by country_code,
		           spot_id
		       for read only
 
		/*
		 * Update all Spots
		 */
		open spot_package_csr
		select @spot_pack_csr_open = 1
        fetch spot_package_csr into @spot_id, @status, @rate, @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting
		while(@@fetch_status = 0)
		begin
				
			select @liability_amount = 0

			/*
			 * Calculate Spot Liability
			 */

			if(@status != 'D' and @rate != 0)
			begin
			
				/*
				 * Calculate Allocation Amount
				 */

				if(@region_class = 'M')
				begin
					select @spot_weight = @weighting / @metro_cin_weight

					if @loop_count = 1 
					begin
						select @liability_amount = @loop_remaining
					end
					else
					begin
						if(@metro_count = 1)
							select @liability_amount = @metro_remaining
						else
							select @liability_amount = round(@metro_alloc * @spot_weight,2)
					end

					select @metro_remaining = @metro_remaining - @liability_amount,
						   @metro_count = @metro_count - 1 
			
				end

				if(@region_class = 'R')
				begin

					select @spot_weight = @weighting / @regional_cin_weight

					if @loop_count = 1 
					begin
						select @liability_amount = @loop_remaining
					end
					else
					begin
						if(@region_count = 1)
							select @liability_amount = @region_remaining
						else
							select @liability_amount = round(@region_alloc * @spot_weight,2)
					end
	
					select @region_remaining = @region_remaining - @liability_amount,
						   @region_count = @region_count - 1 
					
				end

				if(@region_class = 'C')
				begin

					select @spot_weight = @weighting / @country_cin_weight

					if @loop_count = 1 
					begin
						select @liability_amount = @loop_remaining
					end
					else
					begin
						if(@country_count = 1)
							select @liability_amount = @country_remaining
						else
							select @liability_amount = round(@country_alloc * @spot_weight,2)
					end

					select @country_remaining = @country_remaining - @liability_amount,
						   @country_count = @country_count - 1 
			
				end

                /*
                 * If New Zealand -> Override the Regional Weighting
                 */
                
                if(@country_code <> 'A')
                begin
                
                    select @liability_amount = 0
                    
                    select @spot_weight = @weighting / @pack_weight

					if(@loop_count = 1)
						select @liability_amount = @loop_remaining
					else
						select @liability_amount = round(@pack_amount * @spot_weight,2)
            
                end
                    
	    		select @loop_count = @loop_count - 1,
	                   @loop_remaining = @loop_remaining - @liability_amount
    
    	    end

			/*
			 * Reduce Loop Count
			 */

			/**************************************
			 * Calculate Spot & Cinema Weightings *
			 **************************************/
		
			if(@status != 'D' and @rate != 0)
				select @spot_weight = convert(numeric(16,8),@rate) / convert(numeric(16,8),@bill_total)
			else
				select @spot_weight = 0

			if(@status != 'D' and @liability_amount != 0)
				select @cinema_weight = convert(numeric(16,8),@liability_amount) / convert(numeric(16,8),@bill_total)
			else
				select @cinema_weight = 0

			/*
			 * Update Spot
			 */

			update work_spot_list
			   set liability_amount = @liability_amount,
                   spot_weighting = @spot_weight,
				   cinema_weighting = @cinema_weight
			 where spot_id = @spot_id  and
                   session_id = @session

			select @error = @@error
			if (@error !=0)
			begin
                raiserror ('Error: Updating Work Spot List - Liability Values', 16, 1)
				goto error
			end	

			/*
			 * Fetch Next Spot
			 */

			fetch spot_package_csr into @spot_id, @status, @rate, @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting

		end
		close spot_package_csr
		deallocate spot_package_csr
		select @spot_pack_csr_open = 0

        /*
         * Fetch Next
         */

		fetch package_csr into @loop_package

    end
	close package_csr
	deallocate package_csr
    select @spot_pack_csr_open = 0
    
    if(@loop_remaining <> 0 or @loop_count <> 0)
    begin
        raiserror ('Error: Residual Amount Detetected after Spot Calculations.', 16, 1)
        goto error
    end

    /*
     * Fetch Next
     */
     
    fetch campaign_csr into @campaign_no, @tran_id

end
close campaign_csr    
deallocate campaign_csr    
select @campaign_csr_open = 0   


/*
 * Remove Rows from Work Table
 */

delete work_pack_totals
 where session_id = @session

/*
 * Return Sucess
 */
      
return 0

/* 
 * Error Handler
 */
 
error:

    if @campaign_csr_open = 1
    begin
        deallocate  campaign_csr
    end
    if @spot_csr_open = 1
    begin
        deallocate  spot_csr
    end
    if @package_csr_open = 1
    begin
        deallocate  package_csr
    end
    if @spot_pack_csr_open = 1
    begin
        deallocate  spot_package_csr
    end

    raiserror ('Error: Failed to Generate Spot Weightings.', 16, 1)
    return -100
GO
