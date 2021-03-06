/****** Object:  StoredProcedure [dbo].[p_sched_check_cl_clashing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sched_check_cl_clashing]
GO
/****** Object:  StoredProcedure [dbo].[p_sched_check_cl_clashing]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sched_check_cl_clashing] @campaign_no     int,
                                   @cinelight_id      int,
                                   @package_id      int
as
set nocount on 
declare @error						int,
        @spot_csr_open			    tinyint,
        @screening_date			    datetime,
        @pcat						int,
		@spot_count				    int,
	    @clashing_count		        smallint,
		@campaign_clash_count	    smallint,
        @clash                      smallint,
		@row_type					char(10),
		@package_code		    	char(4),
        @client_clash_count         smallint,
        @product_clash_count        smallint,
        @client_clash               char(1),
        @product_clash              char(1),
        @package_clash              char(1),
        @client_id                  int,
		@product_category_id		int,
		@media_product_id			int,
        @complex_id                 int

/*
 * Create a table for returning the screening dates and cinelight ids
 */

create table #clash
(
	screening_date		datetime,
	cinelight_id			int,
    package_id			int,
	row_type			char(10),
    spot_count			int
)

/*
 * Initialise Variables
 */
select @spot_csr_open = 0

/*
* Get complex id for cinelight
*/

select 	@complex_id = complex_id
from	cinelight
where	cinelight_id = @cinelight_id

/*
 * Get Package Code to Count Packages less than this one
 */

select @package_code = package_code,
	   @product_category_id = product_category,
	   @media_product_id = media_product_id
  from cinelight_package
 where package_id = @package_id
 
/*
 * Select Package Clash as well to obtain the correct amount of clashing campaigns.
 */
 
select @package_clash = allow_pack_clashing,
       @client_id = client_id
  from film_campaign 
 where campaign_no = @campaign_no

/*
 * Loop through Spots
 */

 declare spot_csr cursor static for
  select count(spot.spot_id),
         spot.cinelight_id,
         spot.screening_date,
         pack.product_category,
		 'Screening',
         pack.client_clash,
         pack.allow_product_clashing
    from cinelight_spot spot,
         cinelight_package pack,
		 cinelight cl
   where spot.campaign_no = @campaign_no and
		 spot.package_id = @package_id and
         spot.package_id = pack.package_id and
		 spot.cinelight_id = @cinelight_id and
		 spot.cinelight_id = cl.cinelight_id and 
         cl.complex_id = @complex_id
group by spot.cinelight_id,
         spot.screening_date,
         pack.product_category,
         pack.client_clash,
         pack.allow_product_clashing
union all
  select count(spot.spot_id),
         spot.cinelight_id,
         spot.billing_date,
         pack.product_category,
		 'Billing',
         pack.client_clash,
         pack.allow_product_clashing
    from cinelight_spot spot,
         cinelight_package pack,
		 cinelight cl
   where spot.campaign_no = @campaign_no and
		 spot.package_id = @package_id and
         spot.package_id = pack.package_id and
		 spot.cinelight_id = @cinelight_id and
         spot.cinelight_id = cl.cinelight_id and 
         cl.complex_id = @complex_id 
group by spot.cinelight_id,
         spot.billing_date,
         pack.product_category,
         pack.client_clash,
         pack.allow_product_clashing
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_count, 
					@cinelight_id, 
					@screening_date, 
					@pcat,
					@row_type,
                    @client_clash,
                    @product_clash

while(@@fetch_status = 0)
begin

    /*
     * Initialise Variables
     */
     
     select @client_clash_count = 0,
            @product_clash_count = 0,
            @campaign_clash_count = 0

    
	/*
	 * Get Count of Booked Spots with the Same Product Category
	 */

	  select @clashing_count = IsNull(count(pack.package_id),0)
		from cinelight_spot spot,
			 cinelight_package pack,
             cinelight cl,
             film_campaign fc
  	   where spot.screening_date = @screening_date and
			 spot.spot_status <> 'P' and
			 spot.campaign_no <> @campaign_no and
			 spot.package_id = pack.package_id and
			 pack.product_category = @pcat and
             fc.campaign_no = spot.campaign_no and
             fc.campaign_no = pack.campaign_no and
             cl.complex_id = @complex_id and
             cl.cinelight_id = spot.cinelight_id
             -- DYI 2013-04-17
			AND ( ISNULL( pack.allow_product_clashing, 'N')= 'N' OR ISNULL(pack.allow_subcategory_clashing, 'N') ='N' OR  ISNULL(FC.allow_pack_clashing, 'N') = 'N')

    /*
     * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
     */      
     
     if @client_clash = 'Y' and @product_clash = 'N'
     begin
        select @client_clash_count = IsNull(count(pack.package_id),0)
		  from cinelight_spot spot,
			   cinelight_package pack,
               cinelight cl,
               film_campaign fc
  	     where spot.screening_date = @screening_date and
			   spot.spot_status <> 'P' and
			   spot.campaign_no <> @campaign_no and
			   spot.package_id = pack.package_id and
			   pack.product_category = @pcat and
               fc.campaign_no = spot.campaign_no and
               fc.campaign_no = pack.campaign_no and
               fc.client_id = @client_id and
               pack.client_clash = 'Y' and
               pack.allow_product_clashing = 'N' and
               cl.complex_id = @complex_id and
               cl.cinelight_id = spot.cinelight_id
     end
     
     if @product_clash = 'Y'
     begin
        select @product_clash_count  = IsNull(count(pack.package_id),0)
		  from cinelight_spot spot,
			   cinelight_package pack,
               cinelight cl,
               film_campaign fc
  	     where spot.screening_date = @screening_date and
			   spot.spot_status <> 'P' and
			   spot.campaign_no <> @campaign_no and
			   spot.package_id = pack.package_id and
			   pack.product_category = @pcat and
               fc.campaign_no = spot.campaign_no and
               fc.campaign_no = pack.campaign_no and
               pack.allow_product_clashing = 'Y' and
               cl.complex_id = @complex_id and
               cl.cinelight_id = spot.cinelight_id
     end
             
	/*
	 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
	 * With a Package Code less than the package being checked.
	 */
     
     if @package_clash = 'N'
     begin
	 select @campaign_clash_count = isnull(count(pack.package_id),0)
	   from cinelight_spot spot,
		    cinelight_package pack,
            cinelight cl
	  where spot.screening_date = @screening_date and
			spot.campaign_no = @campaign_no and
			spot.package_id = pack.package_id and
			pack.package_code < @package_code and				
			pack.product_category = @pcat and
            cl.complex_id = @complex_id and
            cl.cinelight_id = spot.cinelight_id
     end   	
    
 	 select @clash = (@clashing_count + @campaign_clash_count) + (@client_clash_count + @product_clash_count)

	print 					@spot_count
					print 	@cinelight_id
					print 	@screening_date
					print 	@pcat
					print 	@row_type
                    print 	@client_clash
                    print 	@product_clash	
	print 	@clashing_count
	print	@product_clash_count
	print	@client_clash_count
	print	@campaign_clash_count

	/*
	 * Check if this spot is Affected
	 */

	 if(@clash > 0)
	 begin

		if(@row_type = 'Screening')
			select @clash = @clash * -1
		else
			select @clash = 0



		insert into #clash values (@screening_date, @cinelight_id, @package_id, @row_type, 1)

	 end

	/*
     * Fetch Next Spot
     */

	fetch spot_csr into @spot_count, 
					    @cinelight_id, 
					    @screening_date, 
					    @pcat,
					    @row_type,
                        @client_clash,
                        @product_clash

end

close spot_csr
deallocate spot_csr
select @spot_csr_open = 0

/*
 * Return Clash List
 */

  select distinct screening_date,
         cinelight_id,
         package_id,
		 row_type,
         spot_count
    from #clash
order by screening_date asc,
		 cinelight_id asc,
         package_id asc

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
