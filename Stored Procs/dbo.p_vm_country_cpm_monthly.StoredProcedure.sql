/****** Object:  StoredProcedure [dbo].[p_vm_country_cpm_monthly]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_country_cpm_monthly]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_country_cpm_monthly]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_vm_country_cpm_monthly]	@country_code			char(1), 
												@end_period				datetime,
												@start_period			datetime

as

select		country.country_code, 
			country_name,
			benchmark_end,
			(select	case when sum(attendance) > 0 then sum(agency_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		agency_duration <> 0
			and		movie_type = 'Standard' ) as agency_cpm,			
			(select	case when sum(attendance) > 0 then sum(direct_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		direct_duration <> 0
			and		movie_type = 'Standard') as direct_cpm,			
			(select	case when sum(attendance) > 0 then sum(showcase_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		showcase_duration <> 0
			and		movie_type = 'Standard') as showcase_cpm,			
			(select 	case when sum(attendance_sum) > 0 then sum(revenue_sum) / sum(attendance_sum) * 1000 else 0 end
			from		(select	sum(agency_revenue) as revenue_sum,
								sum(attendance) as attendance_sum
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = temp_period.benchmark_end
						and		agency_duration <> 0
						and		movie_type = 'Standard' 
						union all
						select	sum(direct_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = temp_period.benchmark_end
						and		direct_duration <> 0
						and		movie_type = 'Standard'
						union all 
						select	sum(showcase_revenue),
								sum(attendance)
						from	complex_cpm
						where	country_code = country.country_code and premium_cinema = 'N' 
						and		benchmark_end = temp_period.benchmark_end
						and		showcase_duration <> 0
						and		movie_type = 'Standard') as temp_table) as cinema_cpm,			

			(select	case when sum(attendance) > 0 then sum(ff_aud_revenue + ff_old_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		ff_aud_duration + ff_old_total_duration <> 0
			and		movie_type = 'Standard') as ff_cpm,			
			(select	case when sum(attendance) > 0 then sum(mm_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		mm_total_duration <> 0
			and		movie_type = 'Standard') as mm_cpm,			
			(select	case when sum(attendance) > 0 then sum(roadblock_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		roadblock_duration <> 0
			and		movie_type = 'Standard') as roadblock_cpm,			
			(select	case when sum(attendance) > 0 then sum(tap_revenue) / sum(attendance) * 1000 else 0 end 
			from	complex_cpm
			where	country_code = country.country_code and premium_cinema = 'N' 
			and		benchmark_end = temp_period.benchmark_end
			and		tap_duration <> 0
			and		movie_type = 'Standard') as tap_cpm

from		country, (select distinct benchmark_end from film_screening_date_xref where benchmark_end between @start_period and @end_period) as temp_period
where		country_code = @country_code
group by	country_code, 
			country_name,
			temp_period.benchmark_end
order by	country_name,
			temp_period.benchmark_end

return 0
GO
