USE [production]
GO
/****** Object:  View [dbo].[v_blake_film_revenue]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view	[dbo].[v_blake_film_revenue]
as
SELECT        film_revenue.complex_id, film_revenue.origin_period, film_revenue.accounting_period, film_revenue.revenue_source, 
                         film_revenue.business_unit_id, film_revenue.liability_type_id,
                         film_revenue.currency_code, sum(film_revenue.cinema_amount) as weighted_revenue, sum(film_revenue.spot_amount) as unweighted_revenue, 
                           liability_type.liability_type_desc, liability_category.liability_category_desc, 
                          complex.complex_name, complex.branch_code, complex.state_code, complex.complex_region_class, exhibitor.exhibitor_name
FROM            film_revenue INNER JOIN
                         liability_type ON film_revenue.liability_type_id = liability_type.liability_type_id INNER JOIN
                         liability_category ON liability_type.liability_category_id = liability_category.liability_category_id INNER JOIN
                         complex ON film_revenue.complex_id = complex.complex_id INNER JOIN
                         exhibitor ON complex.exhibitor_id = exhibitor.exhibitor_id 
group by			 film_revenue.complex_id, film_revenue.origin_period, film_revenue.accounting_period, film_revenue.revenue_source, 
                         film_revenue.business_unit_id, film_revenue.liability_type_id,
                         film_revenue.currency_code, 
                           liability_type.liability_type_desc, liability_category.liability_category_desc, 
                          complex.complex_name, complex.branch_code, complex.state_code, complex.complex_region_class, exhibitor.exhibitor_name


GO
