/****** Object:  View [dbo].[v_bookings_detail]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bookings_detail]
GO
/****** Object:  View [dbo].[v_bookings_detail]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




Create View [dbo].[v_bookings_detail] AS
SELECT	Distinct 	booking_figures.campaign_no,
					film_campaign.product_desc,
					business_unit.business_unit_desc,
					booking_figures.nett_amount AS bookings,
					booking_figures.booking_period,
					sales_rep.first_name + ' ' + sales_rep.last_name AS Sales_rep,
					--'Sales Rep' AS sales_rep,
					booking_figures.branch_code, 
					branch.branch_name
FROM		booking_figures,
			business_unit,
			film_campaign,
			sales_rep,
			branch
WHERE	booking_figures.campaign_no = film_campaign.campaign_no
and				booking_figures.branch_code = branch.branch_code
and				booking_figures.rep_id = sales_rep.rep_id
and				business_unit.business_unit_id = film_campaign.business_unit_id
and booking_period >= '01-June-2011'
and		film_campaign.business_unit_id not in (6,7,8)



GO
