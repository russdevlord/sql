/****** Object:  View [dbo].[v_wes_rep_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_wes_rep_revenue]
GO
/****** Object:  View [dbo].[v_wes_rep_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_wes_rep_revenue] as
select  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev.branch_name,v_statrev.business_unit_desc, v_statrev.master_revenue_group_desc, v_statrev.revenue_group_desc, v_statrev.statrev_transaction_type_desc, product_category.product_category_desc,v_statrev.revenue_period, (sales_rep.first_name + ' ' + sales_rep.last_name) as rep_name,sum(cost * rep_share) as rev
from    client, client_group, v_statrev, film_campaign, agency, agency_groups, agency_buying_groups, v_campaign_product_category, product_category, v_rep_book_camp, sales_rep
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and     v_campaign_product_category.product_category = product_category.product_category_id
and     v_campaign_product_category.campaign_no = film_campaign.campaign_no
and business_unit_desc = 'Agency Sales Dept' 
and branch_name in ('South Australia','Western Australia')
and revenue_period > '1-jul-2009'
and		v_rep_book_camp.campaign_no = v_statrev.campaign_no
and		v_rep_book_camp.rep_id = sales_rep.rep_id
group by client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev.revenue_group_desc,v_statrev.branch_name,v_statrev.business_unit_desc, v_statrev.master_revenue_group_desc, v_statrev.revenue_group_desc, v_statrev.statrev_transaction_type_desc, v_statrev.revenue_period, product_category.product_category_desc, sales_rep.first_name, sales_rep.last_name
GO
