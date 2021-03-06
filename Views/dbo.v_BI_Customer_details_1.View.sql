/****** Object:  View [dbo].[v_BI_Customer_details_1]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_BI_Customer_details_1]
GO
/****** Object:  View [dbo].[v_BI_Customer_details_1]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create View [dbo].[v_BI_Customer_details_1]
AS
select DISTINCT Sum(revenue)AS Revenue,
			revenue_period,
            buying_group_desc,
            datepart(yy, temp_table.start_date) as year,
            client_group_desc,
            client_name,
            client_product_desc,
            temp_table.campaign_no,
            branch_name,
            Campaign_Count,
            product_desc,
            reporting,
            product_category,
            a.type,
			a.Avg_Rate, 
			a.no_spots,          
            case  when client_group_desc like '%Govern%' then client_group_desc else product_category end 'client_product_category_combo'
FROM        (
SELECT sum (cost) as revenue,
                        v_statrev.revenue_period,
                        agency_buying_groups.buying_group_desc,
                        agency_status = agency_buying_groups.status,
                        client_name,
                        Count(Distinct film_campaign.campaign_no) campaign_count,
                        v_statrev.product_desc,
                        agency.agency_name 'reporting',
                        accounting_period.finyear_end ,
                        client_group.client_group_desc,
                        client_product.client_product_desc,
                        branch.branch_name,
                        film_campaign.campaign_no,
                        film_campaign.start_date,
                        statrev_transaction_type.statrev_transaction_type_desc,
                        statrev_transaction_type.statrev_transaction_type,
                        (select product_category_desc from product_category where product_category_id in (select max(product_category) from v_campaign_product_category where campaign_no = film_campaign.campaign_no)) as product_category
            FROM        campaign_revision,   
                        film_campaign,   
                        v_statrev,   
                        statrev_transaction_type,
                        agency, 
                        agency_buying_groups, 
                        agency_groups,
                        client,
                        client_group,
                        agency agency2 ,
                        agency agency3 ,
                        accounting_period,
                        branch,
                        client_product            
            WHERE       film_campaign.campaign_no = campaign_revision.campaign_no
            and         v_statrev.revision_id = campaign_revision.revision_id
            and         v_statrev.transaction_type = statrev_transaction_type.statrev_transaction_type
            and         film_campaign.branch_code <> 'Z' 
            and         film_campaign.client_product_id = client_product.client_product_id
            and         film_campaign.reporting_agency = agency.agency_id
            and         branch.branch_code = film_campaign.branch_code
            and         agency.agency_group_id = agency_groups.agency_group_id
            and         agency_buying_groups.buying_group_id =  agency_groups.buying_group_id
            and         film_campaign.client_id = client.client_id
            and         v_statrev.revenue_period = accounting_period.benchmark_end
            and			v_statrev.campaign_no = film_campaign.campaign_no
            and         client.client_group_id = client_group.client_group_id
            --and         v_statrev.business_unit_id = 2
            and			film_campaign.campaign_status <> 'P'
            GROUP BY    v_statrev.revenue_period,
                        agency_buying_groups.buying_group_desc,
                        agency_buying_groups.status,
                        client_name,
                        client_product.client_product_desc,
                        film_campaign.campaign_no,
                        v_statrev.product_desc,
                        agency.agency_name ,
                        agency2.agency_name,
                        agency3.agency_name ,
                        accounting_period.finyear_end ,
                        client_group.client_group_desc,
                        statrev_transaction_type.statrev_transaction_type,
                        branch.branch_name, 
                        film_campaign.start_date,
                        statrev_transaction_type.statrev_transaction_type_desc) as temp_table
JOIN v_bi_Campaign_Spots a
ON temp_table.campaign_no = a.campaign_no
AND temp_table.statrev_transaction_type = a.type_id
WHERE      temp_table.start_date BETWEEN '1-Jan-2009' AND '31-OCT-2013'
Group BY
temp_table.revenue_period,
            buying_group_desc,
            client_group_desc,
            client_name,
            client_product_desc,
            temp_table.campaign_no,
            branch_name,
            Campaign_Count,
            product_desc,
            reporting,
            statrev_transaction_type_desc,
            product_category,
            a.type,
			a.Avg_Rate,
			a.no_spots,
			start_date
GO
