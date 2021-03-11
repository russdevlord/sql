USE [production]
GO
/****** Object:  View [dbo].[v_film_revenue_after_jan_2012]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_film_revenue_after_jan_2012]
as
SELECT        liability_category.liability_category_desc, liability_category.billing_group, liability_category.collect_group, liability_type.liability_type_desc, 
                        film_revenue.campaign_no, film_revenue.complex_id, film_revenue.country_code, film_revenue.product_desc, film_revenue.accounting_period, 
                        sum(film_revenue.cinema_amount) as cinema_amount, exhibitor.exhibitor_name, complex.complex_name
FROM            film_revenue,
                        complex ,
                        exhibitor,
						liability_type,
                        liability_category
where				liability_type.liability_category_id = liability_category.liability_category_id
and					complex.exhibitor_id = exhibitor.exhibitor_id 
and					complex.complex_id = film_revenue.complex_id
and					liability_type.liability_type_id = film_revenue.liability_type_id
and					film_revenue.accounting_period > '1-jul-2010'
group by	 liability_category.liability_category_desc, liability_category.billing_group, liability_category.collect_group, liability_type.liability_type_desc, 
                        film_revenue.campaign_no, film_revenue.complex_id, film_revenue.country_code, film_revenue.product_desc, film_revenue.accounting_period, 
                         exhibitor.exhibitor_name, complex.complex_name



GO
