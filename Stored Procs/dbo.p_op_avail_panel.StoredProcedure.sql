/****** Object:  StoredProcedure [dbo].[p_op_avail_panel]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_avail_panel]
GO
/****** Object:  StoredProcedure [dbo].[p_op_avail_panel]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROC [dbo].[p_op_avail_panel]  	@outpost_panel_id			int,
										@start_date					datetime,
										@end_date					datetime,
										@prod_cat					int,
										@prints						int,
										@duration					int,
										@campaign_type				char(1)
as

set nocount on

/*
 * Declare Variables
 */

declare		@screening_date				datetime,
			@max_ads					int,
			@avail_ads					int,
			@book_ads					int,
			@max_time					int,
			@avail_time					int,
			@book_time					int,
			@date_csr_open				int,
			@clash_limit				int,
			@errorode						int,
			@clash_count				int,
			@avail_clash				int,
			@prod_count     			int,
			@outpost_venue_id			int,
			@player_name				varchar(100),
			@internal_name				varchar(100),
			@spot            			int,
			@count_day					int,
			@book_segs 					int,
			@prod_segs  				int,
			@fully_booked_ads			char(1),
			@fully_clash 				char(1),
			@error						int,
			@start_date1				datetime,
			@end_date1					datetime,
			@start_date2				datetime,
			@end_date2					datetime,
			@playlist_id				int,
			@playlist_no				int,
			@min_ads					int,
			@min_time					int

set nocount on

/*
 * Create Table to Hold Availability Information
 */


create table #segment_distinct_times
(
	start_date			datetime		not null,
	end_date			datetime		not null
)

create table #avails
(
	outpost_panel_id	int				null,
	screening_date		datetime		null,
	start_date			datetime		null,
	end_date			datetime		null,				
	avail_ads			int				null,
    avail_clash			int				null,
	avail_time			int				null,
	fully_booked_ads 	char(1)  		NULL, 
	fully_clash 		char(1)	 		NULL
)

/*
 * Initialise Variables
 */

select 	@date_csr_open = 0

select 	@outpost_venue_id = outpost_venue_id
from	outpost_panel
where	outpost_panel_id = @outpost_panel_id

select 	@player_name = player_name
from	outpost_player_xref
where 	outpost_panel_id = @outpost_panel_id

select	@internal_name = internal_desc
from	outpost_player
where	player_name = @player_name

/*
 * Loop Through Dates
 */

if @campaign_type = 'S' 
begin
	declare		date_csr cursor static for
	select 		cd.screening_date,
				max_ads,
				max_time,
				1
	from 		outpost_player_date cd
	where 		cd.screening_date between @start_date and @end_date 
	and 		cd.player_name = @player_name
	for			read only
end 
else if @campaign_type = 'C'
begin
	declare		date_csr cursor static for
	select 		cd.screening_date,
				max_ads_trailers,
				max_time_trailers,
				1
	from 		outpost_player_date cd
	where 		cd.screening_date between @start_date and @end_date 
	and 		cd.player_name = @player_name
	for			read only
end

open date_csr
select @date_csr_open = 1
fetch date_csr into @screening_date, @max_ads, @max_time, @clash_limit
while(@@fetch_status=0)
begin

	delete  #segment_distinct_times

	insert into		#segment_distinct_times
	SELECT 			DISTINCT outpost_spot_daily_segment.start_date,   
					outpost_spot_daily_segment.end_date
	FROM 			outpost_spot_daily_segment,   
					outpost_spot
	WHERE 			outpost_spot_daily_segment.spot_id = outpost_spot.spot_id
	and  			outpost_spot.outpost_panel_id = @outpost_panel_id
	and  			outpost_spot.screening_date = @screening_date
	union					
	select			dateadd(hh, 8, @screening_date), 
					dateadd(ss, -1, dateadd(hh, 24, @screening_date))
	union					
	select			dateadd(dd, 1, dateadd(hh, 8, @screening_date)), 
					dateadd(dd, 1, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 2, dateadd(hh, 8, @screening_date)), 
					dateadd(dd, 2, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 3, dateadd(hh, 8, @screening_date)), 
					dateadd(dd, 3, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 4, dateadd(hh, 8, @screening_date)), 
					dateadd(dd, 4, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 5, dateadd(hh, 8, @screening_date)), 
					dateadd(dd, 5, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
	union					
	select			dateadd(dd, 6, dateadd(hh, 8, @screening_date)), 
					dateadd(dd, 6, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
									
	declare			playlist_csr cursor for
	SELECT 			DISTINCT outpost_spot_daily_segment.start_date,   
					outpost_spot_daily_segment.end_date
	FROM 			outpost_spot_daily_segment,   
					outpost_spot  
	WHERE 			outpost_spot_daily_segment.spot_id = outpost_spot.spot_id
	and  			outpost_spot.outpost_panel_id = @outpost_panel_id
	and  			outpost_spot.screening_date = @screening_date
	ORDER BY 		outpost_spot_daily_segment.start_date,   
					outpost_spot_daily_segment.end_date   
	for				read only
								
	open playlist_csr
	fetch playlist_csr into @start_date2, @end_date2
	while(@@fetch_status = 0)
	begin
		select	@start_date1 = @start_date2, 
				@end_date1 = @end_date2 
		
		fetch playlist_csr into @start_date2, @end_date2 

		if @start_date2 > @start_date1 and @end_date1 = @end_date2
		begin
				update	#segment_distinct_times
				set		end_date = dateadd(ss, -1, @start_date2)
				where	start_date = @start_date1
				and		end_date = @end_date1
		end

		if @start_date2 = @start_date1 and @end_date1 < @end_date2
		begin
			update		#segment_distinct_times
			set			start_date = dateadd(ss, 1, @end_date1)
			where		start_date = @start_date2
			and			end_date = @end_date2
		end

	end

	close playlist_csr
	deallocate playlist_csr
	
	declare		playlist_csr	cursor for
	select		start_date,
				end_date
	from		#segment_distinct_times
	order by	start_date
	
	open playlist_csr
	fetch playlist_csr into @start_date1, @end_date1
	while(@@fetch_status = 0)						
	begin
	
		select @avail_clash = 999

		/*
		 * Calculate Bookings
		 */

		if(@prod_cat > 0)
		begin

			select 		@book_ads = isnull(sum(pack.capacity_prints),0),
						@book_time = isnull(sum(pack.capacity_duration),0)
			from 		outpost_spot spot,
						outpost_package pack,
						film_campaign fc
			where 		spot.outpost_panel_id = @outpost_panel_id 
			and			spot.screening_date = @screening_date 
			and			spot.spot_status <> 'D' 
			and			spot.spot_status <> 'P' 
			and			spot.package_id = pack.package_id 
			and			spot.campaign_no = fc.campaign_no 
			and			pack.campaign_no = fc.campaign_no 
			and			(
							(@campaign_type = 'S' and pack.screening_trailers = 'S') or
							(@campaign_type = 'C' and (pack.screening_trailers = 'D' or	pack.screening_trailers = 'C'))
							)
			and			spot.spot_id in (select spot_id from outpost_spot_daily_segment  where spot_id = spot.spot_id and start_date <= @start_date1 and end_date >= @end_date1 )							
			
			select 		@prod_count = isnull(count(pack.package_id),0)
			from 		outpost_spot spot,
						outpost_package pack,
						film_campaign fc,
						outpost_panel cl
			where 		spot.screening_date = @screening_date 
			and			spot.outpost_panel_id = cl.outpost_panel_id 
			and			cl.outpost_venue_id = @outpost_venue_id 
			and			spot.spot_status <> 'D' 
			and			spot.spot_status <> 'P' 
			and			spot.package_id = pack.package_id 
			and			pack.product_category = @prod_cat 
			and			spot.campaign_no = fc.campaign_no 
			and			pack.campaign_no = fc.campaign_no 
			and			(
							(@campaign_type = 'S' and pack.screening_trailers = 'S') or
							(@campaign_type = 'C' and (pack.screening_trailers = 'D' or	pack.screening_trailers = 'C'))
							)
			and			spot.spot_id in (select spot_id from outpost_spot_daily_segment  where spot_id = spot.spot_id and start_date <= @start_date1 and end_date >= @end_date1 )							
			
			if(@prod_count is null or @prod_count < 1)
				select @clash_count = 0
			else
				select @clash_count = @prod_count
			
			select @avail_clash = @clash_limit - @clash_count
			
		end
		else
		begin

			select 		@book_ads = Isnull(sum(pack.capacity_prints),0),
						@book_time = isnull(sum(pack.capacity_duration),0)
			from 		outpost_spot spot,
						outpost_package pack,
						film_campaign fc
			where 		spot.outpost_panel_id = @outpost_panel_id 
			and			spot.screening_date = @screening_date 
			and			spot.spot_status <> 'D' 
			and			spot.spot_status <> 'P' 
			and			spot.package_id = pack.package_id 
			and			spot.campaign_no = fc.campaign_no 
			and			pack.campaign_no = fc.campaign_no 
			and			(
							(@campaign_type = 'S' and pack.screening_trailers = 'S') or
							(@campaign_type = 'C' and (pack.screening_trailers = 'D' or	pack.screening_trailers = 'C'))
							)
			and			spot.spot_id in (select spot_id from outpost_spot_daily_segment  where spot_id = spot.spot_id and start_date <= @start_date1 and end_date >= @end_date1 )							
		end

		/*
		 * Determine Availability
		 */

		select @avail_ads = @max_ads - @book_ads
		select @avail_ads = round((@avail_ads / @prints) - 0.5, 0)

		select @avail_time = @max_time - @book_time
		select @avail_time = round((@avail_time / @duration) - 0.5, 0)

		insert into #avails values (	@outpost_panel_id,
															@screening_date, 
															@start_date1,
															@end_date1,
															@avail_ads,
															@avail_clash,
															@avail_time,
															'Y', 
															'Y')  
	
		fetch playlist_csr into @start_date1, @end_date1
	end

	close playlist_csr
	deallocate playlist_csr
	
	select		@min_ads = 0,
				@max_ads = 0,
				@min_time = 0,
				@max_time = 0
					
	select		@min_ads = min(avail_ads)	,
				@max_ads	= max(avail_ads),
				@min_time = min(avail_time),
				@max_time	= max(avail_time)
	from		#avails
	where		screening_date = @screening_date			
	
	if (@min_ads <> @max_ads or @min_time <> @max_time) and @max_time > 0 and @max_time > 0
	begin
		update		#avails
		set			fully_booked_ads = 'N'
		where		screening_date = @screening_date	
	end

	select		@min_ads = 0,
				@max_ads = 0
					
	select		@min_ads = min(avail_clash)	,
				@max_ads = max(avail_clash)
	from		#avails
	where		screening_date = @screening_date			
	
	if @min_ads <> @max_ads
	begin
		update	#avails
		set			fully_clash = 'N'
		where	screening_date = @screening_date	
	end
	
	/*
	 * Fetch Next
	 */

	fetch date_csr into @screening_date, @max_ads, @max_time, @clash_limit

end

close date_csr
deallocate date_csr

/*
 * Return Overbooked Data
 */

select 		avl.outpost_panel_id,
			avl.screening_date,
			min(avl.avail_ads) as avail_ads,
			min(avl.avail_clash) as avail_clash,
			min(avl.avail_time) as avail_time,
			fm.film_market_desc,
			cplx.market_no,
			cl.outpost_panel_desc,
			cplx.outpost_venue_id,
			cplx.outpost_venue_name,
			cbg.outpost_booking_group_id,
			cbg.outpost_booking_group_desc,
			avl.fully_booked_ads 	, 
			avl.fully_clash,
			@player_name, 
			@internal_name
from 		#avails avl,
			outpost_venue cplx,
			outpost_panel cl,
			film_market fm,
			outpost_booking_group cbg
where 		avl.outpost_panel_id = cl.outpost_panel_id
and			cplx.market_no = fm.film_market_no
and			cl.outpost_venue_id = cplx.outpost_venue_id
and			cl.outpost_booking_group_id = cbg.outpost_booking_group_id
group by	avl.outpost_panel_id,
			avl.screening_date,
			fm.film_market_desc,
			cplx.market_no,
			cl.outpost_panel_desc,
			cplx.outpost_venue_id,
			cplx.outpost_venue_name,
			cbg.outpost_booking_group_id,
			cbg.outpost_booking_group_desc,
			avl.fully_booked_ads 	, 
			avl.fully_clash

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	if (@date_csr_open = 1)
    begin
		close date_csr
		deallocate date_csr
	end
	return -1
GO
