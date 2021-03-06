/****** Object:  View [dbo].[v_cinetam_tracking_by_product]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_tracking_by_product]
GO
/****** Object:  View [dbo].[v_cinetam_tracking_by_product]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view	[dbo].[v_cinetam_tracking_by_product]

as
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(select 		sum(target_attendance) from inclusion_follow_film_targets, inclusion where inclusion_follow_film_targets.inclusion_id = inclusion.inclusion_id and campaign_no =  temp_table.campaign_no and screening_date = temp_table.screening_date) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_all_people_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				spot_type = 'F')  as actual_attendance,
						'All People'  as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'Follow Film New Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from					(select 						film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit.business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum
							from						film_campaign
							inner join				v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join				business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join				client on film_campaign.client_id = client.client_id
							inner join				agency on film_campaign.agency_id = agency.agency_id
							inner join				agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join				agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join				v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join				product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join		v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join		product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join		v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type = 'F'
							and						film_campaign.campaign_type  = 0
							group by 				film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit.business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date						
union all
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(0) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_all_people_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				spot_type = 'K')  as actual_attendance,
						'All People'  as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'Roadblock Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from				(select 					film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum					
							from					film_campaign
							inner join			v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join			business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join			client on film_campaign.client_id = client.client_id
							inner join			agency on film_campaign.agency_id = agency.agency_id
							inner join			agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join			agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join			v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join			product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join	v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join	product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join	v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type = 'K'
							and						film_campaign.campaign_type  = 0
							group by 			film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date						
union all
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(select		sum(target_attendance)
						from			inclusion_cinetam_targets
						where			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				inclusion_id in (select inclusion_id from inclusion where inclusion_type = 24)) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_cinetam_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				spot_type = 'T'
						and				cinetam_demographics_id in (	select		cinetam_demographics_id 
																								from		cinetam_reporting_demographics_xref 
																								where		cinetam_reporting_demographics_id in (	select			min(cinetam_reporting_demographics_id)
																																														from			inclusion_cinetam_targets
																																														where			campaign_no = temp_table.campaign_no 
																																														and				screening_date = temp_table.screening_date
																																														and				inclusion_id in (select inclusion_id from inclusion where inclusion_type = 24))))  as actual_attendance,
						(select		min(cinetam_reporting_demographics_desc)
						from			inclusion_cinetam_targets,
											cinetam_reporting_demographics
						where			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				inclusion_id in (select inclusion_id from inclusion where inclusion_type = 24)
						and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id)  as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'Tap Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from				(select 					film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum					
							from					film_campaign
							inner join			v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join			business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join			client on film_campaign.client_id = client.client_id
							inner join			agency on film_campaign.agency_id = agency.agency_id
							inner join			agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join			agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join			v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join			product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join	v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join	product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join	v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type = 'T'
							and						film_campaign.campaign_type  = 0
							group by 			film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date						
union all
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(select		sum(attendance)
						from			cinetam_campaign_targets
						where			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_cinetam_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				follow_film = 'N'
						and				spot_type not in ('T','K','F')
						and				cinetam_demographics_id in (	select		cinetam_demographics_id 
																								from		cinetam_reporting_demographics_xref 
																								where		cinetam_reporting_demographics_id in (	select			min(cinetam_reporting_demographics_id)
																																														from			cinetam_campaign_settings
																																														where			campaign_no = temp_table.campaign_no)))  as actual_attendance,
						(select		min(cinetam_reporting_demographics_desc)
						from			cinetam_campaign_settings,
											cinetam_reporting_demographics
						where			campaign_no = temp_table.campaign_no 
						and				cinetam_campaign_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id)  as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'MM Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from				(select 					film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum					
							from					film_campaign
							inner join			v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join			business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join			client on film_campaign.client_id = client.client_id
							inner join			agency on film_campaign.agency_id = agency.agency_id
							inner join			agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join			agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join			v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join			product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join	v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join	product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join	v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type not in ('T','K','F')
							and						film_campaign.campaign_no in (select campaign_no from cinetam_campaign_settings)
							and						film_campaign.campaign_type  = 0
							and						v_onscreen_allocated_campaigns_by_type.follow_film = 'N'
							group by 			film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date
union all
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(select		sum(attendance) / count(distinct screening_date)
						from			film_campaign_manual_attendance
						where			campaign_no = temp_table.campaign_no) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_all_people_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				follow_film = 'N'
						and				spot_type not in ('T','K','F'))  as actual_attendance,
						'All Peeps' as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'MM Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from				(select 					film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum					
							from					film_campaign
							inner join			v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join			business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join			client on film_campaign.client_id = client.client_id
							inner join			agency on film_campaign.agency_id = agency.agency_id
							inner join			agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join			agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join			v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join			product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join	v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join	product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join	v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type not in ('T','K','F')
							and						film_campaign.campaign_no not in (select campaign_no from cinetam_campaign_settings)
							and						film_campaign.campaign_type  = 0
							and						v_onscreen_allocated_campaigns_by_type.follow_film = 'N'
							group by 			film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date
union all
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(select		sum(attendance)
						from			cinetam_campaign_targets
						where			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_cinetam_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				follow_film = 'Y'
						and				spot_type not in ('T','K','F')
						and				cinetam_demographics_id in (	select		cinetam_demographics_id 
																								from		cinetam_reporting_demographics_xref 
																								where		cinetam_reporting_demographics_id in (	select			min(cinetam_reporting_demographics_id)
																																														from			cinetam_campaign_settings
																																														where			campaign_no = temp_table.campaign_no)))  as actual_attendance,
						(select		min(cinetam_reporting_demographics_desc)
						from			cinetam_campaign_settings,
											cinetam_reporting_demographics
						where			campaign_no = temp_table.campaign_no 
						and				cinetam_campaign_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id)  as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'Follow Film Old Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from				(select 					film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum					
							from					film_campaign
							inner join			v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join			business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join			client on film_campaign.client_id = client.client_id
							inner join			agency on film_campaign.agency_id = agency.agency_id
							inner join			agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join			agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join			v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join			product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join	v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join	product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join	v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type not in ('T','K','F')
							and						film_campaign.campaign_no in (select campaign_no from cinetam_campaign_settings)
							and						film_campaign.campaign_type  = 0
							and						v_onscreen_allocated_campaigns_by_type.follow_film = 'Y'
							group by 			film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date
union all
select				campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						screening_date,
						no_spots,
						makeup_deadline,
						campaign_status,
						(select		sum(attendance) / count(distinct screening_date)
						from			film_campaign_manual_attendance
						where			campaign_no = temp_table.campaign_no) as estimated_attendance,
						(select 		sum(attendance) 
						from 			v_onscreen_allocated_campaigns_all_people_by_type 
						where 			campaign_no = temp_table.campaign_no 
						and				screening_date = temp_table.screening_date
						and				complex_region = temp_table.complex_region
						and				sponsorship = temp_table.sponsorship
						and				duration_band = temp_table.duration_band
						and				follow_film = 'Y'
						and				spot_type not in ('T','K','F'))  as actual_attendance,
						'All Peeps' as demo_desc, 
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						'Follow Film Old Spots' as type,
						sum(cinema_sum) as revenue_charge_rate
from				(select 					film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														sum(no_spots) as no_spots,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)) as contact,
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number,
														sum(cinema_rate_sum) as cinema_sum					
							from					film_campaign
							inner join			v_onscreen_allocated_campaigns_by_type on film_campaign.campaign_no = v_onscreen_allocated_campaigns_by_type.campaign_no
							inner join			business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
							inner join			client on film_campaign.client_id = client.client_id
							inner join			agency on film_campaign.agency_id = agency.agency_id
							inner join			agency_groups on agency.agency_group_id = agency_groups.agency_group_id
							inner join			agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
							inner join			v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
							inner join			product_category on v_campaign_product.product_category_id = product_category.product_category_id
							left outer join	v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
							left outer join	product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
							left outer join	v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
							where					v_onscreen_allocated_campaigns_by_type.spot_type not in ('T','K','F')
							and						film_campaign.campaign_no not in (select campaign_no from cinetam_campaign_settings)
							and						film_campaign.campaign_type  = 0
							and						v_onscreen_allocated_campaigns_by_type.follow_film = 'Y'
							group by 			film_campaign.campaign_no,
														product_desc,
														includes_follow_film,
														includes_premium_position,
														start_date,
														end_date,
														v_onscreen_allocated_campaigns_by_type.screening_date,
														makeup_deadline,
														campaign_status,
														ltrim(rtrim(film_campaign.contact)),
														agency_name,
														agency_group_name,
														buying_group_desc,
														product_category_desc,
														product_subcategory_desc,
														business_unit_desc,
														client_name,
														entry_date,
														confirmation_date,
														complex_region, 
														sponsorship,
														duration_band,
														duration_number	) as temp_table
group by			campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
						contact,
						agency_name,
						agency_group_name,
						buying_group_desc,
						product_category_desc,
						product_subcategory_desc,
						business_unit_desc,
						client_name,
						entry_date,
						confirmation_date,
						complex_region, 
						sponsorship,
						duration_band,
						duration_number,
						screening_date


GO
