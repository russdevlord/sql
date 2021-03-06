/****** Object:  View [dbo].[v_inclusion_follow_film_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_inclusion_follow_film_report]
GO
/****** Object:  View [dbo].[v_inclusion_follow_film_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_inclusion_follow_film_report]
as
select			film_campaign.campaign_no,
				film_campaign.product_desc,
				client.client_name,
				agency.agency_name,
				agency_groups.agency_group_name,
				agency_buying_groups.buying_group_desc,
				branch.branch_code,
				branch.branch_name,
				sales_rep.first_name + ' ' + sales_rep.last_name as rep_name,
				business_unit_desc,
				inclusion_type_desc,
				confirmed_date,
				long_name,
				(select product_category.product_category_desc from v_campaign_product_category inner join product_category on v_campaign_product_category.product_category = product_category.product_category_id where campaign_no = film_campaign.campaign_no) as product_category,
				(select product_subcategory_desc from v_campaign_subproduct inner join product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id where campaign_no = film_campaign.campaign_no) as sub_product_category,
				inclusion_cinetam_master_target.sale_percentage,
				film_campaign.start_date,
				film_campaign.end_date,
				cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
				(select			isnull(AVG(duration),0) 
				from			campaign_package 
				where			campaign_no = film_campaign.campaign_no 
				and				package_id in (	select			package_id
												from			inclusion_campaign_spot_xref
												inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
												inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
												inner join		inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
												where			inclusion_type = inclusion_type.inclusion_type
												and				inclusion_cinetam_master_target.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
												and				inclusion.campaign_no = film_campaign.campaign_no)) as average_duration,
				(select			isnull(SUM(charge_rate),0)
				from			inclusion_spot 
				where			campaign_no = film_campaign.campaign_no 
				and				spot_id in (select			inclusion_campaign_spot_xref.inclusion_spot_id
											from			inclusion_campaign_spot_xref
											inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
											inner join		inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
											where			inclusion_type = inclusion_type.inclusion_type
											and				inclusion_cinetam_master_target.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
											and				campaign_no = film_campaign.campaign_no)) as charge_rate_sum,
				(select			isnull(SUM(inclusion_follow_film_targets.original_target_attendance),0)
				from			inclusion_follow_film_targets
				inner join		inclusion on inclusion_follow_film_targets.inclusion_id = inclusion.inclusion_id
				where			inclusion_type = inclusion_type.inclusion_type
				and				movie_id = inclusion_movies.movie_id
				and				inclusion_follow_film_targets.inclusion_id in (	select			inclusion_campaign_spot_xref.inclusion_id
																				from			inclusion_campaign_spot_xref
																				inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
																				inner join		inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
																				where			inclusion_type = inclusion_type.inclusion_type
																				and				inclusion_cinetam_master_target.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
																				and				campaign_no = film_campaign.campaign_no) 
				and				inclusion_follow_film_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id) as target_attendance,
				(select			isnull(SUM(attendance),0)
				from			inclusion_cinetam_attendance
				inner join		inclusion on inclusion_cinetam_attendance.inclusion_id = inclusion.inclusion_id
				where			inclusion_type = inclusion_type.inclusion_type
				and				movie_id = inclusion_movies.movie_id
				and				inclusion_cinetam_attendance.inclusion_id in (	select			inclusion_campaign_spot_xref.inclusion_id
																				from			inclusion_campaign_spot_xref
																				inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
																				inner join		inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
																				where			inclusion_type = inclusion_type.inclusion_type
																				and				inclusion_cinetam_master_target.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
																				and				campaign_no = film_campaign.campaign_no)
				and				inclusion_cinetam_attendance.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id) as achieved_attendance
from			film_campaign
inner join		client on film_campaign.client_id = client.client_id
inner join		agency on film_campaign.agency_id = agency.agency_id
inner join		branch on film_campaign.branch_code = branch.branch_code
inner join		sales_rep on film_campaign.rep_id = sales_rep.rep_id
inner join		agency_groups on agency.agency_group_id = agency_groups.agency_group_id
inner join		agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
inner join		business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
inner join		inclusion on film_campaign.campaign_no = inclusion.campaign_no
inner join		inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
inner join		cinetam_reporting_demographics on inclusion_cinetam_master_target.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		(select inclusion_id, movie_id from inclusion_follow_film_targets group by inclusion_id, movie_id) as inclusion_movies on inclusion.inclusion_id = inclusion_movies.inclusion_id
inner join		movie on inclusion_movies.movie_id = movie.movie_id
where			inclusion.inclusion_type in (29)
and				campaign_status <> 'P'
group by		film_campaign.campaign_no,
				film_campaign.product_desc,
				client.client_name,
				confirmed_date,
				film_campaign.start_date,
				film_campaign.end_date,
				agency.agency_name,
				agency_groups.agency_group_name,
				agency_buying_groups.buying_group_desc,
				branch.branch_code,
				branch.branch_name,
				sales_rep.first_name,
				sales_rep.last_name,
				inclusion_cinetam_master_target.sale_percentage,
				long_name,
				inclusion_movies.movie_id,
				inclusion_type_desc,
				inclusion_type.inclusion_type,
				cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
				cinetam_reporting_demographics.cinetam_reporting_demographics_id,
				business_unit_desc	
GO
