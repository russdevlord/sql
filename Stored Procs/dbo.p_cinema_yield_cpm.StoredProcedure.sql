/****** Object:  StoredProcedure [dbo].[p_cinema_yield_cpm]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_yield_cpm]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_yield_cpm]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinema_yield_cpm]			@start_period			datetime,
										@end_period				datetime,
										@current_period			datetime,
										@country_code			char(1)

as

declare			@avail_audience			numeric(20,12),
				@sold_audience			numeric(20,12)
	
set nocount on


create table #fill_rate_cpm
(
	screening_date			datetime			not null,
	cpm						numeric(20,12)		not null
)

insert into		#fill_rate_cpm 
select			screening_date,
				sum(revenue) / sum(attendance) * 1000 as cpm
from			(select			temp_table_campaigns.campaign_no,
								temp_table_campaigns.screening_date,
								sum(attendance) as attendance,
								sum(revenue) as revenue
				from			(select			campaign_spot.campaign_no,
												campaign_spot.screening_date
								from			campaign_spot
								inner join		film_screening_date_xref on campaign_spot.screening_date = film_screening_date_xref.screening_date
								inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
								inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
								inner join		branch on film_campaign.branch_code = branch.branch_code
								where			benchmark_end between @start_period and @current_period
								and				country_code = @country_code
								and				film_campaign.campaign_type not in (4,9)
								group by		campaign_spot.campaign_no,
												campaign_spot.screening_date) as temp_table_campaigns
				left join		(select			campaign_spot.campaign_no,
												campaign_spot.screening_date,
												sum(convert(numeric(20,12), movie_history.attendance) / 30.000000000000 * convert(numeric(20,12), campaign_package.duration)) as attendance
								from			campaign_spot
								inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
								inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
								inner join		film_screening_date_xref on campaign_spot.screening_date = film_screening_date_xref.screening_date
								inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
								inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
								inner join		branch on film_campaign.branch_code = branch.branch_code
								where			benchmark_end between @start_period and @current_period
								and				country_code = @country_code
								and				film_campaign.campaign_type not in (4,9)
								group by		campaign_spot.campaign_no,
												campaign_spot.screening_date) as temp_table_attendance
				on				temp_table_campaigns.screening_date = temp_table_attendance.screening_date
				and				temp_table_campaigns.campaign_no = temp_table_attendance.campaign_no
				left join		(select			v_statrev_onscreen_no_def.campaign_no,
												v_statrev_onscreen_no_def.screening_date,
												sum(v_statrev_onscreen_no_def.cost) as revenue
								from			v_statrev_onscreen_no_def
								inner join		film_campaign on v_statrev_onscreen_no_def.campaign_no = film_campaign.campaign_no
								where			revenue_period between @start_period and @current_period
								and				country_code = @country_code
								and				film_campaign.campaign_type not in (4,9)
								group by		v_statrev_onscreen_no_def.campaign_no,
												v_statrev_onscreen_no_def.screening_date) as temp_table_revenue
				on				temp_table_campaigns.screening_date = temp_table_revenue.screening_date
				and				temp_table_campaigns.campaign_no = temp_table_revenue.campaign_no
				group by		temp_table_campaigns.campaign_no,
								temp_table_campaigns.screening_date) as temp_inner_table
group by		temp_inner_table.screening_date
having			sum(attendance) <> 0

select * from #fill_rate_cpm order by screening_date

return 0
GO
