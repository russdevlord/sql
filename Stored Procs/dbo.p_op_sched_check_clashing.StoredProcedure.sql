/****** Object:  StoredProcedure [dbo].[p_op_sched_check_clashing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_sched_check_clashing]
GO
/****** Object:  StoredProcedure [dbo].[p_op_sched_check_clashing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROC [dbo].[p_op_sched_check_clashing]	@campaign_no				int,
																							@outpost_panel_id		int,
																							@package_id					int
as
set nocount on 
declare	@error									int,
				@spot_csr_open					tinyint,
				@screening_date					datetime,
				@pcat										int,
				@spot_count							int,
				@clashing_count					smallint,
				@campaign_clash_count	    smallint,
				@clash									smallint,
				@row_type							varchar(10),
				@package_code		    		varchar(4),
				@client_clash_count			smallint,
				@product_clash_count        smallint,
				@client_clash						char(1),
				@product_clash					char(1),
				@package_clash					char(1),
				@client_id								int,
				@product_category_id		int,
				@media_product_id				int,
				@outpost_venue_id				int,
				@spot										int,
				@startdate							datetime,
				@enddate								datetime,
				@inc										int,
				@count_segs							int,
				@count_day							int,
				@fully_booked						char(1),
				@clash_limit							int

/*
 * Create a table for returning the screening dates and outpost_panel ids
 */

create table #clash
(
	screening_date		datetime,
	outpost_panel_id			int,
    package_id			int,
	row_type			varchar(10),
    spot_count			int,
    fully_booked		char(1)
)

/*
 * Initialise Variables
 */
select @spot_csr_open = 0

/*
* Get outpost_venue id for outpost_panel
*/

select 	@outpost_venue_id = outpost_venue_id
from	outpost_panel
where	outpost_panel_id = @outpost_panel_id

/*
 * Get Package Code to Count Packages less than this one
 */

select		@package_code = package_code,
				@product_category_id = product_category,
				@media_product_id = media_product_id
  from		outpost_package
 where		package_id = @package_id
 
/*
 * Select Package Clash as well to obtain the correct amount of clashing campaigns.
 */
 
select		@package_clash = allow_pack_clashing,
				@client_id = client_id
  from		film_campaign 
 where		campaign_no = @campaign_no

/*
 * Loop through Spots
 */

 declare		spot_csr cursor static for
  select		count(spot.spot_id),
					spot.outpost_panel_id,
					spot.screening_date,
					pack.product_category,
					'Screening',
					pack.client_clash,
					pack.allow_product_clashing, 
					spot.spot_id  --GB
    from		outpost_spot spot,
					outpost_package pack,
					outpost_panel cl
   where		spot.campaign_no = @campaign_no and
		 spot.package_id = @package_id and
         spot.package_id = pack.package_id and
		 spot.outpost_panel_id = @outpost_panel_id and
		 spot.outpost_panel_id = cl.outpost_panel_id and 
         cl.outpost_venue_id = @outpost_venue_id
group by spot.outpost_panel_id,
         spot.screening_date,
         pack.product_category,
         pack.client_clash,
         pack.allow_product_clashing, 
         spot.spot_id
union all
  select count(spot.spot_id),
         spot.outpost_panel_id,
         spot.billing_date,
         pack.product_category,
		 'Billing',
         pack.client_clash,
         pack.allow_product_clashing, 
         spot.spot_id --GB
    from outpost_spot spot,
         outpost_package pack,
		 outpost_panel cl
   where spot.campaign_no = @campaign_no and
		 spot.package_id = @package_id and
         spot.package_id = pack.package_id and
		 spot.outpost_panel_id = @outpost_panel_id and
         spot.outpost_panel_id = cl.outpost_panel_id and 
         cl.outpost_venue_id = @outpost_venue_id 
group by spot.outpost_panel_id,
         spot.billing_date,
         pack.product_category,
         pack.client_clash,
         pack.allow_product_clashing, 
         spot.spot_id
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_count, 
					@outpost_panel_id, 
					@screening_date, 
					@pcat,
					@row_type,
                    @client_clash,
                    @product_clash,
                    @spot  --GB

while(@@fetch_status = 0)
begin

    /*
     * Initialise Variables
     */
     
     select @client_clash_count = 0,
            @product_clash_count = 0,
            @campaign_clash_count = 0,
			@clash = 1

  
declare spot_sds_csr cursor static for
select start_date, end_date 
from outpost_spot_daily_segment
where spot_id = @spot
     for read only

open spot_sds_csr
fetch spot_sds_csr into @startdate, @enddate

while(@@fetch_status = 0)
begin

	select @clash_limit = 1
  
	/*
	 * Get Count of Booked Spots with the Same Product Category
	 */

	  select @clashing_count = IsNull(count(pack.package_id),0)
		from outpost_spot spot,	
		outpost_spot_daily_segment ds,
			 outpost_package pack,
             outpost_panel cl,
             film_campaign fc
  	   where spot.screening_date = @screening_date and
			 spot.spot_status <> 'P' and
			 spot.campaign_no <> @campaign_no and
			 spot.package_id = pack.package_id and
			 pack.product_category = @pcat and
             fc.campaign_no = spot.campaign_no and
             fc.campaign_no = pack.campaign_no and
             cl.outpost_panel_id = @outpost_panel_id and
             cl.outpost_panel_id = spot.outpost_panel_id
	and ds.spot_id = spot.spot_id and
(
(ds.start_date >= @startdate and   ds.end_date <= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @startdate )  or
(ds.start_date <= @enddate and   ds.end_date >= @enddate )  
)  
    /*
     * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
     */      
     
     if @client_clash = 'Y' and @product_clash = 'N'
     begin
        select @client_clash_count = IsNull(count(pack.package_id),0)
		  from outpost_spot spot,outpost_spot_daily_segment ds,
			   outpost_package pack,
               outpost_panel cl,
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
               cl.outpost_panel_id = @outpost_panel_id and
               cl.outpost_panel_id = spot.outpost_panel_id
		and ds.spot_id = spot.spot_id and
(
(ds.start_date >= @startdate and   ds.end_date <= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @startdate )  or
(ds.start_date <= @enddate and   ds.end_date >= @enddate )  
)  
     end
     
     if @product_clash = 'Y'
     begin
        select @product_clash_count  = IsNull(count(pack.package_id),0)
		  from outpost_spot spot,  outpost_spot_daily_segment ds,
			   outpost_package pack,
               outpost_panel cl,
               film_campaign fc
  	     where spot.screening_date = @screening_date and
			   spot.spot_status <> 'P' and
			   spot.campaign_no <> @campaign_no and
			   spot.package_id = pack.package_id and
			   pack.product_category = @pcat and
               fc.campaign_no = spot.campaign_no and
               fc.campaign_no = pack.campaign_no and
               pack.allow_product_clashing = 'Y' and
               cl.outpost_panel_id = @outpost_panel_id and
               cl.outpost_panel_id = spot.outpost_panel_id
		and ds.spot_id = spot.spot_id and
(
(ds.start_date >= @startdate and   ds.end_date <= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @startdate )  or
(ds.start_date <= @enddate and   ds.end_date >= @enddate )  
)  
     end
             
	/*
	 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
	 * With a Package Code less than the package being checked.
	 */
     
     if @package_clash = 'N'
     begin
	 select @campaign_clash_count = isnull(count(pack.package_id),0)
	   from outpost_spot spot, outpost_spot_daily_segment ds,
		    outpost_package pack,
            outpost_panel cl
	  where spot.screening_date = @screening_date and
			spot.campaign_no = @campaign_no and
			spot.package_id = pack.package_id and
			pack.package_code < @package_code and				
			pack.product_category = @pcat and
            cl.outpost_panel_id = @outpost_panel_id and
            cl.outpost_panel_id = spot.outpost_panel_id
	  and ds.spot_id = spot.spot_id and
(
(ds.start_date >= @startdate and   ds.end_date <= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @enddate )  or
(ds.start_date <= @startdate and   ds.end_date >= @startdate )  or
(ds.start_date <= @enddate and   ds.end_date >= @enddate )  
)  
     end   	


--GB
set @fully_booked = 'Y'
/*	    select @count_day = count(*) from outpost_spot_daily_segment where spot_id=@spot and  convert(char(8),start_date, 108) = '08:00:00' and convert(char(8),end_date, 108) = '22:59:59'
	if @count_day <> 7 
	  set @fully_booked = 'N'   
	else
	  set @fully_booked = 'Y'*/
--GB

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
			insert into #clash values (@screening_date, @outpost_panel_id, @package_id, @row_type, 1,  @fully_booked)

	 end


fetch spot_sds_csr into @startdate, @enddate
end
close spot_sds_csr
deallocate spot_sds_csr


	/*
     * Fetch Next Spot
     */

	fetch spot_csr into @spot_count, 
					    @outpost_panel_id, 
					    @screening_date, 
					    @pcat,
					    @row_type,
                        @client_clash,
                        @product_clash
		,@spot  --GB
end

close spot_csr
deallocate spot_csr
select @spot_csr_open = 0

/*
 * Return Clash List
 */

  select distinct screening_date,
         outpost_panel_id,
         package_id,
		 row_type,
         spot_count
 	,  fully_booked  --GB
    from #clash
order by screening_date asc,
		 outpost_panel_id asc,
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
