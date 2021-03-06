/****** Object:  StoredProcedure [dbo].[p_cinelight_evaluation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_evaluation]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_evaluation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_cinelight_evaluation]  @campaign_no 	int

as

/*
 * Return Campaign Evaluation
 */

select 			campaign_no,
				product_desc,   
				campaign_status,
				min_screening_date,
				max_screening_date,
				client_name,
				agency_name,
				country_name,
				country_code,
				package_code,
				package_desc,
				screening_date,
				film_market_no,
				film_market_desc,
				sum(showings_all) as showings,
				max(showings_date_all) as showings_date,
				count(cinelight_desc) as screenings
		from	(select 		fc.campaign_no,
								fc.product_desc,   
								fc.campaign_status,
								(select min(screening_date) from cinelight_spot where package_id = cinelight_package.package_id) as min_screening_date,
								(select max(screening_date) from cinelight_spot where package_id = cinelight_package.package_id) as max_screening_date,
								client_name,
								agency_name,
								country_name,
								country.country_code,
								cinelight_package.package_code,
								package_desc,
								screening_date,
								complex_name,
								cinelight_desc,
								film_market.film_market_no,
								film_market_desc,
								(select isnull(sum(showings),0) from cinelight_attendance_digilite_actuals where cinelight_id = cinelight_spot.cinelight_id and screening_date = cinelight_spot.screening_date and campaign_no = cinelight_spot.campaign_no) as showings_all,
								(select max(screening_date) from cinelight_attendance_digilite_actuals where campaign_no = cinelight_spot.campaign_no) as showings_date_all
					from 		film_campaign fc,
								agency,
								client,
								cinelight_spot,
								cinelight_package,
								cinelight,
								complex,
								film_market,
								branch,
								country
					where 		fc.campaign_no = @campaign_no
					and			fc.agency_id = agency.agency_id
					and			fc.client_id = client.client_id
					and			fc.campaign_no = cinelight_package.campaign_no
					and			fc.campaign_no = cinelight_spot.campaign_no
					and			cinelight_spot.campaign_no = cinelight_package.campaign_no
					and			cinelight_spot.package_id = cinelight_package.package_id
					and			cinelight_spot.cinelight_id = cinelight.cinelight_id
					and			cinelight.complex_id = complex.complex_id
					and			complex.film_market_no = film_market.film_market_no
					and			complex.branch_code = branch.branch_code
					and			branch.country_code = country.country_code
					and			spot_status = 'X'
					group by 	fc.campaign_no,
								fc.product_desc,   
								fc.campaign_status,
								client_name,
								agency_name,
								country_name,
								country.country_code,
								cinelight_package.package_code,
								package_desc,
								screening_date,
								complex_name,
								cinelight_desc,
								film_market.film_market_no,
								film_market_desc,
								cinelight_spot.cinelight_id,
								cinelight_spot.campaign_no,
								cinelight_spot.spot_id,
								cinelight_package.package_id) as temp_table
group by 	campaign_no,
			product_desc,   
			campaign_status,
			min_screening_date,
			max_screening_date,
			client_name,
			agency_name,
			country_name,
			country_code,
			package_code,
			package_desc,
			screening_date,
			film_market_no,
			film_market_desc
			
/*
 * Return Success
 */

return 0
GO
