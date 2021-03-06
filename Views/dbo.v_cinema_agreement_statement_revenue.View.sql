/****** Object:  View [dbo].[v_cinema_agreement_statement_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinema_agreement_statement_revenue]
GO
/****** Object:  View [dbo].[v_cinema_agreement_statement_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view	[dbo].[v_cinema_agreement_statement_revenue]
as
SELECT        cinema_agreement_revenue.cinema_agreement_id, cinema_agreement_revenue.complex_id, cinema_agreement_revenue.accounting_period, 
                         cinema_agreement_revenue.origin_period, cinema_agreement_revenue.release_period, cinema_agreement_revenue.revenue_source, 
                         cinema_agreement_revenue.business_unit_id, cinema_agreement_revenue.liability_type_id, cinema_agreement_revenue.policy_id, 
                         cinema_agreement_revenue.currency_code, cinema_agreement_revenue.cag_entitlement_id, cinema_agreement_revenue.cinema_amount, 
                         cinema_agreement_revenue.percentage_entitlement, cinema_agreement_revenue.agreement_days, cinema_agreement_revenue.period_days, 
                         cinema_agreement_revenue.excess_status, cinema_agreement_revenue.cancelled, liability_type.liability_type_desc, liability_category.liability_category_desc, 
                         cinema_agreement_revenue.revenue_id, cinema_agreement.agreement_no, cinema_agreement.agreement_desc, complex.complex_name, complex.branch_code, complex.state_code, complex.complex_region_class
FROM            cinema_agreement_revenue INNER JOIN
                         liability_type ON cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id INNER JOIN
                         liability_category ON liability_type.liability_category_id = liability_category.liability_category_id INNER JOIN
                         cinema_agreement ON cinema_agreement_revenue.cinema_agreement_id = cinema_agreement.cinema_agreement_id INNER JOIN
                         complex ON cinema_agreement_revenue.complex_id = complex.complex_id
WHERE        (cinema_agreement_revenue.cancelled = 'N') AND (liability_category.billing_group = 'Y') AND (liability_category.collect_group = 'N')
and cinema_agreement_revenue.accounting_period > '1-jan-2013'


GO
