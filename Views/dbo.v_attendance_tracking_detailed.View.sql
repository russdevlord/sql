/****** Object:  View [dbo].[v_attendance_tracking_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_attendance_tracking_detailed]
GO
/****** Object:  View [dbo].[v_attendance_tracking_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_attendance_tracking_detailed]

as
select 				film_campaign.campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						v_onscreen_allocated_campaigns.screening_date,
						no_spots,
						(select sum(attendance) from attendance_campaign_estimates where campaign_no = film_campaign.campaign_no and screening_date = v_onscreen_allocated_campaigns.screening_date) as estimated_attendance,
						(select sum(attendance) from attendance_campaign_actuals where campaign_no = film_campaign.campaign_no and screening_date = v_onscreen_allocated_campaigns.screening_date) as actual_attendance,
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
						confirmation_date					
from				film_campaign
inner join		v_onscreen_allocated_campaigns on film_campaign.campaign_no = v_onscreen_allocated_campaigns.campaign_no
inner join		business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
inner join		client on film_campaign.client_id = client.client_id
inner join		agency on film_campaign.agency_id = agency.agency_id
inner join		agency_groups on agency.agency_group_id = agency_groups.agency_group_id
inner join		agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
inner join		v_campaign_product on film_campaign.campaign_no =  v_campaign_product.campaign_no
inner join		product_category on v_campaign_product.product_category_id = product_category.product_category_id
left outer join v_campaign_subproduct on film_campaign.campaign_no = v_campaign_subproduct.campaign_no
left outer join product_subcategory on v_campaign_subproduct.product_category_id = product_subcategory.product_subcategory_id
left outer join v_statrev_first_revision on film_campaign.campaign_no = v_statrev_first_revision.campaign_no
group by 		film_campaign.campaign_no,
						product_desc,
						includes_follow_film,
						includes_premium_position,
						start_date,
						end_date,
						makeup_deadline,
						campaign_status, 
						no_spots,
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
						v_onscreen_allocated_campaigns.screening_date
GO
