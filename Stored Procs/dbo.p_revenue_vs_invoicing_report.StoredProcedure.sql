/****** Object:  StoredProcedure [dbo].[p_revenue_vs_invoicing_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_revenue_vs_invoicing_report]
GO
/****** Object:  StoredProcedure [dbo].[p_revenue_vs_invoicing_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_revenue_vs_invoicing_report]		@start_period			datetime,
														@end_period				datetime,
														@business_units			varchar(max),
														@branches				varchar(max),
														@reps					varchar(max)

as

declare			@error			int,
				@query			nvarchar(max),
				@cols			nvarchar(max),
				@cols_select	nvarchar(max),
				@sql			nvarchar(max),
				@pre_date		datetime,
				@post_date		datetime

create table #business_units
(
	business_unit_id			int
)

create table #branches
(
	branch_code					char(1)
)

create table #campaigns
(
	campaign_no					int
)	

create table #reps
(
	rep_id						int
)	


create table #revenue
(
	campaign_no					int,
	rpttype						varchar(30),
	revenue_period				datetime,
	revenue						money
)

create table #report_data
(
	campaign_no					int,
	rpttype						varchar(30),
	period_desc					varchar(max),
	period_sort					int,
	revenue						money
)

if len(@business_units) > 0                
	insert into #business_units                
	select * from dbo.f_multivalue_parameter(@business_units,',')   

if len(@branches) > 0                
	insert into #branches                
	select * from dbo.f_multivalue_parameter(@branches,',')   

if len(@reps) > 0                
	insert into #reps                
	select * from dbo.f_multivalue_parameter(@reps,',')  

select			@pre_date = '1-jan-1900'
select			@post_date = '31-dec-3000'

insert into		#campaigns
select			distinct v_view.campaign_no
from			v_all_cinema_spots_revenue_period v_view
inner join		film_campaign on v_view.campaign_no = film_campaign.campaign_no
inner join		#business_units on film_campaign.business_unit_id = #business_units.business_unit_id
inner join		#branches on film_campaign.branch_code = #branches.branch_code
inner join		#reps on film_campaign.rep_id = #reps.rep_id
where			revenue_period between @start_period and @end_period
and				spot_status <> 'P'
group by		v_view.campaign_no
having			sum(charge_rate_sum) <> 0
union
select			distinct v_view.campaign_no
from			v_all_cinema_spots_revenue_period v_view
inner join		film_campaign on v_view.campaign_no = film_campaign.campaign_no
inner join		#business_units on film_campaign.business_unit_id = #business_units.business_unit_id
inner join		#branches on film_campaign.branch_code = #branches.branch_code
inner join		#reps on film_campaign.rep_id = #reps.rep_id
where			billing_period between @start_period and @end_period
and				spot_status <> 'P'
group by		v_view.campaign_no
having			sum(charge_rate_sum) <> 0
union
select			distinct inc_spot.campaign_no
from			inclusion_spot inc_spot
inner join		inclusion on inc_spot.inclusion_id = inclusion.inclusion_id
inner join		film_campaign on inc_spot.campaign_no = film_campaign.campaign_no
inner join		#business_units on film_campaign.business_unit_id = #business_units.business_unit_id
inner join		#branches on film_campaign.branch_code = #branches.branch_code
inner join		#reps on film_campaign.rep_id = #reps.rep_id
where			inc_spot.billing_period between @start_period and @end_period
and				inclusion_type = 28
and				spot_status <> 'P'
group by		inc_spot.campaign_no
having			sum(charge_rate) <> 0

insert into		#revenue
select			v_view.campaign_no,
				'statrev',
				revenue_period,
				sum(cost) as revenue
from			v_statrev_cinema_no_def v_view
inner join		#campaigns on v_view.campaign_no = #campaigns.campaign_no
group by		v_view.campaign_no,
				revenue_period
having			sum(cost) <> 0

insert into		#revenue
select			v_view.campaign_no,
				'invoicing',
				billing_period,
				sum(charge_rate_sum)
from			v_all_cinema_spots_revenue_period v_view
inner join		#campaigns on v_view.campaign_no = #campaigns.campaign_no
where			spot_status <> 'P'
group by		v_view.campaign_no,
				billing_period
having			sum(charge_rate_sum) <> 0

insert into		#revenue
select			inc_spot.campaign_no,
				'invoicing plans',
				inc_spot.billing_period,
				sum(charge_rate)
from			inclusion_spot inc_spot
inner join		inclusion on inc_spot.inclusion_id = inclusion.inclusion_id
inner join		#campaigns on inc_spot.campaign_no = #campaigns.campaign_no
where			inclusion_type = 28
and				spot_status <> 'P'
group by		inc_spot.campaign_no,
				inc_spot.billing_period
having			sum(charge_rate) <> 0

insert into		#report_data
select			campaign_no,
				rpttype,
				case 
					when revenue_period between @start_period and @end_period then convert(varchar(20),revenue_period, 106)
					when revenue_period < @start_period then 'Before Report'
					when revenue_period > @end_period then 'Post Report'
					else null
				end as calc_revenue_period,
				case 
					when revenue_period between @start_period and @end_period then datepart(mm,revenue_period)
					when revenue_period < @start_period then 0
					when revenue_period > @end_period then 13
					else null
				end as calc_revenue_period_sort,
				sum(revenue)
from			#revenue	
group by		campaign_no,
				rpttype,
				case 
					when revenue_period between @start_period and @end_period then convert(varchar(20),revenue_period, 106)
					when revenue_period < @start_period then 'Before Report'
					when revenue_period > @end_period then 'Post Report'
					else null
				end,
				case 
					when revenue_period between @start_period and @end_period then datepart(mm,revenue_period)
					when revenue_period < @start_period then 0
					when revenue_period > @end_period then 13
					else null
				end 

--select * from	#report_data

/*select @cols = isnull(@cols + ',','') + QUOTENAME(period_desc) 
from	(select			period_desc,
						period_sort
		from			#report_data
		group by period_desc, period_sort ) as temp_col_names
order by period_sort

select @cols_select = isnull(@cols_select + ',','') + 'isnull(' + QUOTENAME(period_desc) + ',0) as ' + QUOTENAME(period_desc)
from	(select			period_desc,
						period_sort
		from			#report_data
		group by period_desc, period_sort ) as temp_col_names
order by period_sort

--select @cols

--select @sql = 'fred'
--*select @sql

select			@sql = '
select			campaign_no, rpttype, ' + @cols_select + '
from			(select			campaign_no,
								rpttype,
								period_desc,
								sum(isnull(revenue,0)) as revenue
				from			#report_data
				group by		campaign_no,
								rpttype,
								period_desc) as pivot_temp
pivot	(
		sum(revenue) for period_desc in (' + @cols + ')
		) as pivotresult
order by campaign_no, rpttype'

exec(@sql)*/
--print @sql

select #report_data.*, product_desc from #report_data inner join film_campaign on #report_data.campaign_no = film_campaign.campaign_no
return 0
GO
