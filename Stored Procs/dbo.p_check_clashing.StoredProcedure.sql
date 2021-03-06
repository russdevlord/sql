/****** Object:  StoredProcedure [dbo].[p_check_clashing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_clashing]
GO
/****** Object:  StoredProcedure [dbo].[p_check_clashing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_clashing] @campaign_no     int
as

declare @error						int,
        @spot_csr_open			    tinyint,
        @screening_date			    datetime,
        @pcat						int,
		@spot_count				    int,
	    @clashing_count		        smallint,
		@campaign_clash_count	    smallint,
	    @clash_limit				smallint,
		@row_type					char(10),
		@package_code		    	char(4),
        @client_clash_count         smallint,
        @product_clash_count        smallint,
        @client_clash               char(1),
        @product_clash              char(1),
        @package_clash              char(1),
        @client_id                  int,
        @complex_id                 int,
        @package_id                 int,
		@product_category_id		int,
		@media_product_id			int

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #clash
(
	screening_date		datetime,
	complex_id			int,
    package_id			int,
	row_type			char(10),
    spot_count			int
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0


/*
 * Select Package Clash as well to obtain the correct amount of clashing campaigns.
 */
 
select @package_clash = allow_pack_clashing,
       @client_id = client_id
  from film_campaign 
 where campaign_no = @campaign_no

/*
 * Declare Cursors
 */ 

 declare spot_csr cursor static for
  select count(spot.spot_id),
         spot.complex_id,
         spot.screening_date,
         pack.product_category,
		 'Screening',
         pack.client_clash,
         pack.allow_product_clashing,
         pack.package_id
    from campaign_spot spot,
         campaign_package pack
   where spot.campaign_no = @campaign_no and
         spot.package_id = pack.package_id
group by spot.complex_id,
         spot.screening_date,
         pack.product_category,
         pack.client_clash,
         pack.allow_product_clashing,
         pack.package_id
union all
  select count(spot.spot_id),
         spot.complex_id,
         spot.billing_date,
         pack.product_category,
		 'Billing',
         pack.client_clash,
         pack.allow_product_clashing,
         pack.package_id
    from campaign_spot spot,
         campaign_package pack
   where spot.campaign_no = @campaign_no and
         spot.package_id = pack.package_id 
group by spot.complex_id,
         spot.billing_date,
         pack.product_category,
         pack.client_clash,
         pack.allow_product_clashing,
         pack.package_id
     for read only


/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into @spot_count, 
					@complex_id, 
					@screening_date, 
					@pcat,
					@row_type,
                    @client_clash,
                    @product_clash,
                    @package_id

while(@@fetch_status=0)
begin

    /*
     * Initialise Variables
     */
     
     select @client_clash_count = 0,
            @product_clash_count = 0,
            @campaign_clash_count = 0
            
    select @package_code = package_code,
		   @product_category_id = product_category,
		   @media_product_id = media_product_id
      from campaign_package
     where package_id = @package_id
            

	/*
	 * Get Clash Limit for Complex and Screening Date
	 */

	  select @clash_limit = round((case when @media_product_id = 1 then (cd.clash_safety_limit * pd.film_ad_percent) else (cd.clash_safety_limit * pd.dmg_ad_percent) end) + (case when cd.clash_safety_limit = 1 then 0.5 else -0.5 end),0)
        from complex_date cd,
			 product_date pd
       where cd.complex_id = @complex_id and
             cd.screening_date = @screening_date and
			 cd.screening_date = pd.screening_date and
			 pd.product_category_id = @product_category_id

    
	/*
	 * Get Count of Booked Spots with the Same Product Category
	 */

	  select @clashing_count = IsNull(count(pack.package_id),0)
		from campaign_spot spot,
			 campaign_package pack,
             film_campaign fc
  	   where spot.complex_id = @complex_id and
			 spot.screening_date = @screening_date and
			 spot.spot_status <> 'P' and
			 spot.campaign_no <> @campaign_no and
			 spot.package_id = pack.package_id and
			 pack.product_category = @pcat and
             fc.campaign_no = spot.campaign_no and
             fc.campaign_no = pack.campaign_no 

    /*
     * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
     */      
     
     if @client_clash = 'Y' and @product_clash = 'N'
     begin
        select @client_clash_count = IsNull(count(pack.package_id),0)
		  from campaign_spot spot,
			   campaign_package pack,
               film_campaign fc
  	     where spot.complex_id = @complex_id and
			   spot.screening_date = @screening_date and
			   spot.spot_status <> 'P' and
			   spot.campaign_no <> @campaign_no and
			   spot.package_id = pack.package_id and
			   pack.product_category = @pcat and
               fc.campaign_no = spot.campaign_no and
               fc.campaign_no = pack.campaign_no and
               fc.client_id = @client_id and
               pack.client_clash = 'Y' and
               pack.allow_product_clashing = 'N'
     end
     
     if @product_clash = 'Y'
     begin
        select @product_clash_count  = IsNull(count(pack.package_id),0)
		  from campaign_spot spot,
			   campaign_package pack,
               film_campaign fc
  	     where spot.complex_id = @complex_id and
			   spot.screening_date = @screening_date and
			   spot.spot_status <> 'P' and
			   spot.campaign_no <> @campaign_no and
			   spot.package_id = pack.package_id and
			   pack.product_category = @pcat and
               fc.campaign_no = spot.campaign_no and
               fc.campaign_no = pack.campaign_no and
               pack.allow_product_clashing = 'Y'
     end
             
	/*
	 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
	 * With a Package Code less than the package being checked.
	 */
     
     if @package_clash = 'N'
     begin
	 select @campaign_clash_count = isnull(count(pack.package_id),0)
	   from campaign_spot spot,
		    campaign_package pack
	  where spot.complex_id = @complex_id and
			spot.screening_date = @screening_date and
			spot.campaign_no = @campaign_no and
			spot.package_id = pack.package_id and
			pack.package_code < @package_code and				
			pack.product_category = @pcat
     end   	
    
 	 select @clash_limit = @clash_limit - (@clashing_count + @campaign_clash_count) + (@client_clash_count + @product_clash_count)

	 if(@clash_limit < 0)
		select @clash_limit = 0

	 select @clash_limit = @clash_limit - @spot_count

	/*
	 * Check if this spot is Affected
	 */

	 if(@clash_limit < 0)
	 begin

		if(@row_type = 'Screening')
			select @clash_limit = @clash_limit * -1
		else
			select @clash_limit = 0

		insert into #clash values (@screening_date, @complex_id, @package_id, @row_type, @clash_limit)

	 end

	/*
     * Fetch Next Spot
     */

	fetch spot_csr into @spot_count, 
					    @complex_id, 
					    @screening_date, 
					    @pcat,
					    @row_type,
                        @client_clash,
                        @product_clash,
                        @package_id

end

close spot_csr
deallocate spot_csr

/*
 * Return Clash List
 */

  select screening_date,
         complex_id
    from #clash
group by screening_date,
		 complex_id
order by screening_date asc,
		 complex_id asc

/*
 * Return Success
 */

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
	return -1
GO
