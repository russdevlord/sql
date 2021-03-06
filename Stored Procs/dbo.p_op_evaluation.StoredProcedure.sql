/****** Object:  StoredProcedure [dbo].[p_op_evaluation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_evaluation]
GO
/****** Object:  StoredProcedure [dbo].[p_op_evaluation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_evaluation]  @campaign_no 	int

as

-- Return Campaign Evaluation
select 		@campaign_no,
			fc.product_desc,   
			fc.campaign_status,
			min(screening_date),
			max(screening_date),
			client_name,
			agency_name,
			country_name,
			country.country_code,
			outpost_package.package_code,
			package_desc,
			screening_date,
			outpost_venue_name,
			outpost_panel_desc,
			film_market.film_market_no,
			film_market_desc,
			(select isnull(sum(showings),0) from outpost_attendance_panel_actuals where outpost_panel_id = outpost_spot.outpost_panel_id and screening_date = outpost_spot.screening_date and campaign_no = outpost_spot.campaign_no) as showings,
			(select max(screening_date) from outpost_attendance_panel_actuals where campaign_no = outpost_spot.campaign_no) as showings_date
from 		film_campaign fc,
			agency,
			client,
			outpost_spot,
			outpost_package,
			outpost_panel,
			outpost_venue,
			film_market,
			branch,
			country
where 		fc.campaign_no = @campaign_no
and			fc.agency_id = agency.agency_id
and			fc.client_id = client.client_id
and			fc.campaign_no = outpost_package.campaign_no
and			fc.campaign_no = outpost_spot.campaign_no
and			outpost_spot.campaign_no = outpost_package.campaign_no
and			outpost_spot.package_id = outpost_package.package_id
and			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
and			outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
and			outpost_venue.market_no = film_market.film_market_no
and			outpost_venue.branch_code = branch.branch_code
and			branch.country_code = country.country_code
and			spot_status = 'X'
group by 	fc.product_desc,   
			fc.campaign_status,
			client_name,
			agency_name,
			country_name,
			country.country_code,
			outpost_package.package_code,
			package_desc,
			screening_date,
			outpost_venue_name,
			outpost_panel_desc,
			film_market.film_market_no,
			film_market_desc,
			outpost_spot.outpost_panel_id,
			outpost_spot.campaign_no

return 0
GO
