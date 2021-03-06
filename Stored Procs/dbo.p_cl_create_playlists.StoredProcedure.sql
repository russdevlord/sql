/****** Object:  StoredProcedure [dbo].[p_cl_create_playlists]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_create_playlists]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_create_playlists]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_cl_create_playlists]			@player_name				varchar(100),
																							@screening_date			datetime
																				
as

declare				@error					int,
							@start_date1		datetime,
							@end_date1		datetime,
							@start_date2		datetime,
							@end_date2		datetime,
							@playlist_id		int,
							@playlist_no		int

set nocount on

create table #segment_distinct_times
(
start_date					datetime				not null,
end_date					datetime				not null
)

insert into			#segment_distinct_times
SELECT 			DISTINCT cinelight_spot_daily_segment.start_date,   
							cinelight_spot_daily_segment.end_date
FROM 				cinelight_spot_daily_segment ,   
							cinelight_spot ,   
							cinelight ,   
							cinelight_dsn_player_xref   
WHERE 			cinelight_spot_daily_segment.spot_id = cinelight_spot.spot_id
and  					cinelight_spot.cinelight_id = cinelight.cinelight_id
and  					cinelight.cinelight_id = cinelight_dsn_player_xref.cinelight_id
and  					cinelight_spot.screening_date = @screening_date
and  					cinelight_dsn_player_xref.player_name = @player_name
union					
select				dateadd(hh, 6, @screening_date), 
							dateadd(ss, -1, dateadd(hh, 24, @screening_date))
union					
select				dateadd(dd, 1, dateadd(hh, 6, @screening_date)), 
							dateadd(dd, 1, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
union					
select				dateadd(dd, 2, dateadd(hh, 6, @screening_date)), 
							dateadd(dd, 2, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
union					
select				dateadd(dd, 3, dateadd(hh, 6, @screening_date)), 
							dateadd(dd, 3, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
union					
select				dateadd(dd, 4, dateadd(hh, 6, @screening_date)), 
							dateadd(dd, 4, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
union					
select				dateadd(dd, 5, dateadd(hh, 6, @screening_date)), 
							dateadd(dd, 5, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
union					
select				dateadd(dd, 6, dateadd(hh, 6, @screening_date)), 
							dateadd(dd, 6, dateadd(ss, -1, dateadd(hh, 24, @screening_date)))
								

declare				playlist_csr cursor for
SELECT 			DISTINCT cinelight_spot_daily_segment.start_date,   
							cinelight_spot_daily_segment.end_date
FROM 				cinelight_spot_daily_segment ,   
							cinelight_spot ,   
							cinelight ,   
							cinelight_dsn_player_xref   
WHERE 			cinelight_spot_daily_segment.spot_id = cinelight_spot.spot_id
and  					cinelight_spot.cinelight_id = cinelight.cinelight_id
and  					cinelight.cinelight_id = cinelight_dsn_player_xref.cinelight_id
and  					cinelight_spot.screening_date = @screening_date
AND  					cinelight_dsn_player_xref.player_name = @player_name
ORDER BY 	cinelight_spot_daily_segment.start_date,   
							cinelight_spot_daily_segment.end_date   
for						read only
							
open playlist_csr
fetch playlist_csr into @start_date2, @end_date2
while(@@fetch_status = 0)
begin
	select @start_date1 = @start_date2, 
				 @end_date1 = @end_date2 
	
	fetch playlist_csr into @start_date2, @end_date2 

	print @start_date1
	print @end_date1 
	print @start_date2
	print @end_date2 

	if @start_date2 > @start_date1 and @end_date1 = @end_date2
	begin
			update #segment_distinct_times
			set			end_date = dateadd(ss, -1, @start_date2)
			where	start_date = @start_date1
			and			end_date = @end_date1
	end

	if @start_date2 = @start_date1 and @end_date1 < @end_date2
	begin
		update #segment_distinct_times
		set			start_date = dateadd(ss, 1, @end_date1)
		where	start_date = @start_date2
		and			end_date = @end_date2
	end

	if @start_date2 > @start_date1 and @end_date1 > @end_date2
	begin
		update #segment_distinct_times
		set			end_date = dateadd(ss, -1, @start_date2)
		where	start_date = @start_date1
		and			end_date = @end_date1
	
		insert into #segment_distinct_times values (dateadd(ss, 1, @end_date2), @end_date1)
	end
end


close playlist_csr
deallocate playlist_csr



--select * from #segment_distinct_times

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete any existing playlists
 */

delete	cinelight_playlist_item
where	playlist_id in (	select	playlist_id 
											from		cinelight_playlist 
											where	player_name = @player_name
											and			screening_date = @screening_date)

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error inserrt playlist', 16, 1)
	return -1
end

delete	cinelight_playlist_spot_xref
where	playlist_id in (	select	playlist_id 
											from		cinelight_playlist 
											where	player_name = @player_name
											and			screening_date = @screening_date)

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error inserrt playlist', 16, 1)
	return -1
end
		
delete cinelight_playlist
where player_name = @player_name
and screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error inserrt playlist', 16, 1)
	return -1
end


create table #segment_distinct_times_temp
(
start_date					datetime				not null,
end_date					datetime				not null
)

insert into #segment_distinct_times_temp select start_date, end_date from #segment_distinct_times group by start_date, end_date

delete #segment_distinct_times

insert into #segment_distinct_times select start_date, end_date from #segment_distinct_times_temp group by start_date, end_date

declare				playlist_csr cursor for
SELECT 			DISTINCT #segment_distinct_times.start_date,   
							#segment_distinct_times.end_date
FROM 				#segment_distinct_times 
ORDER BY 	#segment_distinct_times.start_date,   
							#segment_distinct_times.end_date   
for						read only
							
open playlist_csr
fetch playlist_csr into @start_date2, @end_date2
while(@@fetch_status = 0)
begin
	select @start_date1 = @start_date2, 
				 @end_date1 = @end_date2 
	
	fetch playlist_csr into @start_date2, @end_date2 

	if @start_date2 > @start_date1 and @end_date1 = @end_date2
	begin
			update #segment_distinct_times
			set			end_date = dateadd(ss, -1, @start_date2)
			where	start_date = @start_date1
			and			end_date = @end_date1
	end

	if @start_date2 = @start_date1 and @end_date1 < @end_date2
	begin
		update #segment_distinct_times
		set			start_date = dateadd(ss, 1, @end_date1)
		where	start_date = @start_date2
		and			end_date = @end_date2
	end

	if @start_date2 > @start_date1 and @end_date1 > @end_date2
	begin
		update #segment_distinct_times
		set			end_date = dateadd(ss, -1, @start_date2)
		where	start_date = @start_date1
		and			end_date = @end_date1
	
		insert into #segment_distinct_times values (dateadd(ss, 1, @end_date2), @end_date1)
	end
end


close playlist_csr
deallocate playlist_csr

declare				playlist_csr cursor for
SELECT 			DISTINCT #segment_distinct_times.start_date,   
							#segment_distinct_times.end_date
FROM 				#segment_distinct_times 
ORDER BY 	#segment_distinct_times.start_date,   
							#segment_distinct_times.end_date   
for						read only
							
open playlist_csr
fetch playlist_csr into @start_date2, @end_date2
while(@@fetch_status = 0)
begin
	select @start_date1 = @start_date2, 
				 @end_date1 = @end_date2 
	
	fetch playlist_csr into @start_date2, @end_date2 

	if @start_date2 > @start_date1 and @end_date1 = @end_date2
	begin
			update #segment_distinct_times
			set			end_date = dateadd(ss, -1, @start_date2)
			where	start_date = @start_date1
			and			end_date = @end_date1
	end

	if @start_date2 = @start_date1 and @end_date1 < @end_date2
	begin
		update #segment_distinct_times
		set			start_date = dateadd(ss, 1, @end_date1)
		where	start_date = @start_date2
		and			end_date = @end_date2
	end

	if @start_date2 > @start_date1 and @end_date1 > @end_date2
	begin
		update #segment_distinct_times
		set			end_date = dateadd(ss, -1, @start_date2)
		where	start_date = @start_date1
		and			end_date = @end_date1
	
		insert into #segment_distinct_times values (dateadd(ss, 1, @end_date2), @end_date1)
	end
end


close playlist_csr
deallocate playlist_csr


/*select * from #segment_distinct_times ORDER BY 	#segment_distinct_times.start_date,   
							#segment_distinct_times.end_date  */

/*
 * Create Playlists
 */ 
  
declare				playlist_csr cursor for
SELECT 			start_date,   
							end_date
FROM 				#segment_distinct_times
group by			start_date,   
							end_date
for						read only
							
							
select @playlist_no = 0
							
open playlist_csr
fetch playlist_csr into @start_date2, @end_date2
while(@@fetch_status = 0)
begin
	
	
		exec @error = p_get_sequence_number 'cinelight_playlist', 5, @playlist_id OUTPUT
		
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error obtaining playlist id', 16, 1)
			return -1
		end
		
		select @playlist_no = @playlist_no + 1
		
		insert into cinelight_playlist
		values (@playlist_id, @player_name, @screening_date, @start_date2, @end_date2, @playlist_no)
		
		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('Error inserrt playlist', 16, 1)
			return -1
		end
		
		insert into			cinelight_playlist_spot_xref
		select				distinct @playlist_id, 
									cinelight_spot_daily_segment.spot_id
		FROM 				cinelight_spot_daily_segment,   
									cinelight_spot,   
									cinelight,   
									cinelight_dsn_player_xref  
		WHERE 			cinelight_spot_daily_segment.spot_id = cinelight_spot.spot_id
		and  					cinelight_spot.cinelight_id = cinelight.cinelight_id
		and  					cinelight.cinelight_id = cinelight_dsn_player_xref.cinelight_id
		and  					cinelight_spot.screening_date = @screening_date
		AND  					cinelight_dsn_player_xref.player_name = @player_name
		and						cinelight_spot_daily_segment.start_date <= @start_date2   
		and						cinelight_spot_daily_segment.end_date  >=  @end_date2
	
		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('Error insert playlist spot_xref', 16, 1)
			return -1
		end
		
	fetch playlist_csr into @start_date2, @end_date2 
end

commit transaction
select * from cinelight_playlist where screening_Date = @screening_date and player_name = @player_name

return 0
GO
