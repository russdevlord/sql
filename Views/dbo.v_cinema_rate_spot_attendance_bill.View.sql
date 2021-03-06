/****** Object:  View [dbo].[v_cinema_rate_spot_attendance_bill]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinema_rate_spot_attendance_bill]
GO
/****** Object:  View [dbo].[v_cinema_rate_spot_attendance_bill]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view [dbo].[v_cinema_rate_spot_attendance_bill]
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
					complex_id,
					film_market_no,
					film_market_desc,
					(select sum(attendance) from movie_history where complex_id = temp_table.complex_id and screening_date in (select screening_date from film_screening_date_xref where benchmark_end = temp_table.benchmark_end) and screening_date in (select distinct screening_date from campaign_spot where campaign_no = temp_table.campaign_no)) as total_attendance,
					count(spot_id) as no_spots,
					sum(spot_collections) as total_billings,
					sum(spot_attendance)  as attendance,
					(select count(complex_id) from aaa_old_screenvista where complex_id = temp_table.complex_id) as screen_vista_or_not
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
										cplx.film_market_no,
										film_market_desc,
										cplx.complex_name,
										(select sum(isnull(cinema_amount,0)) from spot_liability where spot_liability.spot_id = campaign_spot.spot_id and spot_liability.liability_type <> 3) as spot_collections,
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
										exhibitor,
										film_market
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
					and				film_market.film_market_no = cplx.film_market_no
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
										cplx.film_market_no,
										film_market_desc,
										cplx.complex_id,
										cplx.complex_name) as temp_table
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
							complex_name,
							film_market_no,
							film_market_desc,
							complex_id							



GO
