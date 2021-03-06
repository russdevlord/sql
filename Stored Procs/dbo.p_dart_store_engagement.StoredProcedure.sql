/****** Object:  StoredProcedure [dbo].[p_dart_store_engagement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_store_engagement]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_store_engagement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_dart_store_engagement]		@screening_date		datetime
												
as

declare		@error								int,
					@StartDate						smalldatetime,
					@EndDate							smalldatetime,
					@timeofday						datetime,
					@campaign_views				numeric(12,8),
					@total_views						numeric(12,8),
					@campaign_no					int,
					@outpost_panel_id			int
			
set nocount on

create table #petro_views
(
campaign_no				int,
outpost_panel_id		int,
campaign_views			numeric(12,8),
all_camp_views			numeric(12,8)
)

declare		campaign_csr cursor for
select			distinct film_campaign.campaign_no 
from			film_campaign,
					dart_campaign_panel_actuals
where			film_campaign.campaign_no = dart_campaign_panel_actuals.campaign_no
and				business_unit_id = 7
--and				film_campaign.campaign_no = 208762
and				dart_campaign_panel_actuals.screening_date = @screening_date
order by		campaign_no
for				read only

SET @StartDate = @screening_date
SET @EndDate = dateadd(wk, 1, @screening_date)

create table #times
(
min_time_of_day		datetime
)

SET @StartDate = DATEADD(minute,-DATEPART(minute,@StartDate),@StartDate)
SET @EndDate = DATEADD(minute,-DATEPART(minute,@EndDate),@EndDate)

;WITH dart_5min_table AS
(
SELECT 0 i, @startdate AS min_time_of_day
UNION ALL
SELECT i + 5, DATEADD(minute, i, @startdate )
FROM dart_5min_table 
WHERE DATEADD(minute, i, @startdate ) <= @enddate
)

insert into #times
SELECT DISTINCT min_time_of_day FROM dart_5min_table
OPTION (MAXRECURSION 32767)

delete	dart_petro_engagement
where	screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to delete existing records', 16, 1)
	return -1
end

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status = 0)
begin

	print @campaign_no
	
	declare		ots_time_csr cursor for
	select			distinct min_time_of_day,
						outpost_panel_id
	from			#times,
						dart_dcmedia_player_pop	
	where			campaign_no = @campaign_no
	and				impression_datetime between min_time_of_day and dateadd(ms, -1, dateadd(mi, 5, min_time_of_day))
	order by		min_time_of_day
	for				read only
	
	open ots_time_csr
	fetch ots_time_csr into @timeofday, @outpost_panel_id
	while(@@fetch_status = 0)
	begin
		
		print @timeofday
		--print @outpost_panel_id
		
		select	@campaign_views = sum(isnull(viewers,0))
		from	dart_campaign_panel_actuals_detailed
		where	time_of_day between @timeofday and dateadd(ms, -1, dateadd(mi, 5, @timeofday))
		and		outpost_panel_id = @outpost_panel_id
		and		campaign_no = @campaign_no
		
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error: Failed to get viewers', 16, 1)
			return -1
		end
		
		select	@total_views =  sum(isnull(viewers,0))
		from	dart_campaign_panel_actuals_detailed
		where	time_of_day between @timeofday and dateadd(ms, -1, dateadd(mi, 5, @timeofday))
		and		outpost_panel_id = @outpost_panel_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error: Failed to get ots', 16, 1)
			return -1
		end

		if @campaign_views > 1
			select @campaign_views = 1
			
		if @total_views > 1
			select @total_views = 1
		
		if @total_views > 0 
		begin
			insert into #petro_views values (@campaign_no, @outpost_panel_id, isnull(@campaign_views,0), isnull(@total_views,0))
		
			select @error = @@error
			if @error <> 0
			begin
				raiserror ('Error: Failed to insert row', 16, 1)
				return -1
			end
		end
		
		fetch ots_time_csr into @timeofday, @outpost_panel_id
	end
	
	close ots_time_csr
	deallocate ots_time_csr

	fetch campaign_csr into @campaign_no
end

insert into dart_petro_engagement 
select campaign_no, outpost_panel_id, @screening_date, sum(isnull(campaign_views,0)), sum(isnull(all_camp_views,0)) 
from #petro_views 
group by campaign_no, outpost_panel_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to insert row', 16, 1)
	return -1
end		

delete #petro_views

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to insert row', 16, 1)
	return -1
end

return 0
GO
