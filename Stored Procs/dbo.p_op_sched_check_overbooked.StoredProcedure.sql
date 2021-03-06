/****** Object:  StoredProcedure [dbo].[p_op_sched_check_overbooked]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_sched_check_overbooked]
GO
/****** Object:  StoredProcedure [dbo].[p_op_sched_check_overbooked]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create    PROC [dbo].[p_op_sched_check_overbooked] 	@campaign_no 			int,
	                                     			@outpost_panel_id  		int,
	                                     			@package_id  			int
as

set nocount on 

declare	@error												int,
				@spot_csr_open								tinyint,
				@spot_id											int,
				@screening_date								datetime,
				@row_type										char(10),
				@package_code								char(4),
				@spot_count										int,
				@outpost_panel_id_current			int,
				@package_id_current						int,
				@current_screening_date				datetime,
				@current_spot_count						int,
				@current_row_type							char(10),
				@outpost_panel_campaign_type    char(1),
				@product_category_id 					int,
				@max_Ads											int,
				@max_time										int,
				@booked_count								int,
				@campaign_booked_count				int,
				@booked_time									int,
				@campaign_booked_time				int,
				@pack_count										int,
				@pack_time										int,
				@ad_check										int,
				@time_check										int,
				@loop													int,
				@spot_variance									int,
				@spot            										int,
				@startdate        								datetime,
				@enddate        									datetime,
				@start_date1       								datetime,
				@end_date1        								datetime,
				@start_date2       							datetime,
				@end_date2        								datetime,
				@inc													int,
				@count_segs										int,
				@count_day										int,
				@fully_booked  								char(1),
				@time_id 											datetime, 
				@spots_num 										int, 
				@fullybooked 									int,
				@overlap											int,
				@break												int
		
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

create table #segment_distinct_times
(
start_date					datetime				not null,
end_date					datetime				not null
)

create table #segment_distinct_times_temp
(
start_date					datetime				not null,
end_date					datetime				not null
)

/*
 * Initialise Variables
 */

select  @package_code = package_code,
	    @product_category_id = product_category,
		@outpost_panel_campaign_type = screening_trailers
  from  outpost_package
 where  package_id = @package_id


if @outpost_panel_campaign_type = 'S'
	select @outpost_panel_campaign_type = 'S'
else
	select @outpost_panel_campaign_type = 'C'
 
select @spot_csr_open = 0

/*
 * Loop through Spots
 */

declare 	spot_csr cursor static for
select 		spot.outpost_panel_id,
			cd.screening_date,
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
and			spot.outpost_panel_id = @outpost_panel_id 
and			spot.package_id = @package_id 
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
			spot.spot_id  --GB
union all
select 		spot.outpost_panel_id,
			cd.screening_date,
			(case when pack.screening_trailers = 'S' then cd.max_ads else cd.max_ads_trailers end),
			(case when pack.screening_trailers = 'S' then cd.max_time else cd.max_time_trailers end),
			'Billing',
			count(pack.package_id),
			sum(pack.capacity_prints),
			sum(pack.capacity_duration), 
			spot.spot_id  --GB
from 		outpost_spot spot,
			outpost_player_xref pan,
			outpost_package pack,
			outpost_player_date cd
where 		spot.campaign_no = @campaign_no 
and			spot.outpost_panel_id = @outpost_panel_id 
and			spot.package_id = @package_id 
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
			spot.spot_id  --GB
order by 	spot.outpost_panel_id,
			cd.screening_date
for 		read only


open spot_csr
fetch spot_csr into @outpost_panel_id, 
				    @screening_date, 
				    @max_ads, 
				    @max_time,
				    @row_type,
                    @spot_count,
                    @pack_count,
                    @pack_time,
					@spot  --GB
while(@@fetch_status=0)
begin

	delete #segment_distinct_times

	insert into		#segment_distinct_times
	SELECT 			DISTINCT outpost_spot_daily_segment.start_date,   
					outpost_spot_daily_segment.end_date
	FROM 			outpost_spot_daily_segment ,   
					outpost_spot    
	WHERE 			outpost_spot_daily_segment.spot_id = outpost_spot.spot_id
	and  			outpost_spot.screening_date = @screening_date
	and  			outpost_spot.outpost_panel_id = @outpost_panel_id
	union					
	select			dateadd(hh, 6, @screening_date), 
					dateadd(ss, -1, dateadd(hh, 24, @screening_date))
	union			
	select			dateadd(dd, 1, dateadd(hh, 6, @screening_date)), 
					dateadd(dd, 1, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 2, dateadd(hh, 6, @screening_date)), 
					dateadd(dd, 2, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 3, dateadd(hh, 6, @screening_date)), 
					dateadd(dd, 3, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 4, dateadd(hh, 6, @screening_date)), 
					dateadd(dd, 4, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 5, dateadd(hh, 6, @screening_date)), 
					dateadd(dd, 5, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 6, dateadd(hh, 6, @screening_date)), 
					dateadd(dd, 6, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
								
	declare			playlist_csr cursor for
	SELECT 			DISTINCT outpost_spot_daily_segment.start_date,   
							outpost_spot_daily_segment.end_date
	FROM 				outpost_spot_daily_segment ,   
							outpost_spot    
	WHERE 			outpost_spot_daily_segment.spot_id = outpost_spot.spot_id
	and  				outpost_spot.screening_date = @screening_date
	and  				outpost_spot.outpost_panel_id = @outpost_panel_id								

	open playlist_csr
	fetch playlist_csr into @start_date2, @end_date2
	while(@@fetch_status = 0)
	begin
	
		select @break = 0
		
		select	@start_date1 = @start_date2, 
					@end_date1 = @end_date2 
	
		fetch playlist_csr into @start_date2, @end_date2 

		if @start_date2 > @start_date1 and @end_date1 = @end_date2
		begin
			update	#segment_distinct_times
			set			end_date = dateadd(ss, -1, @start_date2)
			where		start_date = @start_date1
			and			end_date = @end_date1
		end

		if @start_date2 = @start_date1 and @end_date1 < @end_date2
		begin
			update	#segment_distinct_times
			set			start_date = dateadd(ss, 1, @end_date1)
			where		start_date = @start_date2
			and			end_date = @end_date2
		end

		if @start_date2 > @start_date1 and @end_date1 > @end_date2
		begin
			update	#segment_distinct_times
			set			end_date = dateadd(ss, -1, @start_date2)
			where		start_date = @start_date1
			and			end_date = @end_date1
		
			insert into #segment_distinct_times values (dateadd(ss, 1, @end_date2), @end_date1)
		end
	end

	close playlist_csr
	deallocate playlist_csr
	
	delete #segment_distinct_times_temp

	insert into #segment_distinct_times_temp select start_date, end_date from #segment_distinct_times group by start_date, end_date

	delete #segment_distinct_times

	insert into #segment_distinct_times select start_date, end_date from #segment_distinct_times_temp group by start_date, end_date	
	
	
	select @overlap = 	count(*)
	from		(select count(*) as overlap from #segment_distinct_times group by start_date having count(start_date) > 1
					union 
					select count(*) as overlap from #segment_distinct_times group by end_date having count(end_date) > 1) as temp_table		


	while(@overlap > 0)
	begin
	
		select @overlap = 0
		
		declare			playlist_csr cursor for
		SELECT 			DISTINCT start_date,   
								end_date
		FROM 				#segment_distinct_times
		ORDER BY 		#segment_distinct_times.start_date,   
								#segment_distinct_times.end_date   
		for					read only
			
		open playlist_csr
		fetch playlist_csr into @start_date2, @end_date2
		while(@@fetch_status = 0)
		begin
		
			select @break = 0
			
			select	@start_date1 = @start_date2, 
					@end_date1 = @end_date2 
		
			fetch playlist_csr into @start_date2, @end_date2 

			if @start_date2 > @start_date1 and @end_date1 = @end_date2
			begin
				update	#segment_distinct_times
				set			end_date = dateadd(ss, -1, @start_date2)
				where		start_date = @start_date1
				and			end_date = @end_date1

				select @break = 1			
			end

			if @start_date2 = @start_date1 and @end_date1 < @end_date2
			begin
				update	#segment_distinct_times
				set			start_date = dateadd(ss, 1, @end_date1)
				where		start_date = @start_date2
				and			end_date = @end_date2

				select @break = 1
			end

			if @start_date2 > @start_date1 and @end_date1 > @end_date2
			begin
				update	#segment_distinct_times
				set			end_date = dateadd(ss, -1, @start_date2)
				where		start_date = @start_date1
				and			end_date = @end_date1
			
				insert into #segment_distinct_times values (dateadd(ss, 1, @end_date2), @end_date1)
				
				select @break = 1
			end
			
			if @break = 1
				break
		end

		close playlist_csr
		deallocate playlist_csr
		
		delete #segment_distinct_times_temp

		insert into #segment_distinct_times_temp select start_date, end_date from #segment_distinct_times group by start_date, end_date

		delete #segment_distinct_times

		insert into #segment_distinct_times select start_date, end_date from #segment_distinct_times_temp group by start_date, end_date

		--select *, 1, @row_type from #segment_distinct_times
		
		select		@overlap = count(*)
		from		(select count(*) as overlap from #segment_distinct_times group by start_date having count(start_date) > 1
						union 
						select count(*) as overlap from #segment_distinct_times group by end_date having count(end_date) > 1) as temp_table				
	end
	
	--select *, 2, @row_type from #segment_distinct_times			
	
	declare		spot_sds_csr cursor for
	SELECT 		DISTINCT #segment_distinct_times.start_date,   
				#segment_distinct_times.end_date
	FROM		#segment_distinct_times 
	ORDER BY 	#segment_distinct_times.start_date,   
				#segment_distinct_times.end_date   
	for			read only

	open spot_sds_csr
	fetch spot_sds_csr into @startdate, @enddate
	while(@@fetch_status = 0)
	begin

		
		select		@booked_count = 0, 
						@booked_time = 0,
						@pack_count = 0,
						@pack_time = 0,
						@campaign_booked_count = 0,
						@campaign_booked_time = 0,
						@ad_check = 0,
						@time_check = 0
	
		/*
		 * Get Count of Booked Spots
		 */

		select	@booked_count	= 	IsNull(sum(temp_table.capacity_prints),0),
				@booked_time	= 	Isnull(sum(temp_table.capacity_duration),0)	
		from		(select	spot.spot_id, 
							capacity_prints,
							capacity_duration	
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
					group by spot.spot_id, 
							capacity_prints,
							capacity_duration) temp_table
							

		select	@pack_count	= 	IsNull(sum(temp_table.capacity_prints),0),
				@pack_time	= 	Isnull(sum(temp_table.capacity_duration),0)	
		from		(select	spot.spot_id, 
							capacity_prints,
							capacity_duration	
					from  	outpost_spot spot, 
							outpost_spot_daily_segment ds,
							outpost_package pack
					where  	spot.outpost_panel_id = @outpost_panel_id 
					and		spot.screening_date = @screening_date 
					--and		spot.spot_status <> 'P' 
					and		spot.campaign_no = @campaign_no 
					and		spot.package_id = @package_id
					and		spot.package_id = pack.package_id 
					and		((@outpost_panel_campaign_type = 'S' 
					and		pack.screening_trailers = 'S') 
					or		(@outpost_panel_campaign_type = 'C' 
					and 	(pack.screening_trailers = 'D' 
					or 		pack.screening_trailers = 'C')))
					and 	ds.spot_id = spot.spot_id 
					and		ds.start_date <= @enddate
					and		ds.end_date >= @startdate
					group by spot.spot_id, 
							capacity_prints,
							capacity_duration) temp_table							

		/*
		 * Get Count of Campaign Spots
		 */
	
		select  @campaign_booked_count = IsNull(sum(temp_table.capacity_prints),0),
				@campaign_booked_time = Isnull(sum(temp_table.capacity_duration),0)
		from		(select	spot.spot_id, 
							capacity_prints,
							capacity_duration	
					from  	outpost_spot spot, 
							outpost_spot_daily_segment ds,
							outpost_package pack
					where  	spot.outpost_panel_id = @outpost_panel_id 
					and		spot.screening_date = @screening_date 
					and		spot.campaign_no = @campaign_no 
					and		pack.package_id <> @package_id 
					and		spot.package_id = pack.package_id 
					and		((@outpost_panel_campaign_type = 'S' 
					and 	pack.screening_trailers = 'S') 
					or		(@outpost_panel_campaign_type = 'C' 
					and 	(pack.screening_trailers = 'D' 
					or 		pack.screening_trailers = 'C')))
					and 	ds.spot_id = spot.spot_id 
					and		ds.start_date <= @enddate
					and		ds.end_date >= @startdate
					group by spot.spot_id, 
							capacity_prints,
							capacity_duration) temp_table

		select @ad_check 	= @max_ads - (@booked_count + @campaign_booked_count) - @pack_count
		select @time_check 	= @max_time - (@booked_time + @campaign_booked_time) - @pack_time

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
			select @spot_variance = 0
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
            1,--isnull(spot_count,0),
            fully_booked
from	    #overbooked
where		isnull(spot_count,0) <> 0	
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
