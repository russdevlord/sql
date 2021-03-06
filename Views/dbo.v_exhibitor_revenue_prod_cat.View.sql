/****** Object:  View [dbo].[v_exhibitor_revenue_prod_cat]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_exhibitor_revenue_prod_cat]
GO
/****** Object:  View [dbo].[v_exhibitor_revenue_prod_cat]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_exhibitor_revenue_prod_cat]
as
select film_revenue.campaign_no, film_revenue.product_desc,accounting_period, exhibitor_name, liability_type_desc, client_name, sum(cinema_amount) as cin_amt_sum
from film_revenue, complex, liability_type, exhibitor, film_campaign, client
where film_revenue.complex_id = complex.complex_id 
and film_revenue.liability_type_id = liability_type.liability_type_id
--and (complex_name like '%palace%' or complex_name like '%chauvel%' or complex_name like '%kino%')
and complex.exhibitor_id = exhibitor.exhibitor_id
and accounting_period > '1-jan-2019'
and film_revenue.campaign_no = film_campaign.campaign_no
and film_campaign.client_id = client.client_id
group by film_revenue.campaign_no, film_revenue.product_desc,accounting_period, exhibitor_name, liability_type_desc, client_name
GO
