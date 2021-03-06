/****** Object:  StoredProcedure [dbo].[p_check_overbooked]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_overbooked]
GO
/****** Object:  StoredProcedure [dbo].[p_check_overbooked]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_overbooked] @campaign_no int

as

declare @error						int,
        @spot_csr_open				tinyint,
        @spot_id					int,
        @screening_date				datetime,
        @complex_id					int,
        @pcat						int,
        @last_complex_date   	 	int,
	    @max_ads					smallint,
	    @max_time					smallint,
	    @pack_count				    smallint,
	    @pack_time					smallint,
        @booked_count				int,
        @booked_time				int,
        @ad_check					int,
        @time_check					int,
		@campaign_booked_count 	    int,
		@campaign_booked_time  	    int,
		@package_code				char(4),
        @spot_count					int,
        @spot_variance				int,
        @loop						int,
		@package_id 				int,
        @media_product_id           int


 
 
/*
 * Create a table for returning the screening dates and complex ids
 */

create table #overbooked
(
	screening_date		datetime,
	complex_id			int
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0

/*
 * Declare Cursors
 */ 

 declare spot_csr cursor static for
  select cd.complex_id,
         cd.screening_date,
		 spot.package_id,
 		 (case when pack.media_product_id = 1 then (cd.max_ads * cd.movie_target * pd.film_ad_percent) else (cd.mg_max_ads * cd.movie_target * pd.dmg_ad_percent) end),
		 (case when pack.media_product_id = 1 then (cd.max_time * cd.movie_target * pd.film_ad_percent) else (cd.mg_max_time * cd.movie_target * pd.dmg_ad_percent) end),
         count(pack.package_id),
		 sum(pack.capacity_prints),
         sum(pack.capacity_duration),
         pack.media_product_id
    from campaign_spot spot,
         campaign_package pack,
         complex_date cd,
		 product_date pd
   where spot.campaign_no = @campaign_no and
         spot.screening_date = cd.screening_date and
		 spot.complex_id = cd.complex_id and
         spot.package_id = pack.package_id and
		 pd.screening_date = cd.screening_date and
		 pd.screening_date = spot.screening_date and
		 pd.product_category_id = pack.product_category
group by cd.complex_id,
         cd.screening_date,
		 spot.package_id,
         cd.max_ads,
         cd.max_time,
         cd.mg_max_ads,
         cd.mg_max_time,
		 cd.movie_target,
         spot.complex_id,
		 spot.screening_date,
         pack.media_product_id,
		 pd.film_ad_percent,
		 pd.dmg_ad_percent
order by cd.complex_id,
         cd.screening_date,
		 spot.package_id
     for read only




/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into @complex_id, 
				    @screening_date, 
				    @package_id,
				    @max_ads, 
				    @max_time,
				    @spot_count,	
                    @pack_count,
                    @pack_time,
                    @media_product_id

while(@@fetch_status=0)
begin

	select @spot_csr_open = 1

	/*
	 * Get Count of Booked Spots
	 */

	select @booked_count = IsNull(sum(pack.capacity_prints),0),
		   @booked_time = Isnull(sum(pack.capacity_duration),0)
	  from campaign_spot spot,
		   campaign_package pack,
           film_campaign fc
	 where spot.complex_id = @complex_id and
           spot.screening_date = @screening_date and
           spot.spot_status <> 'P' and
		   spot.campaign_no <> @campaign_no and
		   spot.package_id = pack.package_id and
           fc.campaign_no = pack.campaign_no and
           fc.campaign_no = spot.campaign_no and
           pack.media_product_id = @media_product_id

	/*
	 * Get Count of Campaign Spots
	 */

	select @campaign_booked_count = IsNull(sum(pack.capacity_prints),0),
			 @campaign_booked_time = Isnull(sum(pack.capacity_duration),0)
	  from campaign_spot spot,
			 campaign_package pack
	 where spot.complex_id = @complex_id and
          spot.screening_date = @screening_date and
			 spot.campaign_no = @campaign_no and
			 pack.package_code < @package_code and
			 spot.package_id = pack.package_id

	select @ad_check = @max_ads - (@booked_count + @campaign_booked_count)
	select @time_check = @max_time - (@booked_time + @campaign_booked_time)

	if(@ad_check < 0)
		select @ad_check = @spot_count
	else
	begin
		select @loop = 0
		select @ad_check = @ad_check - (@pack_count / @spot_count)
		while(@ad_check >= 0)
		begin
			select @loop = @loop + 1
			select @ad_check = @ad_check - (@pack_count / @spot_count)
		end		
		select @ad_check = @spot_count - @loop
	end

	if(@time_check < 0)
		select @time_check = @spot_count
	else
	begin
		select @loop = 0
      select @time_check = @time_check - (@pack_time / @spot_count)
		while(@time_check >= 0)
		begin
			select @loop = @loop + 1
   	   select @time_check = @time_check - (@pack_time / @spot_count)
		end		
		select @time_check = @spot_count - @loop
	end

	/*
	 * Check if this Spot is Effected
	 */

	if((@ad_check > 0) or (@time_check > 0))
	begin

		if(@ad_check > @time_check)
			select @spot_variance = @ad_check
		else
			select @spot_variance = @time_check

		insert into #overbooked values (@screening_date, @complex_id)

	end
	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @complex_id, 
							  @screening_date, 
							  @package_id,
							  @max_ads, 
							  @max_time,
							  @spot_count,	
							  @pack_count,
							  @pack_time,
                              @media_product_id

end

close spot_csr
deallocate spot_csr

/*
 * Return Overbooked List
 */

  select complex_id,
         screening_date
    from #overbooked
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
