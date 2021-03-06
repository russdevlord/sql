/****** Object:  StoredProcedure [dbo].[p_op_sched_overbook]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_sched_overbook]
GO
/****** Object:  StoredProcedure [dbo].[p_op_sched_overbook]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create    PROC [dbo].[p_op_sched_overbook] 	@campaign_no 			int
as

set nocount on 

declare @error							int,
        @spot_csr_open					tinyint,
        @spot_id						int,
        @screening_date					datetime,
		@row_type						char(10),
		@package_code					char(4),
        @spot_count						int,
		@outpost_panel_id_current   	int,
		@package_id_current				int,
		@current_screening_date			datetime,
		@current_spot_count				int,
		@current_row_type				char(10),
        @outpost_panel_campaign_type    char(1),
	    @product_category_id 			int,
		@max_Ads						int,
		@max_time						int,
		@booked_count					int,
		@campaign_booked_count			int,
		@booked_time					int,
		@campaign_booked_time			int,
		@pack_count						int,
		@pack_time						int,
		@ad_check						int,
		@time_check						int,
		@loop							int,
		@spot_variance					int,
		@spot            				int,
        @startdate        				datetime,
        @enddate        				datetime,
	    @inc							int,
		@count_segs						int,
		@count_day						int,
		@fully_booked  					char(1),
		@time_id 						datetime, 
		@spots_num 						int, 
		@fullybooked 					int,
        @outpost_panel_id  		        int,
        @package_id  			        int 
		
		

/*
 * Create a table for returning the screening dates and outpost_venue ids
 */

create table #overbooked
(
	screening_date		datetime		null,
	outpost_panel_id	int		    	null,
	package_id			int		        null,
	row_type			char(10)		null,
    spot_count			int	        	null,
    fully_booked		char(1)			null, 
	start_date 			datetime 		null,		
	end_date 			datetime		null
)

/*
 * Initialise Variables
 */


 
select @spot_csr_open = 0

/*
 * Loop through Spots
 */

declare 	spot_csr cursor static for
select 		spot.outpost_panel_id,
			cd.screening_date,
            spot.package_id,
			(case when pack.screening_trailers = 'S' then cd.max_ads else cd.max_ads_trailers end),
			(case when pack.screening_trailers = 'S' then cd.max_time else cd.max_time_trailers end),
			'Screening',
			count(pack.package_id),
			sum(pack.capacity_prints),
			sum(pack.capacity_duration), 
			spot.spot_id  --GB
from 		outpost_spot spot,
			outpost_player_xref pan,
			outpost_package pack,
			outpost_player_date cd
where 		spot.campaign_no = @campaign_no 
and			spot.screening_date = cd.screening_date 
and			spot.outpost_panel_id = pan.outpost_panel_id 
and			pan.player_name = cd.player_name 
and			spot.package_id = pack.package_id 
group by 	spot.outpost_panel_id,
			cd.screening_date,
			cd.max_ads,
			cd.max_time,
			cd.max_ads_trailers,
			cd.max_time_trailers,
			pack.screening_trailers, 
			spot.spot_id,
            spot.package_id            --GB
union all
select 		spot.outpost_panel_id,
			cd.screening_date,
            spot.package_id,
			(case when pack.screening_trailers = 'S' then cd.max_ads else cd.max_ads_trailers end),
			(case when pack.screening_trailers = 'S' then cd.max_time else cd.max_time_trailers end),
			'Billing',
			count(pack.package_id),
			sum(pack.capacity_prints),
			sum(pack.capacity_duration), 
			spot.spot_id
from 		outpost_spot spot,
			outpost_player_xref pan,
			outpost_package pack,
			outpost_player_date cd
where 		spot.campaign_no = @campaign_no 
and			spot.billing_date = cd.screening_date 
and			spot.outpost_panel_id = pan.outpost_panel_id 
and			pan.player_name = cd.player_name 
and			spot.package_id = pack.package_id 
group by 	spot.outpost_panel_id,
			cd.screening_date,
			cd.max_ads,
			cd.max_time,
			cd.max_ads_trailers,
			cd.max_time_trailers,
			pack.screening_trailers,
			spot.spot_id,
            spot.package_id
order by 	spot.outpost_panel_id,
			cd.screening_date
for 		read only


open spot_csr
fetch spot_csr into @outpost_panel_id, 
				    @screening_date, 
                    @package_id,
				    @max_ads, 
				    @max_time,
				    @row_type,
                    @spot_count,
                    @pack_count,
                    @pack_time,
					@spot
while(@@fetch_status=0)
begin

    select  @package_code = package_code,
            @product_category_id = product_category,
            @outpost_panel_campaign_type = screening_trailers
      from  outpost_package
     where  package_id = @package_id
    
    
    if @outpost_panel_campaign_type = 'S'
    begin
        select @outpost_panel_campaign_type = 'S'
    end
    else
    begin
        select @outpost_panel_campaign_type = 'C'
    end
    
	declare 	spot_sds_csr cursor static for
	select 		outpost_spot_daily_segment.start_date, 
				outpost_spot_daily_segment.end_date 
	from 		outpost_spot_daily_segment,
				outpost_spot,
				outpost_package
	where 		outpost_spot_daily_segment.spot_id = outpost_spot.spot_id
	and			outpost_spot.spot_status <> 'P'
	and			outpost_spot.package_id = outpost_package.package_id 
	and			((@outpost_panel_campaign_type = 'S' 
	and			screening_trailers = 'S') 
	or			(@outpost_panel_campaign_type = 'C' 
	and 		(screening_trailers = 'D' 
	or 			screening_trailers = 'C')))
	and			outpost_panel_id = @outpost_panel_id
	and			screening_date = @screening_date
	group by	outpost_spot_daily_segment.start_date, 
				outpost_spot_daily_segment.end_date 	 
	order by	outpost_spot_daily_segment.start_date, 
				outpost_spot_daily_segment.end_date 	 
	for 		read only
	
	open spot_sds_csr
	fetch spot_sds_csr into @startdate, @enddate
	while(@@fetch_status = 0)
	begin
    
        select  @booked_count=0,
                @booked_time=0,
                @campaign_booked_count=0,
                @campaign_booked_time=0,
                @ad_check=0,
                @time_check=0
                
		/*
		 * Get Count of Booked Spots
		 */
	
		select  @booked_count = IsNull(sum(pack.capacity_prints),0),
				@booked_time = Isnull(sum(pack.capacity_duration),0)
		from  	outpost_spot spot, 
				outpost_spot_daily_segment ds,
				outpost_package pack
		where  	spot.outpost_panel_id = @outpost_panel_id 
		and		spot.screening_date = @screening_date 
		and		spot.spot_status <> 'P' 
		and		spot.campaign_no <> @campaign_no 
		and		spot.package_id = pack.package_id 
		and		((@outpost_panel_campaign_type = 'S' 
		and		pack.screening_trailers = 'S') 
		or		(@outpost_panel_campaign_type = 'C' 
		and 	(pack.screening_trailers = 'D' 
		or 		pack.screening_trailers = 'C')))
		and 	ds.spot_id = spot.spot_id 
		and		ds.start_date <= @enddate
		and		ds.end_date >= @startdate

		/*
		 * Get Count of Campaign Spots
		 */
	
		select  @campaign_booked_count = IsNull(sum(pack.capacity_prints),0),
				@campaign_booked_time = Isnull(sum(pack.capacity_duration),0)
		from  	outpost_spot spot, 
				outpost_spot_daily_segment ds,
				outpost_package pack
		where  	spot.outpost_panel_id = @outpost_panel_id 
		and		spot.screening_date = @screening_date 
		and		spot.campaign_no = @campaign_no 
		and		pack.package_code < @package_code 
		and		spot.package_id = pack.package_id 
		and		((@outpost_panel_campaign_type = 'S' 
		and 	pack.screening_trailers = 'S') 
		or		(@outpost_panel_campaign_type = 'C' 
		and 	(pack.screening_trailers = 'D' 
		or 		pack.screening_trailers = 'C')))
		and 	ds.spot_id = spot.spot_id 
		and		ds.start_date <= @enddate
		and		ds.end_date >= @startdate

		select @ad_check 	= @max_ads - @booked_count - @campaign_booked_count - @pack_count
		select @time_check 	= @max_time - @booked_time - @campaign_booked_time - @pack_time
       
/*
        print @outpost_panel_id
        print @outpost_panel_campaign_type
        print convert(varchar(30), @startdate,120)
        print convert(varchar(30), @enddate,120)
        print @max_ads
        print @booked_count
        print @campaign_booked_count
        print @pack_count
        print @ad_check
        print '-------'
*/            

		/*
		 * Check if this Spot is Affected
		 */

		if((@ad_check < 0) or (@time_check < 0))
		begin
			set @fully_booked = 'Y' --if all returned rows have yes then row is fully booked, if some have yes then partially booked
	
			if(@row_type = 'Screening')
			begin
				if(@ad_check > @time_check)
					select @spot_variance = @ad_check
				else
					select @spot_variance = @time_check
			end
			else
			begin
				select @spot_variance = 0
			end
		end
		else
		begin
			set @fully_booked = 'N' --if all returned rows have yes then row is fully booked, if some have yes then partially booked
		end

		insert into #overbooked values (@screening_date, @outpost_panel_id, @package_id, @row_type, @spot_variance, @fully_booked, @startdate, @enddate)
        
		--GB
		fetch spot_sds_csr into @startdate, @enddate
	end
	
	close spot_sds_csr
	deallocate spot_sds_csr

	/*
	 * Fetch Next Spot
	 */

	fetch spot_csr into @outpost_panel_id, 
					    @screening_date, 
					    @package_id,
				        @max_ads, 
					    @max_time,
					    @row_type,
					    @spot_count,
					    @pack_count,
					    @pack_time,
						@spot  --GB

end

close spot_csr
deallocate spot_csr

/*
 * Return Overbooked List
 */

select 	    outpost_panel_id,
            screening_date,
            package_id,
            row_type,
            spot_count,
            fully_booked
from	    #overbooked
where       screening_date in (select screening_date from #overbooked where fully_booked = 'Y')
group by    outpost_panel_id,
		    screening_date,
            package_id,
            row_type,
            spot_count,
            fully_booked
order by    screening_date,
		    row_type        

/*
 * Return Success
 */

return 0
GO
