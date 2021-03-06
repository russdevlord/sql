/****** Object:  View [dbo].[V_Tableau_Campaign_Ending]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[V_Tableau_Campaign_Ending]
GO
/****** Object:  View [dbo].[V_Tableau_Campaign_Ending]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[V_Tableau_Campaign_Ending] AS
select 	 fc.campaign_no
		,fc.product_desc
		,fc.start_date
		,fc.end_date
		,fc.makeup_deadline
		,fc.branch_code
		,branch.branch_name
		,fc.client_id 
		,sr.first_name
		,sr.last_name
		,sr.rep_id
		,pc.product_category_id
		,pc.product_category_desc
		,branch.country_code
		from film_campaign as fc
		inner join branch ON fc.branch_code = branch.branch_code
		inner join campaign_type as ct on ct.campaign_type_code = fc.campaign_type
		inner join campaign_status as cs on cs.campaign_status_code = fc.campaign_status
		inner join film_campaign_category as fcc on fcc.campaign_category_code = fc.campaign_category
		inner join sales_rep as sr on sr.rep_id = fc.rep_id
		inner Join v_campaign_product_category ON v_campaign_product_category.campaign_no = fc.campaign_no
		inner Join product_category as pc ON v_campaign_product_category.product_category = pc.product_category_id
		where 1=1 
		and fc.end_date >= GETDATE() 
		and fc.end_date <= '01-01-2016'    


GO
