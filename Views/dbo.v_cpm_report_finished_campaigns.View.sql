/****** Object:  View [dbo].[v_cpm_report_finished_campaigns]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cpm_report_finished_campaigns]
GO
/****** Object:  View [dbo].[v_cpm_report_finished_campaigns]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_cpm_report_finished_campaigns]
as
select			movie_type,
				complex_cpm.campaign_no,
				complex_cpm.product_desc,
				business_unit_desc, 
				premium_cinema,
				duration,
				roadblock_duration,
				tap_duration,
				ff_aud_duration,
				ff_old_total_duration,
				mm_total_duration,
				ff_old_paid_duration,
				mm_paid_duration,
				ff_old_bonus_duration,
				mm_bonus_duration,
				avg(avg_30seceqv_rate) as avg_30seceqv_rate,
				avg(avg_roadblock_30seceqv_rate) as avg_roadblock_30seceqv_rate,
				avg(avg_tap_30seceqv_rate) as avg_tap_30seceqv_rate,
				avg(avg_ff_aud_30seceqv_rate) as avg_ff_aud_30seceqv_rate,
				avg(avg_ff_old_30seceqv_rate) as avg_ff_old_30seceqv_rate,
				avg(avg_mm_30seceqv_rate) as avg_mm_30seceqv_rate,
				avg(avg_rate) as avg_rate,
				avg(avg_roadblock_rate) as avg_roadblock_rate,
				avg(avg_tap_rate) as avg_tap_rate,
				avg(avg_ff_aud_rate) as avg_ff_aud_rate,
				avg(avg_ff_old_rate) as avg_ff_old_rate,
				avg(avg_mm_rate) as avg_mm_rate,
				sum(total_revenue_30seceqv) as total_revenue_30seceqv,
				sum(roadblock_revenue_30seceqv) as roadblock_revenue_30seceqv,
				sum(tap_revenue_30seceqv) as tap_revenue_30seceqv,
				sum(ff_aud_revenue_30seceqv) as ff_aud_revenue_30seceqv,
				sum(ff_old_revenue_30seceqv) as ff_old_revenue_30seceqv,
				sum(mm_revenue_30seceqv) as mm_revenue_30seceqv,
				sum(total_revenue) as total_revenue,
				sum(roadblock_revenue) as roadblock_revenue,
				sum(tap_revenue) as tap_revenue,
				sum(ff_aud_revenue) as ff_aud_revenue,
				sum(ff_old_revenue) as ff_old_revenue,
				sum(mm_revenue) as mm_revenue,
				agency_duration,
				direct_duration,
				showcase_duration,
				cineads_duration,
				sum(agency_revenue) as agency_revenue,
				sum(direct_revenue) as direct_revenue,
				sum(showcase_revenue) as showcase_revenue,
				sum(cineads_revenue) as cineads_revenue,
				sum(attendance) as attendance,
				sum(all_18_39) as all_18_39,
				sum(all_25_54) as all_25_54,
				country_code,
				agency_name,
				agency_group_name,
				buying_group_desc,
				client_name,
				client_product_desc,
				YEAR(benchmark_end) as year,
				case when sum(attendance) > 0 then sum(total_revenue) / sum(attendance) * 1000 else 0 end as all_people_cpm,
				case when sum(all_18_39) > 0 then sum(total_revenue) / sum(all_18_39) * 1000 else 0 end as all_18_39_cpm,
				case when sum(all_25_54) > 0 then sum(total_revenue) / sum(all_25_54) * 1000 else 0 end as all_25_54_cpm
FROM			complex_cpm,   
				film_campaign, 
				agency, 
				agency_groups, 
				agency_buying_groups, 
				client, 
				client_product, 
				business_unit
where			film_campaign.campaign_no = complex_cpm.campaign_no
and				film_campaign.agency_id = agency.agency_id
and				agency.agency_group_id = agency_groups.agency_group_id
and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and				film_campaign.client_id = client.client_id
and				film_campaign.client_product_id = client_product.client_product_id
and				campaign_status in ('F', 'X') 
and				film_campaign.end_date > '25-dec-2014'
and				film_campaign.end_date <= (select max(screening_date) from film_screening_dates where attendance_status = 'X')
and				film_campaign.business_unit_id = business_unit.business_unit_id
group by		movie_type,
				complex_cpm.campaign_no,
				complex_cpm.product_desc,
				business_unit_desc, 
				premium_cinema,
				duration,
				roadblock_duration,
				tap_duration,
				ff_aud_duration,
				ff_old_total_duration,
				mm_total_duration,
				ff_old_paid_duration,
				mm_paid_duration,
				ff_old_bonus_duration,
				mm_bonus_duration,
				agency_duration,
				direct_duration,
				showcase_duration,
				cineads_duration,
				country_code,
				agency_name,
				agency_group_name,
				buying_group_desc,
				client_name,
				client_product_desc,
				YEAR(benchmark_end)

GO
