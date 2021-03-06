/****** Object:  StoredProcedure [dbo].[p_inclusion_check_overbooked]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_check_overbooked]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_check_overbooked]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_inclusion_check_overbooked] @campaign_no 		int,
	                                     @complex_id  		int,
	                                     @inclusion_id  	int
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
        @spot_count					int,
        @spot_variance				int,
        @loop						int,
	    @product_category_id 		int,
		@inclusion_format			char(1)

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #overbooked
(
	screening_date		datetime		null,
	complex_id			int		        null,
    inclusion_id		int		        null,
	row_type			char(10)		null,
    spot_count			int	        	null,
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0
select @last_complex_date = 0

/*
 * Get Package Code to Count Packages less than this one
 */

select  @product_category_id = product_category_id,
		@inclusion_format = inclusion_format
  from  inclusion
 where  inclusion_id = @inclusion_id

/*
 * Loop through Spots
 */

 declare spot_csr cursor static for
  select spot.complex_id,
         spot.screening_date,
		 1,
		 1,
	     'Screening',
         count(inc.inclusion_id),
         count(inc.inclusion_id),
		 count(inc.inclusion_id)
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.complex_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
		 inc.inclusion_format <> 'R'
group by spot.complex_id,
         spot.screening_date
union all
  select spot.complex_id,
         spot.billing_date,
		 1,
		 1,
	     'Screening',
         count(inc.inclusion_id),
         count(inc.inclusion_id),
		 count(inc.inclusion_id)
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.complex_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
		 inc.inclusion_format <> 'R'
group by spot.complex_id,
         spot.billing_date
union all
  select spot.outpost_venue_id,
         spot.op_screening_date,
		 1,
		 1,
	     'Screening',
         count(inc.inclusion_id),
         count(inc.inclusion_id),
		 count(inc.inclusion_id)
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.outpost_venue_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
		 inc.inclusion_format = 'R'
group by spot.outpost_venue_id,
         spot.op_screening_date
union all
  select spot.outpost_venue_id,
         spot.op_billing_date,
		 1,
		 1,
	     'Screening',
         count(inc.inclusion_id),
         count(inc.inclusion_id),
		 count(inc.inclusion_id)
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.outpost_venue_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
		 inc.inclusion_format <> 'R'
group by spot.outpost_venue_id,
         spot.op_billing_date
order by spot.complex_id,
         spot.screening_date
     for read only


open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @complex_id, 
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

	if @inclusion_format <> 'R'
	begin
		select 	@booked_count = IsNull(count(inc.inclusion_id),0),
				@booked_time = IsNull(count(inc.inclusion_id),0)
		from 	inclusion_spot spot,
				inclusion inc
		where 	spot.complex_id = @complex_id 
		and		spot.screening_date = @screening_date 
		and		spot.spot_status <> 'P' 
		and		spot.campaign_no <> @campaign_no 
		and		spot.inclusion_id = inc.inclusion_id 
	end
	else
	begin
		select 	@booked_count = IsNull(count(inc.inclusion_id),0),
				@booked_time = IsNull(count(inc.inclusion_id),0)
		from 	inclusion_spot spot,
				inclusion inc
		where 	spot.outpost_venue_id = @complex_id 
		and		spot.op_screening_date = @screening_date 
		and		spot.spot_status <> 'P' 
		and		spot.campaign_no <> @campaign_no 
		and		spot.inclusion_id = inc.inclusion_id 
	end

	
	/*
	 * Get Count of Campaign Spots
	 */
	
	if @inclusion_format <> 'R'
	begin
		select 	@campaign_booked_count = IsNull(count(inc.inclusion_id),0),
				@campaign_booked_time = IsNull(count(inc.inclusion_id),0)
		from 	inclusion_spot spot,
				inclusion inc
		where 	spot.complex_id = @complex_id 
		and		spot.screening_date = @screening_date 
		and		spot.campaign_no = @campaign_no 
		and		inc.inclusion_id <> @inclusion_id 
		and		spot.inclusion_id = inc.inclusion_id 
	end
	else
	begin
		select 	@campaign_booked_count = IsNull(count(inc.inclusion_id),0),
				@campaign_booked_time = IsNull(count(inc.inclusion_id),0)
		from 	inclusion_spot spot,
				inclusion inc
		where 	spot.outpost_venue_id = @complex_id 
		and		spot.op_screening_date = @screening_date 
		and		spot.campaign_no = @campaign_no 
		and		inc.inclusion_id <> @inclusion_id 
		and		spot.inclusion_id = inc.inclusion_id 
	end
	

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

		insert into #overbooked values (@screening_date, @complex_id, @inclusion_id, @row_type, @spot_variance)

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

  select complex_id,
         screening_date,
         inclusion_id,
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
