/****** Object:  View [dbo].[v_liability_analysis]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_liability_analysis]
GO
/****** Object:  View [dbo].[v_liability_analysis]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_liability_analysis]

as

select			temp_table.inclusion_id, 
				temp_table.campaign_no,
				temp_table.inclusion_type_desc,
				temp_table.screening_date,
				temp_table.complex_id,
				temp_table.branch_code,
				temp_table.complex_name, 
				temp_table.exhibitor_name,
				temp_table.weighting,
				temp_table.region_class_desc,
				sum(temp_table.all_people_attendance) as all_people_attendance,
				(select cinetam_complex_date_settings.percent_market from cinetam_complex_date_settings where complex_id = temp_table.complex_id and screening_Date = temp_table.screening_date and cinetam_reporting_demographics_id = 0) as last_year_attendance_share,
				count(distinct temp_table.spot_id) as no_spots,
				max(total_weekly_campaign_revenue) as total_weekly_campaign_revenue,
				sum(total_actual_unweighted_amount) as total_actual_unweighted_amount,
				sum(total_actual_weighted_amount) as total_actual_weighted_amount
from			(select			campaign_spot.spot_id,
								inclusion.inclusion_id, 
								campaign_spot.campaign_no,
								inclusion_type_desc,
								campaign_spot.screening_date,
								campaign_spot.complex_id,
								complex.branch_code,
								complex_name, 
								exhibitor_name,
								complex_rent_groups.weighting,
								complex_region_class.region_class_desc,
								sum(attendance) as all_people_attendance,
								count(distinct campaign_spot.spot_id) as no_spots,
								max(inclusion_spot.charge_rate) as total_weekly_campaign_revenue,
								(select sum(spot_amount) from spot_liability where spot_id = campaign_spot.spot_id and liability_type in (1,5, 34)) as total_actual_unweighted_amount,
								(select sum(cinema_amount) from spot_liability where spot_id = campaign_spot.spot_id and liability_type in (1,5, 34)) as total_actual_weighted_amount
				from			campaign_spot
				inner join		spot_type on campaign_spot.spot_type = spot_type.spot_type_code
				inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
				inner join		inclusion_spot on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id
				inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
				inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
				inner join		complex on campaign_spot.complex_id = complex.complex_id
				inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id
				inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
				inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
				inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no
				inner join		complex_region_class on complex.complex_region_class = complex_region_class.complex_region_class
				where			campaign_spot.screening_date in (select screening_date from film_screening_dates where attendance_status = 'X')
				group by		campaign_spot.spot_id,
								inclusion.inclusion_id, 
								campaign_spot.campaign_no,
								inclusion_type_desc,
								campaign_spot.screening_date,
								campaign_spot.complex_id,
								complex.branch_code,
								complex_name, 
								exhibitor_name,
								complex_rent_groups.weighting,
								complex_region_class.region_class_desc) as temp_table
group by		temp_table.inclusion_id, 
				temp_table.campaign_no,
				temp_table.inclusion_type_desc,
				temp_table.screening_date,
				temp_table.complex_id,
				temp_table.branch_code,
				temp_table.complex_name, 
				temp_table.exhibitor_name,
				temp_table.weighting,
				temp_table.region_class_desc
GO
