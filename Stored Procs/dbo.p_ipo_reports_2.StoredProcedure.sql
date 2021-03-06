/****** Object:  StoredProcedure [dbo].[p_ipo_reports_2]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_ipo_reports_2]
GO
/****** Object:  StoredProcedure [dbo].[p_ipo_reports_2]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_ipo_reports_2]

as

declare     @error          int

set nocount on

create table #revenue
(
campaign_no                     int         null,
revision_transaction_type       int         null,
revenue_period                  datetime    null,
billing_date                    datetime    null,
cost                            money       null,
units                           int         null,
business_unit_id                int         null,
booking_period                  datetime    null,
booking                         money       null
)

insert into #revenue
SELECT 		campaign_no = campaign_spot.campaign_no,   
			revision_transaction_type = 1,
			revenue_period = ( 	SELECT 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
			billing_date = campaign_spot.billing_date,   
			cost = sum ( campaign_spot.charge_rate ),   
			units = count(*) ,
            film_campaign.business_unit_id,
            booking_period,
            sum(nett_amount)
FROM 		campaign_spot,
			campaign_package,
            film_campaign,
            booking_figures
WHERE 		campaign_package.package_id = campaign_spot.package_id
AND 		campaign_spot.spot_status != 'P'
and         film_campaign.campaign_no = campaign_spot.campaign_no
and         film_campaign.branch_code <> 'Z'
and         campaign_package.media_product_id = 1
and         film_campaign.campaign_no = booking_figures.campaign_no
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.billing_date,
			campaign_package.media_product_id,
            film_campaign.business_unit_id,
            booking_period
HAVING  	sum(campaign_spot.rate) <> 0 
OR			sum(campaign_spot.charge_rate) <> 0     
OR			sum(campaign_spot.makegood_rate) <> 0 
union
SELECT 		campaign_no = campaign_spot.campaign_no,   
			revision_transaction_type = 4,
			revenue_period = ( 	SELECT 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
			billing_date = campaign_spot.billing_date,   
			cost = sum ( campaign_spot.charge_rate ),   
			units = count(*) ,
            film_campaign.business_unit_id,
            booking_period,
            sum(nett_amount)
FROM 		campaign_spot,
			campaign_package,
            film_campaign,
            booking_figures 
WHERE 		campaign_package.package_id = campaign_spot.package_id
AND 		campaign_spot.spot_status != 'P'
and         film_campaign.campaign_no = campaign_spot.campaign_no
and         film_campaign.branch_code <> 'Z'
and         campaign_package.media_product_id = 2
and         film_campaign.campaign_no = booking_figures.campaign_no
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.billing_date,
			campaign_package.media_product_id,
            film_campaign.business_unit_id,
            booking_period
HAVING  	sum(campaign_spot.rate) <> 0 
OR			sum(campaign_spot.charge_rate) <> 0     
OR			sum(campaign_spot.makegood_rate) <> 0 


/* 2. Film TakeOut */

INSERT 		#revenue
SELECT 		campaign_no = inclusion_spot.campaign_no,   
			revision_transaction_type = 2, 
			inclusion_spot.revenue_period,
			billing_date = (select 	max(screening_date) 
				from 	film_screening_date_xref fdx
				WHERE 	fdx.benchmark_end = inclusion_spot.revenue_period),   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),  
			units = count(*),
            film_campaign.business_unit_id,
            null,
            0
FROM 		inclusion_spot,
            inclusion,
            film_campaign
WHERE		inclusion.campaign_no = film_campaign.campaign_no
AND  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and         film_campaign.branch_code <> 'Z'
AND 		inclusion_spot.spot_status != 'P'
AND 		inclusion.inclusion_category = 'F'
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.revenue_period,
            film_campaign.business_unit_id


/* 3. FILM Billing Credits & Bad Debts */

INSERT 		#revenue
SELECT 		campaign_no = campaign_spot.campaign_no,   
			revision_transaction_type = 3, 
			revenue_period = spot_liability.creation_period  ,
			billing_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx
							WHERE 	fdx.benchmark_end = spot_liability.creation_period),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
            film_campaign.business_unit_id,
            null,
            0
FROM 		campaign_spot,
			spot_liability,
            film_campaign
WHERE		campaign_spot.campaign_no = film_campaign.campaign_no
AND 		campaign_spot.spot_status != 'P'
AND 		spot_liability.liability_type = 7 
AND 		campaign_spot.spot_id  = spot_liability.spot_id
GROUP BY	campaign_spot.campaign_no,
			spot_liability.creation_period,
            film_campaign.business_unit_id


/* 5. DMG TakeOut */

INSERT 		#revenue
SELECT 		campaign_no = inclusion_spot.campaign_no,   
			revision_transaction_type = 5, 
			inclusion_spot.revenue_period,
			billing_date = (select 	max(screening_date) 
				from 	film_screening_date_xref fdx
				WHERE 	fdx.benchmark_end = inclusion_spot.revenue_period),   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),  
			units = count(*),
            film_campaign.business_unit_id,
            null,
            0
FROM 		inclusion_spot,
            inclusion,
            film_campaign
WHERE		inclusion.campaign_no = film_campaign.campaign_no
AND  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and         film_campaign.branch_code <> 'Z'
AND 		inclusion_spot.spot_status != 'P'
AND 		inclusion.inclusion_category = 'D'
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.revenue_period,
            film_campaign.business_unit_id

/* 6. DMG Billing Credits */

INSERT 		#revenue
SELECT 		campaign_no = campaign_spot.campaign_no,   
			revision_transaction_type = 6, 
			revenue_period = spot_liability.creation_period  ,
			billing_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx
							WHERE 	fdx.benchmark_end = spot_liability.creation_period),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
            film_campaign.business_unit_id,
            null,
            0
FROM 		campaign_spot,
			spot_liability,
            film_campaign
WHERE		campaign_spot.campaign_no = film_campaign.campaign_no
AND 		campaign_spot.spot_status != 'P'
AND 		spot_liability.liability_type = 8 
AND 		campaign_spot.spot_id  = spot_liability.spot_id
GROUP BY	campaign_spot.campaign_no,
			spot_liability.creation_period,
            film_campaign.business_unit_id


select      campaign_no,
            revision_transaction_type_desc,
            revenue_period,
            sum(cost) as revenue,
            business_unit_desc,
            booking_period,
            sum(booking) as booking
from        #revenue,
            business_unit,
            revision_transaction_type
where       revenue_period > '1-jul-2007'
and         revision_transaction_type.revision_transaction_type = #revenue.revision_transaction_type
and         #revenue.business_unit_id = business_unit.business_unit_id
group by    campaign_no,
            revision_transaction_type_desc,
            revenue_period,
            business_unit_desc,
            booking_period
having      sum(cost) <> 0
GO
