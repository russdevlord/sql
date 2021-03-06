/****** Object:  StoredProcedure [dbo].[p_dart_store_tower_ots]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_store_tower_ots]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_store_tower_ots]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_dart_store_tower_ots]		@screening_date		datetime
												
as

declare		@error									int,
					@start_time							datetime,
					@end_time								datetime,
					@timeofday							datetime,
					@campaign_views					numeric(12,8),
					@total_views							numeric(12,8),
					@ots_count							numeric(12,8),
					@campaign_no						int,
					@outpost_panel_id				int,
					@dart_demographics_id		int,
					@package_id							int
			
set nocount on

declare		tower_ots_panel_csr cursor for
select			campaign_no,
					outpost_panel_id,
					time_of_day, --this is an hourly amount
					dateadd(ss, -1, dateadd(hh, 1, time_of_day)),
					sum(viewers) as viewers,
					dart_demographics_id,
					package_id
from			dart_campaign_panel_actuals_detailed
where			dart_campaign_panel_actuals_detailed.country_code = 'Z'
and				dart_campaign_panel_actuals_detailed.screening_date = @screening_date
group by		campaign_no,
					outpost_panel_id,
					time_of_day ,
					dart_demographics_id,
					package_id
order by		campaign_no,
					outpost_panel_id,
					time_of_day,
					dart_demographics_id,
					package_id
for				read only

open tower_ots_panel_csr
fetch tower_ots_panel_csr into @campaign_no, @outpost_panel_id, @start_time, @end_time, @campaign_views, @dart_demographics_id, @package_id
while(@@fetch_status = 0)
begin
	
	select	@total_views =  sum(isnull(viewers,0))
	from	dart_campaign_panel_actuals_detailed
	where	time_of_day between @start_time and @end_time
	and		outpost_panel_id = @outpost_panel_id
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error: Failed to get total viewers', 16, 1)
		return -1
	end

	if @total_views <> 0 
	begin
		select		@ots_count = sum(isnull(ots_count,0))
		from		dart_quividi_ots
		where		start_time between @start_time and @end_time
		and			outpost_panel_id = @outpost_panel_id
		
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error: Failed to get ots', 16, 1)
			return -1
		end		
		
		if @ots_count <> 0
		begin
			update		dart_campaign_panel_actuals_detailed
			set				ots = @ots_count * @campaign_views / @total_views
			where			campaign_no = @campaign_no
			and				package_id = @package_id
			and				outpost_panel_id = @outpost_panel_id
			and				time_of_day = @start_time
			and				dart_demographics_id = @dart_demographics_id
			
			select @error = @@error
			if @error <> 0
			begin
				raiserror ('Error: Failed to update ots', 16, 1)
				return -1
			end		
						
		end
	end
	fetch tower_ots_panel_csr into @campaign_no, @outpost_panel_id, @start_time, @end_time, @campaign_views, @dart_demographics_id, @package_id
end

update		dart_campaign_panel_actuals
set				ots = temp_table.ots
from			(select		campaign_no, 
										package_id, 
										screening_date, 
										dart_demographics_id,
										outpost_panel_id,
										sum(ots) as ots
						from		dart_campaign_panel_actuals_detailed 
						where		country_code = 'Z' 
						and			screening_date = @screening_date
						group by	campaign_no, 
										package_id, 
										screening_date, 
										outpost_panel_id,
										dart_demographics_id) as temp_table
where			dart_campaign_panel_actuals.campaign_no = temp_table.campaign_no
and				dart_campaign_panel_actuals.package_id = temp_table.package_id
and				dart_campaign_panel_actuals.outpost_panel_id = temp_table.outpost_panel_id
and				dart_campaign_panel_actuals.screening_date = temp_table.screening_date
and				dart_campaign_panel_actuals.dart_demographics_id = temp_table.dart_demographics_id
and				dart_campaign_panel_actuals.country_code = 'Z'
and				dart_campaign_panel_actuals.screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to update ots', 16, 1)
	return -1
end		

return 0
GO
