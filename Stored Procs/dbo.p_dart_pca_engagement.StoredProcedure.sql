/****** Object:  StoredProcedure [dbo].[p_dart_pca_engagement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_pca_engagement]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_pca_engagement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_dart_pca_engagement]		@campaign_no		int,
												@start_date			datetime,
												@end_date			datetime,
												@panels				varchar(250)
										
as

declare		@business_unit_id			int,
			@error						int,
			@StartDate					smalldatetime,
			@EndDate					smalldatetime,
			@timeofday					datetime,
			@campaign_views				numeric(12,8),
			@total_views				numeric(12,8),
			@outpost_panel_id			int
			
set nocount on

create table #engagement
(
engagement			numeric(12,8),
engagement_type		int
)

create table #petro_views
(
campaign_views			numeric(12,8),
all_camp_views			numeric(12,8)
)


select		@business_unit_id = business_unit_id
from		film_campaign
where		campaign_no = @campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: could not determine business unit', 16, 1)
	return -1
end

if @business_unit_id = 6 --retail
begin
	insert into #engagement
	select	sum(viewers) / sum(ots) as engagement, 1 as type
	from	dart_campaign_panel_actuals
	where	dart_campaign_panel_actuals.campaign_no = @campaign_no
	and		dart_campaign_panel_actuals.screening_date between  @start_date and @end_date
	and		dart_campaign_panel_actuals.outpost_panel_id in (@panels)
	union
	select	1 - (sum(viewers) / sum(ots)) as engagement, 2 as type
	from	dart_campaign_panel_actuals
	where	dart_campaign_panel_actuals.campaign_no = @campaign_no
	and		dart_campaign_panel_actuals.screening_date between  @start_date and @end_date
	and		dart_campaign_panel_actuals.outpost_panel_id in (@panels)
end
else if @business_unit_id = 7 --petro
begin
	insert	into #engagement
	select	sum(viewers) / sum(ots) as engagement, 1
	from	dart_petro_engagement
	where	campaign_no = @campaign_no
	and		screening_date between  @start_date and @end_date
	and		dart_petro_engagement.outpost_panel_id in (@panels)
	union 
	select	1 - (sum(viewers) / sum(ots)) as engagement, 2
	from	dart_petro_engagement	
	where	campaign_no = @campaign_no
	and		screening_date between  @start_date and @end_date
	and		dart_petro_engagement.outpost_panel_id in (@panels)
end

update	#engagement
set		engagement = 1.0
where	engagement_type = 1
and		engagement > 1.0


update	#engagement
set		engagement = 0.0
where	engagement_type = 2
and		engagement < 0.0

select * from #engagement
return 0
GO
