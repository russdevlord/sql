/****** Object:  View [dbo].[v_cinema_rate_spot_attendance_bill_two]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinema_rate_spot_attendance_bill_two]
GO
/****** Object:  View [dbo].[v_cinema_rate_spot_attendance_bill_two]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_cinema_rate_spot_attendance_bill_two]
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
					screening_date,
					film_market_no,
					film_market_desc,
					(select sum(attendance) from movie_history where complex_id in (select complex_id from complex where film_market_no = temp_table.film_market_no)  and screening_date = temp_table.screening_date) as total_attendance,
					(select sum(attendance) from movie_history where complex_id in (select complex_id from complex where film_market_no = temp_table.film_market_no)  and screening_date = temp_table.screening_date and complex_id not in (select complex_id from aaa_old_screenvista)) as total_attendance_non_vista,
					(select sum(attendance) from movie_history where complex_id in (select complex_id from complex where film_market_no = temp_table.film_market_no)  and screening_date = temp_table.screening_date and complex_id  in (select complex_id from aaa_old_screenvista)) as total_attendance_vista,
					count(spot_id) as no_spots,
					sum(spot_collections) as total_billings,
					sum(spot_attendance)  as campaign_attendance,
					sum(spot_non_vista_attendance)  as campaign_non_vista_attendance,
					sum(spot_vista_attendance)  as campaign_vista_attendance
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
										campaign_spot.screening_date,
										exhibitor_name,
										spot_id,
										cplx.complex_id,
										cplx.film_market_no,
										film_market_desc,
										cplx.complex_name,
										(select sum(isnull(cinema_amount,0)) from spot_liability where spot_liability.spot_id = campaign_spot.spot_id and spot_liability.liability_type <> 3) as spot_collections,
										(select sum(attendance) from v_certificate_item_distinct, movie_history where v_certificate_item_distinct.certificate_group =  movie_history.certificate_group and spot_reference = campaign_spot.spot_id) as spot_attendance,
										(select sum(attendance) from v_certificate_item_distinct, movie_history where v_certificate_item_distinct.certificate_group =  movie_history.certificate_group and spot_reference = campaign_spot.spot_id and complex_id in (select complex_id from aaa_old_screenvista) ) as spot_vista_attendance,
										(select sum(attendance) from v_certificate_item_distinct, movie_history where v_certificate_item_distinct.certificate_group =  movie_history.certificate_group and spot_reference = campaign_spot.spot_id and complex_id not in (select complex_id from aaa_old_screenvista)) as spot_non_vista_attendance
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
										campaign_spot.screening_date,
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
							screening_date,
							film_market_no,
							film_market_desc				




GO
