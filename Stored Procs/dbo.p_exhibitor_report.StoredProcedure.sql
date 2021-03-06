/****** Object:  StoredProcedure [dbo].[p_exhibitor_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_exhibitor_report]
GO
/****** Object:  StoredProcedure [dbo].[p_exhibitor_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_exhibitor_report]		@revenue_period				datetime,
																			@country_code					char(1)

as

declare			@error						int,
						@product_id				int,
						@product_desc			varchar(30),
						@start_period			datetime,
						@end_period				datetime,
						@previous_start		datetime,
						@previous_end			datetime,
						@period_group			int,
						@period_rank			int
						
set nocount on						
						
create table #exhibitor_report_details_yield
(
	period_desc					varchar(100)				not null,
	period_group					int								not null,
	period_rank					int								not null,
	exhibitor_name				varchar(50)				not null,
	exhibitor_sort				int								not null,
	product_type					varchar(50)				not null,
	product_sort					int								not null,
	revenue							money							not null,
	no_spots							numeric(18,6)				not null,
	spot_yield						numeric(18,6)				not null,
	utilisation						numeric(18,6)				not null,
	cpm									numeric(18,6)				not null
)	
create table #periods
(
	start_period					datetime						not null,
	end_period						datetime						not null,
	period_group					int								not null,
	period_rank					int								not null
)

select			@end_period = @revenue_period

select			@start_period = min(end_date)
from			accounting_period
where			datepart(yy, @revenue_period) = datepart(yy, calendar_end)

select			@previous_end = max(end_date)
from			accounting_period
where			end_date < @revenue_period
and				period_no in (select period_no from accounting_period where end_date = @revenue_period)

select			@previous_start = min(end_date)
from			accounting_period
where			datepart(yy, @previous_end) = datepart(yy, calendar_end)


insert into #periods values (@end_period, @end_period, 1, 1)
insert into #periods values (@start_period, @end_period, 2, 4)
insert into #periods values (@previous_end, @previous_end, 1, 2)
insert into #periods values (@previous_start, @previous_end, 2, 5)

declare	product_csr cursor for
select		product_id,
				product_desc,
				start_period,
				end_period,
				period_group,
				period_rank
from		film_campaign_pca_product,
				#periods
where		product_id <> 5				
order by product_id						
for			read only

open product_csr
fetch product_csr into @product_id,  @product_desc, @start_period, @end_period, @period_group, @period_rank
while(@@fetch_status = 0)
begin

	if @product_id = 1 --follow film
	begin
		insert into	#exhibitor_report_details_yield
		select			case when @start_period =  @end_period then convert(varchar(20), @start_period, 106) else convert(varchar(20), @start_period, 106) + ' - ' + convert(varchar(20), @end_period, 106) end,
							@period_group, 
							@period_rank,
							exhibitor_name,
							exhibitor_id,
							@product_desc,
							@product_id,
							sum(ff_aud_revenue),
							sum(ff_aud_spots),
							sum(ff_aud_revenue) / sum(ff_aud_spots),
							sum(ff_aud_duration) / sum(time_avail),
							sum(ff_aud_revenue) / sum(attendance) * 1000
		from			complex_yield_charge
		where			benchmark_end between @start_period and @end_period
		--and				movie_type= 'Standard'
		and				country_code = @country_code
		group by		exhibitor_name,
							exhibitor_id
		having			sum(ff_aud_spots) > 0							
		and				sum(attendance) > 0 
		
	end					
	else if  @product_id = 2 --roadblock
	begin
		insert into	#exhibitor_report_details_yield
		select			case when @start_period =  @end_period then convert(varchar(20), @start_period, 106) else convert(varchar(20), @start_period, 106) + ' - ' + convert(varchar(20), @end_period, 106) end,
							@period_group, 
							@period_rank,
							exhibitor_name,
							exhibitor_id,
							@product_desc,
							@product_id,
							sum(roadblock_revenue),
							sum(roadblock_spots),
							sum(roadblock_revenue) / sum(roadblock_spots),
							sum(roadblock_duration) / sum(time_avail),
							sum(roadblock_revenue) / sum(attendance) * 1000		  
		from			complex_yield_charge
		where			benchmark_end between @start_period and @end_period
		--and				movie_type= 'Standard'
		and				country_code = @country_code
		group by		exhibitor_name,
							exhibitor_id
		having			sum(roadblock_spots) > 0				
		and				sum(attendance) > 0 
		
		
	end					
	else if  @product_id = 3 --movie mix
	begin
		insert into	#exhibitor_report_details_yield
		select			case when @start_period =  @end_period then convert(varchar(20), @start_period, 106) else convert(varchar(20), @start_period, 106) + ' - ' + convert(varchar(20), @end_period, 106) end,
							@period_group, 
							@period_rank,
							exhibitor_name,
							exhibitor_id,
							@product_desc,
							@product_id,
							sum(mm_revenue),
							sum(mm_total_spots),
							sum(mm_revenue) / sum(mm_total_spots),
							sum(mm_total_duration) / sum(time_avail),
							sum(mm_revenue) / sum(attendance) * 1000		  
		from			complex_yield_charge
		where			benchmark_end between @start_period and @end_period
		--and				movie_type= 'Standard'
		and				country_code = @country_code
		group by		exhibitor_name,
							exhibitor_id
		having			sum(mm_total_spots) > 0							
		and				sum(attendance) > 0 
		
		
	end					
	else if  @product_id = 4 --tap
	begin
		insert into	#exhibitor_report_details_yield
		select			case when @start_period =  @end_period then convert(varchar(20), @start_period, 106) else convert(varchar(20), @start_period, 106) + ' - ' + convert(varchar(20), @end_period, 106) end,
							@period_group, 
							@period_rank,
							exhibitor_name,
							exhibitor_id,
							@product_desc,
							@product_id,
							sum(tap_revenue),
							sum(tap_spots),
							sum(tap_revenue) / sum(tap_spots),
							sum(tap_duration) / sum(time_avail)	,
							sum(tap_revenue) / sum(attendance) * 1000		 
		from			complex_yield_charge
		where			benchmark_end between @start_period and @end_period
		--and				movie_type= 'Standard'
		and				country_code = @country_code
		group by		exhibitor_name,
							exhibitor_id
		having			sum(tap_spots) > 0 
		and				sum(attendance) > 0 
		
		
	end					

	fetch product_csr into @product_id,  @product_desc, @start_period, @end_period, @period_group, @period_rank
end

declare	period_csr cursor for
select		start_period,
				end_period,
				period_group,
				period_rank
from		#periods
order by period_rank						
for			read only

open period_csr
fetch period_csr into @start_period, @end_period, @period_group, @period_rank
while(@@fetch_status = 0)
begin
	
	insert into	#exhibitor_report_details_yield
	select			case when @start_period =  @end_period then convert(varchar(20), @start_period, 106) else convert(varchar(20), @start_period, 106) + ' - ' + convert(varchar(20), @end_period, 106) end,
						@period_group, 
						@period_rank,
						exhibitor_name,
						exhibitor_id,
						'Exhibitor Total',
						10,
						sum(total_revenue),
						sum(total_spots),
						sum(tap_revenue) / sum(total_spots),
						sum(duration) / sum(time_avail)	,
						sum(total_revenue) / sum(attendance) * 1000		 
	from			complex_yield_charge
	where			benchmark_end between @start_period and @end_period
	--and				movie_type= 'Standard'
	and				country_code = @country_code
	group by		exhibitor_name,
						exhibitor_id
	having			sum(total_spots) > 0 
	and				sum(attendance) > 0 
	
	fetch period_csr into @start_period, @end_period, @period_group, @period_rank
end	

insert into	#exhibitor_report_details_yield
select			current_period.period_desc + ' vs. ' + previous_period.period_desc,
					current_period.period_group, 
					previous_period.period_rank + 1,
					current_period.exhibitor_name,
					current_period.exhibitor_sort,
					current_period.product_type,
					current_period.product_sort,
					current_period.revenue - previous_period.revenue,
					current_period.no_spots - previous_period.no_spots,
					current_period.spot_yield - previous_period.spot_yield,
					current_period.utilisation - previous_period.utilisation,
					current_period.cpm - previous_period.cpm
from			#exhibitor_report_details_yield current_period,
					#exhibitor_report_details_yield previous_period
where			current_period.period_group = previous_period.period_group
and				current_period.exhibitor_sort = previous_period.exhibitor_sort
and				current_period.product_sort = previous_period.product_sort
and				current_period.period_group = 1
and				current_period.period_rank = 1
and				previous_period.period_rank = 2

insert into	#exhibitor_report_details_yield
select			current_period.period_desc + ' vs. ' + previous_period.period_desc,
					current_period.period_group, 
					previous_period.period_rank + 1,
					current_period.exhibitor_name,
					current_period.exhibitor_sort,
					current_period.product_type,
					current_period.product_sort,
					current_period.revenue - previous_period.revenue,
					current_period.no_spots - previous_period.no_spots,
					current_period.spot_yield - previous_period.spot_yield,
					current_period.utilisation - previous_period.utilisation,
					current_period.cpm - previous_period.cpm
from			#exhibitor_report_details_yield current_period,
					#exhibitor_report_details_yield previous_period
where			current_period.period_group = previous_period.period_group
and				current_period.exhibitor_sort = previous_period.exhibitor_sort
and				current_period.product_sort = previous_period.product_sort
and				current_period.period_group = 2
and				current_period.period_rank = 4
and				previous_period.period_rank = 5
										
select * from #exhibitor_report_details_yield

return 0
GO
