/****** Object:  View [dbo].[v_Outdoor_bookings_detail]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_Outdoor_bookings_detail]
GO
/****** Object:  View [dbo].[v_Outdoor_bookings_detail]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[v_Outdoor_bookings_detail] AS
SELECT	Distinct 	booking_figures.campaign_no,
					film_campaign.product_desc,
					v_statrev.business_unit_desc,
					booking_figures.nett_amount AS bookings,
					booking_figures.booking_period,
					sales_rep.first_name + ' ' + sales_rep.last_name AS Sales_rep,
					--'Sales Rep' AS sales_rep,
					booking_figures.branch_code, 
					branch.branch_name
FROM		booking_figures,
			v_statrev,
			film_campaign,
			sales_rep,
			branch
WHERE	booking_figures.campaign_no = film_campaign.campaign_no
and				booking_figures.branch_code = branch.branch_code
and				booking_figures.rep_id = sales_rep.rep_id
and				v_statrev.campaign_no = film_campaign.campaign_no
and booking_period >= '01-June-2011'
and v_statrev.master_revenue_group_desc IN ('Retail', 'Petro','Petro Panel','Petro CStore')
GO
