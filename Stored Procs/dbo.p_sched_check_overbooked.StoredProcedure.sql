/****** Object:  StoredProcedure [dbo].[p_sched_check_overbooked]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sched_check_overbooked]
GO
/****** Object:  StoredProcedure [dbo].[p_sched_check_overbooked]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sched_check_overbooked] @campaign_no int,
											 @complex_id  int,
											 @package_id  int
as
set nocount on 
declare @error						int,
        @spot_csr_open				tinyint,
        @spot_id					int,
        @complex_date				int,
        @screening_date				datetime,
        @pcat						int,
        @last_complex_date       	int,
	    @max_ads					smallint,
	    @max_time					smallint,
	    @pack_count	    			smallint,
	    @pack_time					smallint,
        @booked_count				int,
        @booked_time				int,
        @ad_check					int,
        @time_check					int,
		@row_type					char(10),
		@campaign_booked_count 	    int,
		@campaign_booked_time   	int,
		@package_code				char(4),
        @spot_count					int,
        @spot_variance				int,
        @loop						int,
        @media_product_id           smallint,
	    @product_category_id 		int,
	    @campaign_type				int,
	    @screen_no					int

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #overbooked
(
	screening_date		datetime		null,
	complex_id			int		        null,
    package_id			int		        null,
	row_type			char(10)		null,
    spot_count			int	        	null,
    screen_no			int				null
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0
select @last_complex_date = 0

/*
 * Get Package Code to Count Packages less than this one
 */

select  @package_code = package_code,
	 	@media_product_id = media_product_id,
	    @product_category_id = product_category
  from  campaign_package
 where  package_id = @package_id
 
select	@campaign_type = campaign_type
from	film_campaign
where	campaign_no = @campaign_no 

/*
 * Loop through Spots
 */
 
if @campaign_type < 5
begin
	declare		spot_csr cursor static for
	select		cd.complex_id,
				cd.screening_date,
				(case when pack.media_product_id = 1 then (cd.max_ads * cd.movie_target * pd.film_ad_percent) else (cd.mg_max_ads * cd.movie_target * pd.dmg_ad_percent) end),
				(case when pack.media_product_id = 1 then (cd.max_time * cd.movie_target * pd.film_ad_percent) else (cd.mg_max_time * cd.movie_target * pd.dmg_ad_percent) end),
				'Screening',
				count(pack.package_id),
				sum(pack.capacity_prints),
				sum(pack.capacity_duration),
				-1
	from		campaign_spot spot,
				campaign_package pack,
				complex_date cd,
				product_date pd
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = @complex_id 
	and			spot.package_id = @package_id 
	and			spot.screening_date = cd.screening_date 
	and			spot.complex_id = cd.complex_id 
	and			spot.package_id = pack.package_id 
	and			spot.screening_date = pd.screening_date 
	and			pd.screening_date = cd.screening_date 
	and			pd.product_category_id = pack.product_category
	group by	cd.complex_id,
				cd.screening_date,
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
	union all
	select		cd.complex_id,
				spot.billing_date,
				(case when pack.media_product_id = 1 then (cd.max_ads * cd.movie_target * pd.film_ad_percent) else (cd.mg_max_ads * cd.movie_target * pd.dmg_ad_percent) end),
				(case when pack.media_product_id = 1 then (cd.max_time * cd.movie_target * pd.film_ad_percent) else (cd.mg_max_time * cd.movie_target * pd.dmg_ad_percent) end),
				'Billing',
				count(pack.package_id),
				sum(pack.capacity_prints),
				sum(pack.capacity_duration),
				-1
	from		campaign_spot spot,
				campaign_package pack,
				complex_date cd,
				product_date pd
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = @complex_id 
	and			spot.package_id = @package_id 
	and			spot.billing_date = cd.screening_date 
	and			spot.complex_id = cd.complex_id 
	and			spot.package_id = pack.package_id 
	and			spot.billing_date = pd.screening_date 
	and			pd.screening_date = cd.screening_date 
	and			pd.product_category_id = pack.product_category
	group by	cd.complex_id,
				spot.billing_date,
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
	order by	cd.complex_id,
				cd.screening_date
	for read only
end
else
begin

	create table #constraints
	(max_ads		int, 
	max_time		int)

	insert into #constraints exec p_certificate_cineads_constraints @complex_id
		
	declare		spot_csr cursor static for
	select		spot.complex_id,
				cd.screening_date,
				max_ads,
				max_time,
				'Screening',
				count(pack.package_id),
				sum(pack.capacity_prints),
				sum(pack.capacity_duration),
				cin.cinema_no
	from		campaign_spot spot,
				campaign_package pack,
				film_screening_dates cd,
				#constraints,
				cinema cin
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = @complex_id 
	and			spot.package_id = @package_id 
	and			spot.screening_date = cd.screening_date 
	and			spot.complex_id = cin.complex_id 
	and			spot.package_id = pack.package_id 
	and			spot.film_plan_id = cin.cinema_no	
	and			cin.active_flag = 'Y'
	group by	spot.complex_id,
				cd.screening_date,
				max_ads,
				max_time,
				cin.cinema_no
	union all
	select		spot.complex_id,
				cd.screening_date,
				max_ads,
				max_time,
				'Screening',
				count(pack.package_id),
				sum(pack.capacity_prints),
				sum(pack.capacity_duration),
				cin.cinema_no
	from		campaign_spot spot,
				campaign_package pack,
				film_screening_dates cd,
				#constraints,
				cinema cin
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = @complex_id 
	and			spot.package_id = @package_id 
	and			spot.billing_date = cd.screening_date 
	and			spot.complex_id = cin.complex_id 
	and			spot.package_id = pack.package_id 
	and			spot.film_plan_id = cin.cinema_no
	and			cin.active_flag = 'Y'
	group by	spot.complex_id,
				cd.screening_date,
				max_ads,
				max_time,
				cin.cinema_no
	order by	spot.complex_id,
				cd.screening_date
	for read only
end


open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @complex_id, 
				    @screening_date, 
				    @max_ads, 
				    @max_time,
				    @row_type,
                    @spot_count,
                    @pack_count,
                    @pack_time,
                    @screen_no

while(@@fetch_status=0)
begin

	/*
	 * Get Count of Booked Spots
	 */

	select	@booked_count = IsNull(sum(pack.capacity_prints),0),
			@booked_time = Isnull(sum(pack.capacity_duration),0)
	from	campaign_spot spot,
			campaign_package pack
	where	spot.complex_id = @complex_id 
	and		spot.screening_date = @screening_date 
	and		spot.spot_status <> 'P' 
	and		spot.campaign_no <> @campaign_no 
	and		spot.package_id = pack.package_id 
	and		pack.media_product_id = @media_product_id
	and		(@screen_no = -1
	or		spot.film_plan_id = @screen_no)
	
	/*
	 * Get Count of Campaign Spots
	 */

	select	@campaign_booked_count = IsNull(sum(pack.capacity_prints),0),
			@campaign_booked_time = Isnull(sum(pack.capacity_duration),0)
	from	campaign_spot spot,
			campaign_package pack
	where	spot.complex_id = @complex_id 
	and		spot.screening_date = @screening_date 
	and		spot.campaign_no = @campaign_no 
	and		pack.package_code < @package_code 
	and		spot.package_id = pack.package_id 
	and		pack.media_product_id = @media_product_id
	and		(@screen_no = -1
	or		spot.film_plan_id = @screen_no)          

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

		insert into #overbooked values (@screening_date, @complex_id, @package_id, @row_type, @spot_variance, @screen_no)

	end

	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @complex_id, 
					    @screening_date, 
					    @max_ads, 
					    @max_time,
					    @row_type,
					    @spot_count,
					    @pack_count,
					    @pack_time,
						@screen_no

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

select		complex_id,
			screening_date,
			package_id,
			row_type,
			sum(spot_count)
from		#overbooked
group by	complex_id,
			screening_date,
			package_id,
			row_type


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
