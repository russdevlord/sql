/****** Object:  View [dbo].[v_agency_deal_tracker]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_agency_deal_tracker]
GO
/****** Object:  View [dbo].[v_agency_deal_tracker]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view		[dbo].[v_agency_deal_tracker]
as
select			inclusion_temp.branch_code, 
				inclusion_temp.branch_name, 
				inclusion_temp.country_code, 
				inclusion_temp.country_name,
				inclusion_temp.client_name,
				inclusion_temp.booking_agency_name,
				inclusion_temp.booking_rep_name,
				inclusion_temp.campaign_no,
				inclusion_temp.product_desc,
				inclusion_temp.business_unit_desc,
				inclusion_temp.inclusion_type_desc,
				min(inclusion_temp.start_date) as start_date,
				max(inclusion_temp.end_date) as end_date,
				sum(inclusion_temp.inclusion_charge_rate) as inclusion_charge_rate,
				inclusion_temp.confirmed_date,
				inclusion_temp.duration,
				inclusion_temp.sold_demo,
				sum(inclusion_temp.demo_original_target_attendance) as demo_original_target_attendance,
				sum(inclusion_temp.all_people_original_target_attendance) as all_people_original_target_attendance,
				sum(inclusion_temp.metro_count) as metro_count,
				sum(inclusion_temp.regional_count) as regional_count,
				sum(inclusion_temp.demo_actual_attendance) as demo_actual_attendance,
				sum(inclusion_temp.all_people_actual_attendance) as all_people_actual_attendance,
				case when sum(inclusion_temp.demo_original_target_attendance)  = 0 then 0 else 1000 * sum(inclusion_temp.inclusion_charge_rate) * duration / 30 / sum(inclusion_temp.demo_original_target_attendance) end as demo_30sec_CPM,
				case when sum(inclusion_temp.all_people_original_target_attendance)  = 0 then 0 else 1000 * sum(inclusion_temp.inclusion_charge_rate) * duration / 30 / sum(inclusion_temp.all_people_original_target_attendance) end as all_people_30sec_CPM
from			(--FAP MAP TAP run as they have targets and hence a demo
				select			inclusion_temp_spots.inclusion_id,
								inclusion_temp_spots.branch_code, 
								inclusion_temp_spots.branch_name, 
								inclusion_temp_spots.country_code, 
								inclusion_temp_spots.country_name,
								inclusion_temp_spots.client_name,
								inclusion_temp_spots.booking_agency_name,
								inclusion_temp_spots.booking_rep_name,
								inclusion_temp_spots.campaign_no,
								inclusion_temp_spots.product_desc,
								inclusion_temp_spots.business_unit_desc,
								inclusion_temp_spots.inclusion_type_desc,
								inclusion_temp_spots.start_date,
								inclusion_temp_spots.end_date,
								inclusion_temp_spots.inclusion_charge_rate,
								inclusion_temp_spots.confirmed_date,
								inclusion_temp_spots.duration,
								inclusion_temp_spots.sold_demo,
								sum(v_cinetam_inclusion_target_summary.original_target_attendance) as demo_original_target_attendance,
								sum(v_cinetam_inclusion_target_summary_converted.original_target_attendance) as all_people_original_target_attendance,
								inclusion_temp_spots.metro_count,
								inclusion_temp_spots.regional_count,
								(select			sum(attendance) 
								from			v_inclusion_cinetam_attendance with (nolock)
								where			v_inclusion_cinetam_attendance.inclusion_id = inclusion_temp_spots.inclusion_id
								and				v_inclusion_cinetam_attendance.cinetam_reporting_demographics_id = inclusion_temp_spots.cinetam_reporting_demographics_id) as demo_actual_attendance,
								(select			sum(attendance) 
								from			v_inclusion_cinetam_attendance with (nolock)
								where			v_inclusion_cinetam_attendance.inclusion_id = inclusion_temp_spots.inclusion_id
								and				v_inclusion_cinetam_attendance.cinetam_reporting_demographics_id = 0) as all_people_actual_attendance
				from			(select			inclusion.inclusion_id,
												branch.branch_code, 
												branch.branch_name, 
												country.country_code, 
												country.country_name,
												client.client_name,
												agency.agency_name as booking_agency_name,
												sales_rep.first_name + ' ' + sales_rep.last_name as booking_rep_name,
												film_campaign.campaign_no,
												film_campaign.product_desc,
												business_unit.business_unit_desc,
												inclusion_type.inclusion_type_desc,
												min(inclusion_spot.screening_date) as start_date,
												max(inclusion_spot.screening_date) as end_date,
												sum(inclusion_spot.charge_rate) as inclusion_charge_rate,
												film_campaign.confirmed_date,
												v_cinetam_inclusion_spot_duration.duration,
												cinetam_reporting_demographics_desc as sold_demo,
												v_cinetam_inclusion_target_summary.cinetam_reporting_demographics_id,
												metro_count,
												regional_count
								from			film_campaign with (nolock)
								inner join		branch with (nolock) on film_campaign.branch_code = branch.branch_code
								inner join		country with (nolock)  on branch.country_code = country.country_code
								inner join		business_unit with (nolock)  on film_campaign.business_unit_id = business_unit.business_unit_id
								inner join		inclusion with (nolock)  on film_campaign.campaign_no = inclusion.campaign_no
								inner join		inclusion_type with (nolock)  on inclusion.inclusion_type = inclusion_type.inclusion_type
								inner join		client with (nolock)  on film_campaign.client_id = client.client_id
								inner join		agency with (nolock)  on film_campaign.agency_id = agency.agency_id
								inner join		sales_rep with (nolock)  on film_campaign.rep_id = sales_rep.rep_id
								inner join		inclusion_spot with (nolock)  on inclusion.inclusion_id = inclusion_spot.inclusion_id
								inner join		v_cinetam_inclusion_spot_duration  with (nolock) on inclusion.inclusion_id = v_cinetam_inclusion_spot_duration.inclusion_id
								inner join		v_cinetam_inclusion_target_summary  with (nolock) on inclusion.inclusion_id = v_cinetam_inclusion_target_summary.inclusion_id 
								inner join		cinetam_reporting_demographics  with (nolock) on v_cinetam_inclusion_target_summary.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
								inner join		v_cinetam_inclusion_region_count  with (nolock) on inclusion.inclusion_id = v_cinetam_inclusion_region_count.inclusion_id
								inner join		v_cinetam_inclusion_target_summary_converted  with (nolock)  on inclusion.inclusion_id = v_cinetam_inclusion_target_summary_converted.inclusion_id and v_cinetam_inclusion_target_summary_converted.cinetam_reporting_demographics_id = 0
								where			inclusion_type.inclusion_type in (24,29,32)
								and				film_campaign.campaign_status <> 'P'
								group by		inclusion.inclusion_id,
												branch.branch_code, 
												branch.branch_name, 
												country.country_code, 
												country.country_name,
												client.client_name,
												agency.agency_name,
												film_campaign.campaign_no,
												film_campaign.product_desc,
												business_unit.business_unit_desc,
												inclusion_type.inclusion_type,
												sales_rep.first_name + ' ' + sales_rep.last_name,
												inclusion_type.inclusion_type_desc,
												film_campaign.confirmed_date,
												v_cinetam_inclusion_spot_duration.duration,
												cinetam_reporting_demographics_desc,
												metro_count,
												regional_count,
												v_cinetam_inclusion_target_summary.cinetam_reporting_demographics_id 
								union all
								--roadblock and first run as they have no targets and hence no demo
								select			inclusion.inclusion_id,
												branch.branch_code, 
												branch.branch_name, 
												country.country_code, 
												country.country_name,
												client.client_name,
												agency.agency_name as booking_agency_name,
												sales_rep.first_name + ' ' + sales_rep.last_name as booking_rep_name,
												film_campaign.campaign_no,
												film_campaign.product_desc,
												business_unit.business_unit_desc,
												inclusion_type.inclusion_type_desc,
												min(inclusion_spot.screening_date) as start_date,
												max(inclusion_spot.screening_date) as end_date,
												sum(inclusion_spot.charge_rate) as inclusion_charge_rate,
												film_campaign.confirmed_date,
												v_cinetam_inclusion_spot_duration.duration,
												'No Demo' as sold_demo,
												null,
												metro_count,
												regional_count
								from			film_campaign with (nolock) 
								inner join		branch with (nolock)  on film_campaign.branch_code = branch.branch_code
								inner join		country with (nolock)  on branch.country_code = country.country_code
								inner join		business_unit with (nolock)  on film_campaign.business_unit_id = business_unit.business_unit_id
								inner join		inclusion with (nolock)  on film_campaign.campaign_no = inclusion.campaign_no
								inner join		inclusion_type with (nolock)  on inclusion.inclusion_type = inclusion_type.inclusion_type
								inner join		client with (nolock)  on film_campaign.client_id = client.client_id
								inner join		agency with (nolock)  on film_campaign.agency_id = agency.agency_id
								inner join		sales_rep with (nolock)  on film_campaign.rep_id = sales_rep.rep_id
								inner join		inclusion_spot with (nolock)  on inclusion.inclusion_id = inclusion_spot.inclusion_id
								inner join		v_cinetam_inclusion_spot_duration with (nolock)  on inclusion.inclusion_id = v_cinetam_inclusion_spot_duration.inclusion_id
								inner join		v_cinetam_inclusion_region_count with (nolock)  on inclusion.inclusion_id = v_cinetam_inclusion_region_count.inclusion_id
								where			inclusion_type.inclusion_type in (30,31)
								and				film_campaign.campaign_status <> 'P'
								group by		inclusion.inclusion_id,
												branch.branch_code, 
												branch.branch_name, 
												country.country_code, 
												country.country_name,
												client.client_name,
												agency.agency_name,
												film_campaign.campaign_no,
												film_campaign.product_desc,
												business_unit.business_unit_desc,
												inclusion_type.inclusion_type,
												sales_rep.first_name + ' ' + sales_rep.last_name,
												inclusion_type.inclusion_type_desc,
												film_campaign.confirmed_date,
												duration,
												metro_count,
												regional_count) as inclusion_temp_spots
				inner join		v_cinetam_inclusion_target_summary on inclusion_temp_spots.inclusion_id = v_cinetam_inclusion_target_summary.inclusion_id 
				inner join		v_cinetam_inclusion_target_summary_converted on inclusion_temp_spots.inclusion_id = v_cinetam_inclusion_target_summary_converted.inclusion_id and v_cinetam_inclusion_target_summary_converted.cinetam_reporting_demographics_id = 0
				group by		inclusion_temp_spots.inclusion_id,
								inclusion_temp_spots.branch_code, 
								inclusion_temp_spots.branch_name, 
								inclusion_temp_spots.country_code, 
								inclusion_temp_spots.country_name,
								inclusion_temp_spots.client_name,
								inclusion_temp_spots.booking_agency_name,
								inclusion_temp_spots.booking_rep_name,
								inclusion_temp_spots.campaign_no,
								inclusion_temp_spots.product_desc,
								inclusion_temp_spots.business_unit_desc,
								inclusion_temp_spots.inclusion_type_desc,
								inclusion_temp_spots.start_date,
								inclusion_temp_spots.end_date,
								inclusion_temp_spots.inclusion_charge_rate,
								inclusion_temp_spots.confirmed_date,
								inclusion_temp_spots.cinetam_reporting_demographics_id,
								inclusion_temp_spots.duration,
								inclusion_temp_spots.sold_demo,
								inclusion_temp_spots.metro_count,
								inclusion_temp_spots.regional_count) as inclusion_temp
group by		inclusion_temp.branch_code, 
				inclusion_temp.branch_name, 
				inclusion_temp.country_code, 
				inclusion_temp.country_name,
				inclusion_temp.client_name,
				inclusion_temp.booking_agency_name,
				inclusion_temp.booking_rep_name,
				inclusion_temp.campaign_no,
				inclusion_temp.product_desc,
				inclusion_temp.business_unit_desc,
				inclusion_temp.inclusion_type_desc,
				inclusion_temp.confirmed_date,
				inclusion_temp.duration,
				inclusion_temp.sold_demo
GO
