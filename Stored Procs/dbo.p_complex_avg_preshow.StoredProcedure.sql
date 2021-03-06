/****** Object:  StoredProcedure [dbo].[p_complex_avg_preshow]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_avg_preshow]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_avg_preshow]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_complex_avg_preshow]	@exhibitor_id			int,
											@start_period			datetime,
											@end_period				datetime,
											@top_movie				int
								
as

set nocount on

select		film_market.film_market_no,
			film_market.film_market_desc,
			complex.complex_id, 
			complex_name,
			(select	avg(agency_duration)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and  @end_period
			and		movie_type = 'Standard'
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as avg_agency_duration,
			(select	avg(direct_duration) + avg(showcase_duration)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and  @end_period
			and		movie_type = 'Standard'
			and		premium_cinema = 'N'
			and		((@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as avg_direct_duration,
			(select	avg(cineads_duration)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and  @end_period
			and		movie_type = 'CINEads'
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as avg_cineads_duration,
			(select	sum(total_revenue)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and @end_period
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as total_revenue_ytd,			
			@end_period as accounting_period,
			@start_period as year_start,
			(select	max(agency_duration + direct_duration + showcase_duration + cineads_duration)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and  @end_period
			and		movie_type = 'Standard'
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as max_duration,
			(select	sum(agency_revenue)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and @end_period
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as total_agency_ytd,
			(select	sum(direct_revenue) + sum(showcase_revenue)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and @end_period
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as total_direct_ytd,
			(select	sum(cineads_revenue)
			from	complex_yield
			where	complex_id = complex.complex_id
			and		benchmark_end between @start_period and @end_period
			and		premium_cinema = 'N'
			and (	(@top_movie = 0)
					or (@top_movie = 1 and exhibitor_top_1 = 'Y')
					or (@top_movie = 2 and exhibitor_top_2 = 'Y')
					or (@top_movie = 3 and exhibitor_not_top_1 = 'Y')
					or (@top_movie = 4 and exhibitor_not_top_2 = 'Y'))) as total_cineads_ytd			
from		complex, film_market, v_exhibitor_report
where		complex_id = complex.complex_id
and			complex.film_complex_status <> 'C'
and			complex.complex_id >= 100
and			complex.film_market_no = film_market.film_market_no
and			v_exhibitor_report.exhibitor_id = complex.exhibitor_id
and			exhibitor_group_id = @exhibitor_id
group by	exhibitor_group_id,
			complex_id, 
			film_market.film_market_no,
			film_market.film_market_desc,
			complex_name
order by	film_market.film_market_no,
			complex_name
GO
