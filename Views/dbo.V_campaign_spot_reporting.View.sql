/****** Object:  View [dbo].[V_campaign_spot_reporting]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[V_campaign_spot_reporting]
GO
/****** Object:  View [dbo].[V_campaign_spot_reporting]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




--DROP VIEW [V_campaign_spot_reporting]

Create View [dbo].[V_campaign_spot_reporting]
AS

SELECT      a.type, 
			CASE 
                WHEN a.type = 'Digilite' THEN 7 
                WHEN a.type = 'Cinema Onscreen' THEN 1 
                WHEN a.type = 'Cinemarketing' THEN 10
            END as Type_ID, 
            Sum(charge_rate_sum) / SUM(a.no_spots) as Avg_Rate, 
            SUM(a.no_spots) as no_spots, 
            a.campaign_no, 
            SUM(charge_rate_sum) as revenue, 
            c.campaign_type_desc as Campaign_type, 
            sum(a.Campaign_value) asCampaign_value, 
            AVG(a.charge_rate) as effective_rate, 
            avg(convert(numeric(7,2),a.avg_duration)) as avg_duration,
            AVG(a.charge_rate) / avg(convert(numeric(7,2),a.avg_duration)) * 30 as effective_30_sec_rate,
            buying_group_desc,
            agency_buying_groups.buying_group_id,
            agency_group_name,
            agency_groups.agency_group_id,
            agency_name,
            agency.agency_id,
            client_name,
            client_group.client_group_desc,
            client.client_id,
            client_product.client_product_desc,
            client_product.client_product_id ,
            b.product_desc 
FROM        [v_all_cinema_spots_fj] a JOIN
                      film_campaign b ON a.campaign_no = b.campaign_no
                      JOIN campaign_type c ON b.campaign_type = c.campaign_type_code                
                JOIN agency on agency.agency_id = b.reporting_agency
                join agency_groups on agency.agency_group_id = agency_groups.agency_group_id
                join agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
                join client on b.reporting_client = client.client_id
                join client_group on client_group.client_group_id = client.client_group_id
                join client_product on client_product.client_id = client.client_id
WHERE  type NOT IN ('takeouts') AND a.spot_type IN ('B', 'C', 'D', 'S')
			AND a.billing_period >= '25-Jul-2012'
GROUP BY    a.type, 
            a.campaign_no, 
            campaign_type_desc,
            buying_group_desc,
            agency_buying_groups.buying_group_id,
            agency_group_name,
            agency_groups.agency_group_id,
            agency_name,
            agency.agency_id,
            client_name,
            client_group.client_group_desc,
            client.client_id,
            client_product.client_product_desc,
            client_product.client_product_id
             ,
            b.product_desc 
UNION ALL
SELECT      a.Type, 
            CASE 
                WHEN a.type = 'Petro Panel' THEN 200 
                WHEN a.type = 'Retail Wall' THEN 103 
                WHEN a.type = 'Retail Superscreen' THEN 106 
                WHEN a.type = 'Retail Panels' THEN 100 
                WHEN a.type = 'Sports' THEN 250 
                WHEN a.type = 'Petro CStore' THEN 207 
            END as Type_ID, 
            sum(charge_rate_sum) / SUM(a.no_spots) as Avg_Rate, 
            SUM(a.no_spots) as no_spots, 
            a.campaign_no, 
            SUM(charge_rate_sum) as revenue, 
            c.campaign_type_desc As Campaign_type, 
            sum(a.Campaign_value) as Campaign_value, 
            AVG(a.charge_rate) Effective_rate, 
            NULL as avg_duration,
            NULL as effective_30_sec_rate,
            buying_group_desc,
            agency_buying_groups.buying_group_id,
            agency_group_name,
            agency_groups.agency_group_id,
            agency_name,
            agency.agency_id,
            client_name,
            client_group.client_group_desc,
            client.client_id,
            client_product.client_product_desc,
            client_product.client_product_id,
            b.product_desc 
FROM        v_all_retail_spots_fj a 
                JOIN film_campaign b ON a.campaign_no = b.campaign_no
                JOIN campaign_type c ON b.campaign_type = c.campaign_type_code
                JOIN agency on agency.agency_id = b.reporting_agency
                join agency_groups on agency.agency_group_id = agency_groups.agency_group_id
                join agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
                join client on b.reporting_client = client.client_id
                join client_group on client_group.client_group_id = client.client_group_id
                join client_product on client_product.client_id = client.client_id
WHERE  type NOT IN ('takeouts') AND a.spot_type IN ('B', 'C', 'D', 'S')
AND a.billing_period >= '25-Jul-2012'
GROUP BY    a.type, 
            a.campaign_no, 
            campaign_type_desc,
            buying_group_desc,
            agency_buying_groups.buying_group_id,
            agency_group_name,
            agency_groups.agency_group_id,
            agency_name,
            agency.agency_id,
            client_name,
            client_group.client_group_desc,
            client.client_id,
            client_product.client_product_desc,
            client_product.client_product_id,
            b.product_desc 



GO
