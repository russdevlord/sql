/****** Object:  StoredProcedure [dbo].[p_sched_check_cl_overbooked]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sched_check_cl_overbooked]
GO
/****** Object:  StoredProcedure [dbo].[p_sched_check_cl_overbooked]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sched_check_cl_overbooked] 	@campaign_no 	int,
	                                     	@cinelight_id  	int,
	                                     	@package_id  	int
as
set nocount on 
declare @error						int,
        @spot_csr_open				tinyint,
        @spot_id					int,
        @screening_date				datetime,
		@row_type					char(10),
		@package_code				char(4),
        @spot_count					int,
		@cinelight_id_current   	int,
		@package_id_current			int,
		@current_screening_date		datetime,
		@current_spot_count			int,
		@current_row_type			char(10),
        @cinelight_campaign_type    char(1),
	    @product_category_id 		int,
		@max_Ads					int,
		@max_time					int,
		@booked_count				int,
		@campaign_booked_count		int,
		@booked_time				int,
		@campaign_booked_time		int,
		@pack_count					int,
		@pack_time					int,
		@ad_check					int,
		@time_check					int,
		@loop						int,
		@spot_variance				int		
		

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #overbooked
(
	screening_date		datetime		null,
	cinelight_id		int		        null,
	package_id			int		        null,
	row_type			char(10)		null,
    spot_count			int	        	null,
)

/*
 * Initialise Variables
 */

select  @package_code = package_code,
	    @product_category_id = product_category,
		@cinelight_campaign_type = screening_trailers
  from  cinelight_package
 where  package_id = @package_id


if @cinelight_campaign_type = 'S'
	select @cinelight_campaign_type = 'S'
else
	select @cinelight_campaign_type = 'C'
 
select @spot_csr_open = 0

/*
 * Loop through Spots
 */

 declare spot_csr cursor static for
  select cd.cinelight_id,
         cd.screening_date,
		 (case when pack.screening_trailers = 'S' then cd.max_ads else cd.max_ads_trailers end),
		 (case when pack.screening_trailers = 'S' then cd.max_time else cd.max_time_trailers end),
	     'Screening',
         count(pack.package_id),
         sum(pack.prints),
         sum(pack.duration)
    from cinelight_spot spot,
         cinelight_package pack,
         cinelight_date cd
   where spot.campaign_no = @campaign_no and
         spot.cinelight_id = @cinelight_id and
         spot.package_id = @package_id and
         spot.screening_date = cd.screening_date and
         spot.cinelight_id = cd.cinelight_id and
         spot.package_id = pack.package_id 
group by cd.cinelight_id,
         cd.screening_date,
         cd.max_ads,
         cd.max_time,
         cd.max_ads_trailers,
         cd.max_time_trailers,
		 pack.screening_trailers
union all
  select cd.cinelight_id,
         cd.screening_date,
		 (case when pack.screening_trailers = 'S' then cd.max_ads else cd.max_ads_trailers end),
		 (case when pack.screening_trailers = 'S' then cd.max_time else cd.max_time_trailers end),
	     'Billing',
         count(pack.package_id),
         sum(pack.prints),
         sum(pack.duration)
    from cinelight_spot spot,
         cinelight_package pack,
         cinelight_date cd
   where spot.campaign_no = @campaign_no and
         spot.cinelight_id = @cinelight_id and
         spot.package_id = @package_id and
         spot.billing_date = cd.screening_date and
         spot.cinelight_id = cd.cinelight_id and
         spot.package_id = pack.package_id 
group by cd.cinelight_id,
         cd.screening_date,
         cd.max_ads,
         cd.max_time,
         cd.max_ads_trailers,
         cd.max_time_trailers,
		 pack.screening_trailers
order by cd.cinelight_id,
         cd.screening_date
     for read only


open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @cinelight_id, 
				    @screening_date, 
				    @max_ads, 
				    @max_time,
				    @row_type,
                    @spot_count,
                    @pack_count,
                    @pack_time

while(@@fetch_status=0)
begin

	/*
	 * Get Count of Booked Spots
	 */

	select  @booked_count = IsNull(sum(pack.prints),0),
		    @booked_time = Isnull(sum(pack.duration),0)
	  from  cinelight_spot spot,
		    cinelight_package pack
	 where  spot.cinelight_id = @cinelight_id and
            spot.screening_date = @screening_date and
            spot.spot_status <> 'P' and
			spot.campaign_no <> @campaign_no and
		    spot.package_id = pack.package_id and
			(
			 (@cinelight_campaign_type = 'S' and pack.screening_trailers = 'S') or
			 (@cinelight_campaign_type = 'C' and (pack.screening_trailers = 'D' or pack.screening_trailers = 'C'))
			)

	/*
	 * Get Count of Campaign Spots
	 */

	select  @campaign_booked_count = IsNull(sum(pack.prints),0),
		    @campaign_booked_time = Isnull(sum(pack.duration),0)
	  from  cinelight_spot spot,
		    cinelight_package pack
	 where  spot.cinelight_id = @cinelight_id and
            spot.screening_date = @screening_date and
		    spot.campaign_no = @campaign_no and
		    pack.package_code < @package_code and
		    spot.package_id = pack.package_id and
			(
			 (@cinelight_campaign_type = 'S' and pack.screening_trailers = 'S') or
			 (@cinelight_campaign_type = 'C' and (pack.screening_trailers = 'D' or pack.screening_trailers = 'C'))
			)
          

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

		if(@row_type = 'Screening')
		begin
			if(@ad_check > @time_check)
				select @spot_variance = @ad_check
			else
				select @spot_variance = @time_check
		end
		else
			select @spot_variance = 0

		insert into #overbooked values (@screening_date, @cinelight_id, @package_id, @row_type, isnull(@spot_variance,0))

	end

	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @cinelight_id, 
					    @screening_date, 
					    @max_ads, 
					    @max_time,
					    @row_type,
					    @spot_count,
					    @pack_count,
					    @pack_time

end

if (@spot_csr_open = 1)
	begin
		close spot_csr
		deallocate spot_csr
		select @spot_csr_open = 0
	end

/*
 * Return Overbooked List
 */

  select cinelight_id,
         screening_date,
         package_id,
		 row_type,
         spot_count
    from #overbooked

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
