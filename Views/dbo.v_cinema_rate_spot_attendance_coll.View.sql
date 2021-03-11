USE [production]
GO
/****** Object:  View [dbo].[v_cinema_rate_spot_attendance_coll]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_cinema_rate_spot_attendance_coll] 
as


select			campaign_no, 
					product_desc,
					branch_name, 
					branch_code,
					country_code,
					business_unit_desc,
					business_unit_id,
					client_name,
					client_product_desc,
					agency_name,
					agency_group_name,
					buying_group_desc,
					benchmark_end,
					exhibitor_name,
					complex_name, 
					count(spot_id) as no_spots,
					sum(spot_collections) as total_collections,
					sum(spot_attendance)  as attendance
from			(select 		film_campaign.campaign_no, 
										film_campaign.product_desc,
										branch_name, 
										branch.branch_code,
										branch.country_code,
										business_unit_desc,
										business_unit.business_unit_id,
										client_name,
										client_product_desc,
										agency_name,
										agency_group_name,
										buying_group_desc,
										benchmark_end,
										exhibitor_name,
										spot_id,
										cplx.complex_id,
										complex_name,
										(select sum(isnull(cinema_amount,0)) from spot_liability where spot_liability.spot_id = campaign_spot.spot_id and spot_liability.liability_type = 3) as spot_collections,
										(select sum(attendance) from v_certificate_item_distinct, movie_history where v_certificate_item_distinct.certificate_group =  movie_history.certificate_group and spot_reference = campaign_spot.spot_id) as spot_attendance
					from 			film_campaign, 
										branch,
										business_unit,
										client,
										client_product,
										agency,
										agency_groups,
										agency_buying_groups,
										campaign_spot,
										film_screening_date_xref fsdx,
										complex cplx,
										exhibitor
					where			film_campaign.branch_code = branch.branch_code
					and				film_campaign.business_unit_id = business_unit.business_unit_id
					and				film_campaign.agency_id = agency.agency_id
					and				agency.agency_group_id = agency_groups.agency_group_id
					and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
					and				film_campaign.client_id = client.client_id
					and				film_campaign.client_product_id = client_product.client_product_id
					and				campaign_spot.spot_status = 'X'
					and				campaign_spot.campaign_no = film_campaign.campaign_no
					and				campaign_spot.screening_date = fsdx.screening_date
					and				campaign_spot.complex_id = cplx.complex_id
					and				cplx.exhibitor_id = exhibitor.exhibitor_id
					and				benchmark_end > '1-jan-2015'
					group by 	film_campaign.campaign_no, 
										film_campaign.product_desc,
										branch_name, branch.branch_code,branch.country_code,
										business_unit_desc,
										business_unit.business_unit_id,
										client_name,
										client_product_desc,
										agency_name,
										agency_group_name,
										buying_group_desc,
										benchmark_end,
										exhibitor_name,
										spot_id,
										cplx.complex_id,
										complex_name) as temp_table
group by				campaign_no, 
							product_desc,
							branch_name, 
							branch_code,
							country_code,
							business_unit_desc,
							business_unit_id,
							client_name,
							client_product_desc,
							agency_name,
							agency_group_name,
							buying_group_desc,
							benchmark_end,
							exhibitor_name,
							complex_name						

GO
