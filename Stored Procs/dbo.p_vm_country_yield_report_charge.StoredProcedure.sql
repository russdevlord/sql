/****** Object:  StoredProcedure [dbo].[p_vm_country_yield_report_charge]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_country_yield_report_charge]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_country_yield_report_charge]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_vm_country_yield_report_charge]	@country_code			char(1), 
														@accounting_period		datetime

as

declare		@prior_accounting_period			datetime,
			@prior_year_start					datetime,
			@year_start							datetime
			
set nocount on			

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

select		country.country_code, 
			country_name,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard') as this_month_util,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard') as prior_month_util,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard') as this_ytd_util,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard') as prior_ytd_util,			

			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard') as this_month_attendance_util,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard') as prior_month_attendance_util,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard') as this_ytd_attendance_util,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard') as prior_ytd_attendance_util,			

			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as this_month_util_top_1,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as prior_month_util_top_1,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as this_ytd_util_top_1,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as prior_ytd_util_top_1,			

			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as this_month_attendance_util_top_1,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as prior_month_attendance_util_top_1,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as this_ytd_attendance_util_top_1,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard' and country_top_1 = 'Y') as prior_ytd_attendance_util_top_1,			

			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as this_month_util_top_2,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as prior_month_util_top_2,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as this_ytd_util_top_2,
			(select	case when sum(time_avail) > 0 then sum(duration) / sum(time_avail) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as prior_ytd_util_top_2,			

			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as this_month_attendance_util_top_2,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as prior_month_attendance_util_top_2,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as this_ytd_attendance_util_top_2,
			(select	case when sum(time_avail) > 0 then sum(duration / 30 * attendance) / sum(time_avail / 30 * attendance) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		movie_type = 'Standard' and country_top_2 = 'Y') as prior_ytd_attendance_util_top_2,			

			(select	sum(agency_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_revenue,			
			(select	sum(direct_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_revenue,			
			(select	sum(showcase_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_revenue,			
			(select	sum(cineads_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as cineads_revenue,			

			(select	sum(agency_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_revenue_prior,			
			(select	sum(direct_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_revenue_prior,			
			(select	sum(showcase_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_revenue_prior,			
			(select	sum(cineads_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as cineads_revenue_prior,			

			(select	sum(agency_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_revenue_ytd,			
			(select	sum(direct_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_revenue_ytd,			
			(select	sum(showcase_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_revenue_ytd,			
			(select	sum(cineads_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cineads_revenue_ytd,			

			(select	sum(agency_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_revenue_ytd_prior,			
			(select	sum(direct_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_revenue_ytd_prior,			
			(select	sum(showcase_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_revenue_ytd_prior,			
			(select	sum(cineads_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as cineads_revenue_ytd_prior,			

			(select	case when sum(agency_spots_ffmm) > 0 then sum(agency_30sec_revenue_ffmm) / sum(agency_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_yield,			
			(select	case when sum(direct_spots_ffmm) > 0 then sum(direct_30sec_revenue_ffmm) / sum(direct_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_yield,			
			(select	case when sum(showcase_spots_ffmm) > 0 then sum(showcase_30sec_revenue_ffmm) / sum(showcase_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_yield,			
			(select	case when sum(cineads_spots_ffmm) > 0 then sum(cineads_30sec_revenue_ffmm) / sum(cineads_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as cineads_yield,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as cinema_yield,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm) + sum(cineads_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as total_yield,			

			(select	case when sum(agency_spots_ffmm) > 0 then sum(agency_30sec_revenue_ffmm) / sum(agency_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_prior_yield,			
			(select	case when sum(direct_spots_ffmm) > 0 then sum(direct_30sec_revenue_ffmm) / sum(direct_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_prior_yield,			
			(select	case when sum(showcase_spots_ffmm) > 0 then sum(showcase_30sec_revenue_ffmm) / sum(showcase_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_prior_yield,			
			(select	case when sum(cineads_spots_ffmm) > 0 then sum(cineads_30sec_revenue_ffmm) / sum(cineads_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as cineads_prior_yield,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as cinema_prior_yield,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm) + sum(cineads_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as total_prior_yield,			

			(select	case when sum(agency_spots_ffmm) > 0 then sum(agency_30sec_revenue_ffmm) / sum(agency_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_yield_ytd,			
			(select	case when sum(direct_spots_ffmm) > 0 then sum(direct_30sec_revenue_ffmm) / sum(direct_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_yield_ytd,			
			(select	case when sum(showcase_spots_ffmm) > 0 then sum(showcase_30sec_revenue_ffmm) / sum(showcase_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_yield_ytd,			
			(select	case when sum(cineads_spots_ffmm) > 0 then sum(cineads_30sec_revenue_ffmm) / sum(cineads_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cineads_yield_ytd,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cinema_yield_ytd,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm) + sum(cineads_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as total_yield_ytd,			

			(select	case when sum(agency_spots_ffmm) > 0 then sum(agency_30sec_revenue_ffmm) / sum(agency_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_yield_ytd_prior,			
			(select	case when sum(direct_spots_ffmm) > 0 then sum(direct_30sec_revenue_ffmm) / sum(direct_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_yield_ytd_prior,			
			(select	case when sum(showcase_spots_ffmm) > 0 then sum(showcase_30sec_revenue_ffmm) / sum(showcase_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_yield_ytd_prior,			
			(select	case when sum(cineads_spots_ffmm) > 0 then sum(cineads_30sec_revenue_ffmm) / sum(cineads_spots_ffmm) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as cineads_yield_ytd_prior,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as cinema_yield_ytd_prior,			
			(select	case when (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) > 0 then (sum(agency_30sec_revenue_ffmm) + sum(direct_30sec_revenue_ffmm) + sum(showcase_30sec_revenue_ffmm) + sum(cineads_30sec_revenue_ffmm)) / (sum(agency_spots_ffmm) + sum(direct_spots_ffmm) + sum(showcase_spots_ffmm) + sum(cineads_spots_ffmm)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as total_yield_ytd_prior,	
			
			(select	case when sum(attendance) > 0 then sum(agency_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard' ) as agency_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_cpm,			
			(select 	case when sum(attendance_sum) > 0 then sum(revenue_sum) / sum(attendance_sum) * 1000 else 0 end
			from		(select	sum(agency_revenue) as revenue_sum,
								sum(attendance) as attendance_sum
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = @accounting_period
						and		agency_duration <> 0
						and		movie_type = 'Standard' 
						union all
						select	sum(direct_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = @accounting_period
						and		direct_duration <> 0
						and		movie_type = 'Standard'
						union all 
						select	sum(showcase_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = @accounting_period
						and		showcase_duration <> 0
						and		movie_type = 'Standard') as temp_table) as cinema_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_prior_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_prior_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_prior_cpm,			
			(select 	case when sum(attendance_sum) > 0 then sum(revenue_sum) / sum(attendance_sum) * 1000 else 0 end
			from		(select	sum(agency_revenue) as revenue_sum,
								sum(attendance) as attendance_sum
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = @prior_accounting_period
						and		agency_duration <> 0
						and		movie_type = 'Standard' 
						union all
						select	sum(direct_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = @prior_accounting_period
						and		direct_duration <> 0
						and		movie_type = 'Standard'
						union all 
						select	sum(showcase_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = @prior_accounting_period
						and		showcase_duration <> 0
						and		movie_type = 'Standard') as temp_table) as cinema_prior_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(direct_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(showcase_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_cpm_ytd,			
			(select 	case when sum(attendance_sum) > 0 then sum(revenue_sum) / sum(attendance_sum) *1000 else 0 end
			from		(select	sum(agency_revenue) as revenue_sum,
								sum(attendance) as attendance_sum
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end between @year_start and @accounting_period
						and		agency_duration <> 0
						and		movie_type = 'Standard' 
						union all
						select	sum(direct_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end between @year_start and @accounting_period
						and		direct_duration <> 0
						and		movie_type = 'Standard'
						union all 
						select	sum(showcase_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end between @year_start and @accounting_period
						and		showcase_duration <> 0
						and		movie_type = 'Standard') as temp_table) as cinema_cpm_ytd,			

			(select	case when sum(attendance) > 0 then sum(agency_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(direct_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(showcase_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_cpm_ytd_prior,			
			(select 	case when sum(attendance_sum) > 0 then sum(revenue_sum) / sum(attendance_sum) * 1000 else 0 end
			from		(select	sum(agency_revenue) as revenue_sum,
								sum(attendance) as attendance_sum
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end between @prior_year_start and @prior_accounting_period
						and		agency_duration <> 0
						and		movie_type = 'Standard' 
						union all
						select	sum(direct_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end between @prior_year_start and @prior_accounting_period
						and		direct_duration <> 0
						and		movie_type = 'Standard'
						union all 
						select	sum(showcase_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end between @prior_year_start and @prior_accounting_period
						and		showcase_duration <> 0
						and		movie_type = 'Standard') as temp_table) as cinema_cpm_ytd_prior,			


			(select	sum(mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard') as mm_revenue,			
			(select	sum(ff_aud_revenue + ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard') as ff_revenue,			
			(select	sum(roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard' ) as roadblock_revenue,			
			(select	sum(tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard') as tap_revenue,			

			(select	sum(mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as mm_revenue_prior,			
			(select	sum(ff_aud_revenue + ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as ff_revenue_prior,			
			(select	sum(roadblock_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as roadblock_revenue_prior,			
			(select	sum(tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as tap_revenue_prior,			

			(select	sum(mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as mm_revenue_ytd,			
			(select	sum(ff_aud_revenue + ff_old_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as ff_revenue_ytd,			
			(select	sum(roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as roadblock_revenue_ytd,			
			(select	sum(tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as tap_revenue_ytd,			

			(select	sum(mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as mm_revenue_ytd_prior,			
			(select	sum(ff_aud_revenue + ff_old_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as ff_revenue_ytd_prior,			
			(select	sum(roadblock_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as roadblock_revenue_ytd_prior,			
			(select	sum(tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as tap_revenue_ytd_prior,			

			(select	case when sum(attendance) > 0 then sum(ff_aud_revenue + ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		ff_aud_duration + ff_old_total_duration <> 0
			and		movie_type = 'Standard') as ff_cpm,			
			(select	case when sum(attendance) > 0 then sum(mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		mm_total_duration <> 0
			and		movie_type = 'Standard') as mm_cpm,			
			(select	case when sum(attendance) > 0 then sum(roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		roadblock_duration <> 0
			and		movie_type = 'Standard') as roadblock_cpm,			
			(select	case when sum(attendance) > 0 then sum(tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		tap_duration <> 0
			and		movie_type = 'Standard') as tap_cpm,			

			(select	case when sum(attendance) > 0 then sum(ff_aud_revenue + ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		ff_aud_duration + ff_old_total_duration <> 0
			and		movie_type = 'Standard') as ff_prior_cpm,			
			(select	case when sum(attendance) > 0 then sum(mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		mm_total_duration <> 0
			and		movie_type = 'Standard') as mm_prior_cpm,			
			(select	case when sum(attendance) > 0 then sum(roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		roadblock_duration <> 0
			and		movie_type = 'Standard') as roadblock_prior_cpm,			
			(select	case when sum(attendance) > 0 then sum(tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		tap_duration <> 0) as tap_prior_cpm,			

			(select	case when sum(attendance) > 0 then sum(ff_aud_revenue + ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		ff_aud_duration + ff_old_total_duration <> 0
			and		movie_type = 'Standard') as ff_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		mm_total_duration <> 0) as mm_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		roadblock_duration <> 0
			and		movie_type = 'Standard') as roadblock_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		tap_duration <> 0
			and		movie_type = 'Standard') as tap_cpm_ytd,			

			(select	case when sum(attendance) > 0 then sum(ff_aud_revenue + ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		ff_aud_duration + ff_old_total_duration <> 0
			and		movie_type = 'Standard') as ff_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		mm_total_duration <> 0
			and		movie_type = 'Standard') as mm_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		roadblock_duration <> 0
			and		movie_type = 'Standard') as roadblock_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		tap_duration <> 0
			and		movie_type = 'Standard') as tap_cpm_ytd_prior,			

			(select	case when sum(mm_total_spots) > 0 then sum(mm_revenue_30seceqv) / sum(mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard') as mm_yield,			
			(select	case when (sum(ff_old_total_spots) + sum(ff_aud_spots)) > 0 then (sum(ff_old_revenue_30seceqv) + sum(ff_aud_revenue_30seceqv)) / (sum(ff_old_total_spots) + sum(ff_aud_spots)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard') as ff_yield,			
			(select	case when sum(roadblock_spots) > 0  then sum(roadblock_revenue_30seceqv) / sum(roadblock_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard' ) as roadblock_yield,			
			(select	case when sum(tap_spots) > 0 then sum(tap_revenue_30seceqv) / sum(tap_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period and		movie_type = 'Standard') as tap_yield,			

			(select	case when sum(mm_total_spots) > 0 then sum(mm_revenue_30seceqv) / sum(mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as mm_yield_prior,			
			(select	case when (sum(ff_old_total_spots) + sum(ff_aud_spots)) > 0 then (sum(ff_old_revenue_30seceqv) + sum(ff_aud_revenue_30seceqv)) / (sum(ff_old_total_spots) + sum(ff_aud_spots)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as ff_yield_prior,			
			(select	case when sum(roadblock_spots) > 0  then sum(roadblock_revenue_30seceqv) / sum(roadblock_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as roadblock_yield_prior,			
			(select	case when sum(tap_spots) > 0 then sum(tap_revenue_30seceqv) / sum(tap_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period and		movie_type = 'Standard') as tap_yield_prior,			

			(select	case when sum(mm_total_spots) > 0 then sum(mm_revenue_30seceqv) / sum(mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as mm_yield_ytd,			
			(select	case when (sum(ff_old_total_spots) + sum(ff_aud_spots)) > 0 then (sum(ff_old_revenue_30seceqv) + sum(ff_aud_revenue_30seceqv)) / (sum(ff_old_total_spots) + sum(ff_aud_spots)) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as ff_yield_ytd,			
			(select	case when sum(roadblock_spots) > 0  then sum(roadblock_revenue_30seceqv) / sum(roadblock_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as roadblock_yield_ytd,			
			(select	case when sum(tap_spots) > 0 then sum(tap_revenue_30seceqv) / sum(tap_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period and		movie_type = 'Standard') as tap_yield_ytd,			

			(select	case when sum(mm_total_spots) > 0 then sum(mm_revenue_30seceqv) / sum(mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as mm_yield_ytd_prior,			
			(select	case when (sum(ff_old_total_spots) + sum(ff_aud_spots)) > 0 then (sum(ff_old_revenue_30seceqv) + sum(ff_aud_revenue_30seceqv)) / (sum(ff_old_total_spots) + sum(ff_aud_spots)) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as ff_yield_ytd_prior,			
			(select	case when sum(roadblock_spots) > 0  then sum(roadblock_revenue_30seceqv) / sum(roadblock_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as roadblock_yield_ytd_prior,			
			(select	case when sum(tap_spots) > 0 then sum(tap_revenue_30seceqv) / sum(tap_spots) else 0 end
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period and		movie_type = 'Standard') as tap_yield_ytd_prior,			
/* business unit and prodcut splits start here*/
			(select	sum(agency_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_roadblock_revenue,			
			(select	sum(direct_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_roadblock_revenue,			
			(select	sum(showcase_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_roadblock_revenue,			

			(select	sum(agency_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_roadblock_revenue_prior,			
			(select	sum(direct_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_roadblock_revenue_prior,			
			(select	sum(showcase_roadblock_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_roadblock_revenue_prior,			

			(select	sum(agency_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_roadblock_revenue_ytd,			
			(select	sum(direct_roadblock_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_roadblock_revenue_ytd,			
			(select	sum(showcase_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_roadblock_revenue_ytd,			

			(select	sum(agency_roadblock_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_roadblock_revenue_ytd_prior,			
			(select	sum(direct_roadblock_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_roadblock_revenue_ytd_prior,			
			(select	sum(showcase_roadblock_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_roadblock_revenue_ytd_prior,			
			
			(select	sum(agency_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_tap_revenue,			
			(select	sum(direct_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_tap_revenue,			
			(select	sum(showcase_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_tap_revenue,			

			(select	sum(agency_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_tap_revenue_prior,			
			(select	sum(direct_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_tap_revenue_prior,			
			(select	sum(showcase_tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_tap_revenue_prior,			

			(select	sum(agency_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_tap_revenue_ytd,			
			(select	sum(direct_tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_tap_revenue_ytd,			
			(select	sum(showcase_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_tap_revenue_ytd,			

			(select	sum(agency_tap_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_tap_revenue_ytd_prior,			
			(select	sum(direct_tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_tap_revenue_ytd_prior,			
			(select	sum(showcase_tap_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_tap_revenue_ytd_prior,			

			(select	sum(agency_ff_aud_revenue + agency_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_ff_aud_revenue,			
			(select	sum(direct_ff_aud_revenue + direct_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_ff_aud_revenue,			
			(select	sum(showcase_ff_aud_revenue + showcase_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_ff_aud_revenue,			

			(select	sum(agency_ff_aud_revenue + agency_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_ff_aud_revenue_prior,			
			(select	sum(direct_ff_aud_revenue + direct_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_ff_aud_revenue_prior,			
			(select	sum(showcase_ff_aud_revenue + showcase_ff_old_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_ff_aud_revenue_prior,			

			(select	sum(agency_ff_aud_revenue + agency_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_ff_aud_revenue_ytd,			
			(select	sum(direct_ff_aud_revenue + direct_ff_old_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_ff_aud_revenue_ytd,			
			(select	sum(showcase_ff_aud_revenue + showcase_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_ff_aud_revenue_ytd,			

			(select	sum(agency_ff_aud_revenue + agency_ff_old_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_ff_aud_revenue_ytd_prior,			
			(select	sum(direct_ff_aud_revenue + direct_ff_old_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_ff_aud_revenue_ytd_prior,			
			(select	sum(showcase_ff_aud_revenue + showcase_ff_old_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_ff_aud_revenue_ytd_prior,			
			
			(select	sum(agency_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_mm_revenue,			
			(select	sum(direct_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_mm_revenue,			
			(select	sum(showcase_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_mm_revenue,			

			(select	sum(agency_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_mm_revenue_prior,			
			(select	sum(direct_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_mm_revenue_prior,			
			(select	sum(showcase_mm_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_mm_revenue_prior,			

			(select	sum(agency_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_mm_revenue_ytd,			
			(select	sum(direct_mm_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_mm_revenue_ytd,			
			(select	sum(showcase_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_mm_revenue_ytd,			

			(select	sum(agency_mm_revenue)
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_mm_revenue_ytd_prior,			
			(select	sum(direct_mm_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_mm_revenue_ytd_prior,			
			(select	sum(showcase_mm_revenue) 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_mm_revenue_ytd_prior,			

			(select	case when sum(agency_roadblock_spots) > 0 then sum(agency_roadblock_revenue_30seceqv) / sum(agency_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_roadblock_yield,			
			(select	case when sum(direct_roadblock_spots) > 0 then sum(direct_roadblock_revenue_30seceqv) / sum(direct_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_roadblock_yield,			
			(select	case when sum(showcase_roadblock_spots) > 0 then sum(showcase_roadblock_revenue_30seceqv) / sum(showcase_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_roadblock_yield,			

			(select	case when sum(agency_roadblock_spots) > 0 then sum(agency_roadblock_revenue_30seceqv) / sum(agency_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_prior_roadblock_yield,			
			(select	case when sum(direct_roadblock_spots) > 0 then sum(direct_roadblock_revenue_30seceqv) / sum(direct_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_prior_roadblock_yield,			
			(select	case when sum(showcase_roadblock_spots) > 0 then sum(showcase_roadblock_revenue_30seceqv) / sum(showcase_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_prior_roadblock_yield,			

			(select	case when sum(agency_roadblock_spots) > 0 then sum(agency_roadblock_revenue_30seceqv) / sum(agency_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_roadblock_yield_ytd,			
			(select	case when sum(direct_roadblock_spots) > 0 then sum(direct_roadblock_revenue_30seceqv) / sum(direct_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_roadblock_yield_ytd,			
			(select	case when sum(showcase_roadblock_spots) > 0 then sum(showcase_roadblock_revenue_30seceqv) / sum(showcase_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_roadblock_yield_ytd,			

			(select	case when sum(agency_roadblock_spots) > 0 then sum(agency_roadblock_revenue_30seceqv) / sum(agency_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_roadblock_yield_ytd_prior,			
			(select	case when sum(direct_roadblock_spots) > 0 then sum(direct_roadblock_revenue_30seceqv) / sum(direct_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_roadblock_yield_ytd_prior,			
			(select	case when sum(showcase_roadblock_spots) > 0 then sum(showcase_roadblock_revenue_30seceqv) / sum(showcase_roadblock_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_roadblock_yield_ytd_prior,			

			(select	case when sum(agency_tap_spots) > 0 then sum(agency_tap_revenue_30seceqv) / sum(agency_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_tap_yield,			
			(select	case when sum(direct_tap_spots) > 0 then sum(direct_tap_revenue_30seceqv) / sum(direct_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_tap_yield,			
			(select	case when sum(showcase_tap_spots) > 0 then sum(showcase_tap_revenue_30seceqv) / sum(showcase_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_tap_yield,			

			(select	case when sum(agency_tap_spots) > 0 then sum(agency_tap_revenue_30seceqv) / sum(agency_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_prior_tap_yield,			
			(select	case when sum(direct_tap_spots) > 0 then sum(direct_tap_revenue_30seceqv) / sum(direct_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_prior_tap_yield,			
			(select	case when sum(showcase_tap_spots) > 0 then sum(showcase_tap_revenue_30seceqv) / sum(showcase_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_prior_tap_yield,			

			(select	case when sum(agency_tap_spots) > 0 then sum(agency_tap_revenue_30seceqv) / sum(agency_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_tap_yield_ytd,			
			(select	case when sum(direct_tap_spots) > 0 then sum(direct_tap_revenue_30seceqv) / sum(direct_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_tap_yield_ytd,			
			(select	case when sum(showcase_tap_spots) > 0 then sum(showcase_tap_revenue_30seceqv) / sum(showcase_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_tap_yield_ytd,			

			(select	case when sum(agency_tap_spots) > 0 then sum(agency_tap_revenue_30seceqv) / sum(agency_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_tap_yield_ytd_prior,			
			(select	case when sum(direct_tap_spots) > 0 then sum(direct_tap_revenue_30seceqv) / sum(direct_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_tap_yield_ytd_prior,			
			(select	case when sum(showcase_tap_spots) > 0 then sum(showcase_tap_revenue_30seceqv) / sum(showcase_tap_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_tap_yield_ytd_prior,			

			(select	case when sum(agency_ff_aud_spots + agency_ff_old_total_spots) > 0 then sum(agency_ff_aud_revenue_30seceqv + agency_ff_old_revenue_30seceqv) / sum(agency_ff_aud_spots + agency_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_ff_aud_yield,			
			(select	case when sum(direct_ff_aud_spots + direct_ff_old_total_spots) > 0 then sum(direct_ff_aud_revenue_30seceqv + direct_ff_old_revenue_30seceqv) / sum(direct_ff_aud_spots + direct_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_ff_aud_yield,			
			(select	case when sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) > 0 then sum(showcase_ff_aud_revenue_30seceqv + showcase_ff_old_revenue_30seceqv) / sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_ff_aud_yield,			

			(select	case when sum(agency_ff_aud_spots + agency_ff_old_total_spots) > 0 then sum(agency_ff_aud_revenue_30seceqv + agency_ff_old_revenue_30seceqv) / sum(agency_ff_aud_spots + agency_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_prior_ff_aud_yield,			
			(select	case when sum(direct_ff_aud_spots + direct_ff_old_total_spots) > 0 then sum(direct_ff_aud_revenue_30seceqv + direct_ff_old_revenue_30seceqv) / sum(direct_ff_aud_spots + direct_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_prior_ff_aud_yield,			
			(select	case when sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) > 0 then sum(showcase_ff_aud_revenue_30seceqv + showcase_ff_old_revenue_30seceqv) / sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_prior_ff_aud_yield,			

			(select	case when sum(agency_ff_aud_spots + agency_ff_old_total_spots) > 0 then sum(agency_ff_aud_revenue_30seceqv + agency_ff_old_revenue_30seceqv) / sum(agency_ff_aud_spots + agency_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_ff_aud_yield_ytd,			
			(select	case when sum(direct_ff_aud_spots + direct_ff_old_total_spots) > 0 then sum(direct_ff_aud_revenue_30seceqv + direct_ff_old_revenue_30seceqv) / sum(direct_ff_aud_spots + direct_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_ff_aud_yield_ytd,			
			(select	case when sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) > 0 then sum(showcase_ff_aud_revenue_30seceqv + showcase_ff_old_revenue_30seceqv) / sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_ff_aud_yield_ytd,			

			(select	case when sum(agency_ff_aud_spots + agency_ff_old_total_spots) > 0 then sum(agency_ff_aud_revenue_30seceqv + agency_ff_old_revenue_30seceqv) / sum(agency_ff_aud_spots + agency_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_ff_aud_yield_ytd_prior,			
			(select	case when sum(direct_ff_aud_spots + direct_ff_old_total_spots) > 0 then sum(direct_ff_aud_revenue_30seceqv + direct_ff_old_revenue_30seceqv) / sum(direct_ff_aud_spots + direct_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_ff_aud_yield_ytd_prior,			
			(select	case when sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) > 0 then sum(showcase_ff_aud_revenue_30seceqv + showcase_ff_old_revenue_30seceqv) / sum(showcase_ff_aud_spots + showcase_ff_old_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_ff_aud_yield_ytd_prior,			
			
			(select	case when sum(agency_mm_total_spots) > 0 then sum(agency_mm_revenue_30seceqv) / sum(agency_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as agency_mm_yield,			
			(select	case when sum(direct_mm_total_spots) > 0 then sum(direct_mm_revenue_30seceqv) / sum(direct_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as direct_mm_yield,			
			(select	case when sum(showcase_mm_total_spots) > 0 then sum(showcase_mm_revenue_30seceqv) / sum(showcase_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period) as showcase_mm_yield,			

			(select	case when sum(agency_mm_total_spots) > 0 then sum(agency_mm_revenue_30seceqv) / sum(agency_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as agency_prior_mm_yield,			
			(select	case when sum(direct_mm_total_spots) > 0 then sum(direct_mm_revenue_30seceqv) / sum(direct_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as direct_prior_mm_yield,			
			(select	case when sum(showcase_mm_total_spots) > 0 then sum(showcase_mm_revenue_30seceqv) / sum(showcase_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period) as showcase_prior_mm_yield,			

			(select	case when sum(agency_mm_total_spots) > 0 then sum(agency_mm_revenue_30seceqv) / sum(agency_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as agency_mm_yield_ytd,			
			(select	case when sum(direct_mm_total_spots) > 0 then sum(direct_mm_revenue_30seceqv) / sum(direct_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as direct_mm_yield_ytd,			
			(select	case when sum(showcase_mm_total_spots) > 0 then sum(showcase_mm_revenue_30seceqv) / sum(showcase_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period) as showcase_mm_yield_ytd,			

			(select	case when sum(agency_mm_total_spots) > 0 then sum(agency_mm_revenue_30seceqv) / sum(agency_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as agency_mm_yield_ytd_prior,			
			(select	case when sum(direct_mm_total_spots) > 0 then sum(direct_mm_revenue_30seceqv) / sum(direct_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as direct_mm_yield_ytd_prior,			
			(select	case when sum(showcase_mm_total_spots) > 0 then sum(showcase_mm_revenue_30seceqv) / sum(showcase_mm_total_spots) else 0 end 
			from	complex_yield_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period) as showcase_mm_yield_ytd_prior,			

			(select	case when sum(attendance) > 0 then sum(agency_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard' ) as agency_roadblock_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_roadblock_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_roadblock_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_prior_roadblock_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_prior_roadblock_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_prior_roadblock_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_roadblock_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(direct_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_roadblock_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(showcase_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_roadblock_cpm_ytd,			

			(select	case when sum(attendance) > 0 then sum(agency_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_roadblock_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(direct_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_roadblock_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(showcase_roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_roadblock_cpm_ytd_prior,			

			(select	case when sum(attendance) > 0 then sum(agency_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard' ) as agency_tap_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_tap_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_tap_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_prior_tap_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_prior_tap_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_prior_tap_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_tap_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(direct_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_tap_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(showcase_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_tap_cpm_ytd,			

			(select	case when sum(attendance) > 0 then sum(agency_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_tap_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(direct_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_tap_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(showcase_tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_tap_cpm_ytd_prior,			

			(select	case when sum(attendance) > 0 then sum(agency_ff_aud_revenue + agency_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard' ) as agency_ff_aud_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_ff_aud_revenue + direct_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_ff_aud_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_ff_aud_revenue + showcase_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_ff_aud_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_ff_aud_revenue + agency_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_prior_ff_aud_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_ff_aud_revenue + direct_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_prior_ff_aud_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_ff_aud_revenue + showcase_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_prior_ff_aud_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_ff_aud_revenue + agency_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_ff_aud_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(direct_ff_aud_revenue + direct_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_ff_aud_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(showcase_ff_aud_revenue + showcase_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_ff_aud_cpm_ytd,			

			(select	case when sum(attendance) > 0 then sum(agency_ff_aud_revenue + agency_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_ff_aud_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(direct_ff_aud_revenue + direct_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_ff_aud_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(showcase_ff_aud_revenue + showcase_ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_ff_aud_cpm_ytd_prior,			
			
			(select	case when sum(attendance) > 0 then sum(agency_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard' ) as agency_mm_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_mm_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_mm_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_prior_mm_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_prior_mm_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_prior_mm_cpm,			

			(select	case when sum(attendance) > 0 then sum(agency_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_mm_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(direct_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_mm_cpm_ytd,			
			(select	case when sum(attendance) > 0 then sum(showcase_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @year_start and @accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_mm_cpm_ytd,			

			(select	case when sum(attendance) > 0 then sum(agency_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		agency_duration <> 0
			and		movie_type = 'Standard') as agency_mm_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(direct_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_mm_cpm_ytd_prior,			
			(select	case when sum(attendance) > 0 then sum(showcase_mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm_charge
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end between @prior_year_start and @prior_accounting_period
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_mm_cpm_ytd_prior,			
			
			@accounting_period as accounting_period,
			@prior_accounting_period as prior_accounting_period,
			@prior_year_start as prior_year_start,
			@year_start as year_start
from		country 
where		country_code = @country_code
group by	country_code, 
			country_name
order by	country_name

return 0
GO
