/****** Object:  StoredProcedure [dbo].[p_cinema_yield_fill_rate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_yield_fill_rate]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_yield_fill_rate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinema_yield_fill_rate]	@start_period			datetime,
										@end_period				datetime,
										@current_period			datetime,
										@country_code			char(1)

as

declare			@avail_audience			numeric(20,12),
				@sold_audience			numeric(20,12)
	
set nocount on


create table #fill_rate_weekly
(
	screening_date			datetime			not null,
	fill_rate				numeric(20,12)		not null
)

insert into		#fill_rate_weekly 
select			film_screening_date_xref.screening_date,
				sum(time_used) / sum(time_avail) as fill_rate
from			film_screening_date_xref
inner join		(select			movie_history.screening_date,
								sum(convert(numeric(24,12), max_time + mg_max_time)) as time_avail
				from			movie_history
				inner join		complex_date on movie_history.screening_date = complex_date.screening_date
				and				movie_history.complex_id = complex_date.complex_id
				inner join		film_screening_date_xref on	movie_history.screening_date = film_screening_date_xref.screening_date
				where			country = @country_code
				and				movie_history.movie_id <> 102
				and				benchmark_end between @start_period and @current_period
				group by		movie_history.screening_date) as temp_table_playlist_time
on				film_screening_date_xref.screening_date = temp_table_playlist_time.screening_date
inner join		(select			campaign_spot.screening_date,
								sum(convert(numeric(24,12), campaign_package.duration)) as time_used
				from			campaign_spot
				inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
				inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
				inner join		film_screening_date_xref on campaign_spot.screening_date = film_screening_date_xref.screening_date
				and				movie_history.screening_date = film_screening_date_xref.screening_date
				inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
				inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
				where			benchmark_end between @start_period and @current_period
				and				movie_history.country = @country_code
				and				movie_history.movie_id <> 102
				and				film_campaign.campaign_type not in (4,9)
				group by		campaign_spot.screening_date) as temp_table_prints
on				film_screening_date_xref.screening_date = temp_table_prints.screening_date
and				temp_table_playlist_time.screening_date = temp_table_prints.screening_date
where			benchmark_end between @start_period and @current_period
group by		film_screening_date_xref.screening_date
having			sum(time_avail) <> 0
order by		film_screening_date_xref.screening_date

select * from #fill_rate_weekly

return 0
GO
