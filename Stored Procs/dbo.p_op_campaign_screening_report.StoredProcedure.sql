/****** Object:  StoredProcedure [dbo].[p_op_campaign_screening_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_campaign_screening_report]
GO
/****** Object:  StoredProcedure [dbo].[p_op_campaign_screening_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_op_campaign_screening_report]			@from_screening_date				DATETIME,
																																		@to_screening_date					DATETIME,
																																		@business_unit_id						int
																																		
AS

SET NOCOUNT ON;

		SELECT
		fc.campaign_no
		,fc.product_desc
		,fc.revision_no
		,fc.campaign_status
		,fc.cinelight_status
		,fc.inclusion_status
		,fc.outpost_status
		,fc.campaign_type
		,fc.includes_media
		,fc.includes_cinelights
		,fc.includes_infoyer
		,fc.includes_miscellaneous
		,fc.includes_follow_film
		,fc.includes_premium_position
		,fc.includes_gold_class
		,fc.includes_retail
		,fc.agency_deal
		,a.agency_name
		,c.client_name
		,c.contact
		,fc.confirmed_date
		,fc.billing_start_date
		,fc.start_date
		,fc.end_date
		,fc.makeup_deadline
		,fc.expired_date
		,fc.closed_date
		,fc.confirmed_cost
		,fc.confirmed_value
		,fc.campaign_cost
		,fc.campaign_value
		,fc.balance_outstanding
		,fc.balance_credit
		,fc.balance_current
		,sr.first_name + ' ' + sr.last_name as sales_rep
		,sr.email
		,sr.business_unit_id
		FROM film_campaign AS fc
		INNER JOIN client AS c ON c.client_id = fc.client_id
		INNER JOIN sales_rep AS sr ON sr.rep_id = fc.rep_id
		inner join agency as a on a.agency_id = fc.agency_id
		INNER JOIN (SELECT campaign_no
					FROM (SELECT  campaign_no
						  FROM    outpost_spot
                          where     screening_date BETWEEN @from_screening_date AND @to_screening_date
						  GROUP BY campaign_no) AS temp_table
					GROUP BY  temp_table.campaign_no) AS cs ON cs.campaign_no = fc.campaign_no
		WHERE     campaign_status <> 'P'
and	(@business_unit_id = 0 
or	fc.business_unit_id = @business_unit_id)
		order by fc.campaign_no

return 0
GO
