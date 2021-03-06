/****** Object:  StoredProcedure [dbo].[p_exhibitor_yield_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_exhibitor_yield_report]
GO
/****** Object:  StoredProcedure [dbo].[p_exhibitor_yield_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_exhibitor_yield_report]	@exhibitor_id			int, 
												@accounting_period		datetime

as

declare		@prior_accounting_period			datetime,
			@prior_year_start					datetime,
			@year_start							datetime
			
set nocount on			
/*sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) */
select		@prior_accounting_period = max(end_date)
from		accounting_period
where		period_no in (select period_no from accounting_period where end_date = @accounting_period)
and			end_date < @accounting_period

select		@prior_year_start = min(end_date)
from		accounting_period 
where		datepart(yy, end_date) = datepart(yy, @prior_accounting_period)
			
select		@year_start = min(end_date)
from		accounting_period 
where		datepart(yy, end_date) = datepart(yy, @accounting_period)

select		exhibitor_group_id as exhibitor_id, 
			exhibitor_name,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard') as this_month_util,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard') as prior_month_util,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard') as this_ytd_util,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard') as prior_ytd_util,			

			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard') as this_month_attendance_util,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard') as prior_month_attendance_util,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard') as this_ytd_attendance_util,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard') as prior_ytd_attendance_util,			

			(select	sum(agency_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_revenue,			
			(select	sum(direct_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_revenue,			
			(select	sum(showcase_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_revenue,			
			(select	sum(cineads_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as cineads_revenue,			

			(select	sum(agency_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_revenue_prior,			
			(select	sum(direct_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_revenue_prior,			
			(select	sum(showcase_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_revenue_prior,			
			(select	sum(cineads_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as cineads_revenue_prior,			

			(select	sum(agency_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_revenue_ytd,			
			(select	sum(direct_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_revenue_ytd,			
			(select	sum(showcase_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_revenue_ytd,			
			(select	sum(cineads_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cineads_revenue_ytd,			

			(select	sum(agency_revenue)
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_revenue_ytd_prior,			
			(select	sum(direct_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_revenue_ytd_prior,			
			(select	sum(showcase_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_revenue_ytd_prior,			
			(select	sum(cineads_revenue) 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as cineads_revenue_ytd_prior,			

			(select	case when sum(agency_duration) > 0 then sum(agency_revenue) / sum(agency_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_yield,			
			(select	case when sum(direct_duration) > 0 then sum(direct_revenue) / sum(direct_duration) * 30  else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_yield,			
			(select	case when sum(showcase_duration) > 0 then sum(showcase_revenue) / sum(showcase_duration) * 30  else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_yield,			
			(select	case when sum(cineads_duration) > 0 then sum(cineads_revenue) / sum(cineads_duration) * 30  else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as cineads_yield,			
			(select	case when (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30  else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as cinema_yield,			
			(select	case when (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(cineads_revenue) + sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30  else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as total_yield,			

			(select	case when sum(agency_duration) > 0 then sum(agency_revenue) / sum(agency_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_prior_yield,			
			(select	case when sum(direct_duration) > 0 then sum(direct_revenue) / sum(direct_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_prior_yield,			
			(select	case when sum(showcase_duration) > 0 then sum(showcase_revenue) / sum(showcase_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_prior_yield,			
			(select	case when sum(cineads_duration) > 0 then sum(cineads_revenue) / sum(cineads_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as cineads_prior_yield,			
			(select	case when (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as cinema_prior_yield,			
			(select	case when (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(cineads_revenue) + sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as total_prior_yield,			

			(select	case when sum(agency_duration) > 0 then sum(agency_revenue) / sum(agency_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_yield_ytd,			
			(select	case when sum(direct_duration) > 0 then sum(direct_revenue) / sum(direct_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_yield_ytd,			
			(select	case when sum(showcase_duration) > 0 then sum(showcase_revenue) / sum(showcase_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_yield_ytd,			
			(select	case when sum(cineads_duration) > 0 then sum(cineads_revenue) / sum(cineads_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cineads_yield_ytd,			
			(select	case when (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cinema_yield_ytd,			
			(select	case when (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(cineads_revenue) + sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as total_yield_ytd,			

			(select	case when sum(agency_duration) > 0 then sum(agency_revenue) / sum(agency_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_yield_ytd_prior,			
			(select	case when sum(direct_duration) > 0 then sum(direct_revenue) / sum(direct_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_yield_ytd_prior,			
			(select	case when sum(showcase_duration) > 0 then sum(showcase_revenue) / sum(showcase_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_yield_ytd_prior,			
			(select	case when sum(cineads_duration) > 0 then sum(cineads_revenue) / sum(cineads_duration) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as cineads_yield_ytd_prior,			
			(select	case when (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cinema_yield_ytd_prior,			
			(select	case when (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) > 0 then (sum(cineads_revenue) + sum(showcase_revenue) + sum(direct_revenue) + sum(agency_revenue)) / (sum(cineads_duration) + sum(showcase_duration) + sum(direct_duration) + sum(agency_duration)) * 30 else 0 end 
			from	complex_yield, v_exhibitor_report
			where	exhibitor_group_id = @exhibitor_id and complex_yield.exhibitor_id = v_exhibitor_report.exhibitor_id and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as total_yield_ytd_prior,	
			@accounting_period as accounting_period,
			@prior_accounting_period as prior_accounting_period,
			@prior_year_start as prior_year_start,
			@year_start as year_start
from		v_exhibitor_report 
where		exhibitor_group_id = @exhibitor_id 
group by	exhibitor_group_id, 
			exhibitor_name
order by	exhibitor_name

return 0
GO
