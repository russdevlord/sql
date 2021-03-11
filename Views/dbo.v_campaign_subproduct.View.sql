USE [production]
GO
/****** Object:  View [dbo].[v_campaign_subproduct]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_campaign_subproduct] 
AS
select      max(product_subcategory) as  product_category_id,
            campaign_no
from        (SELECT 	product_subcategory,
            campaign_no
            FROM 	campaign_package
           where  product_subcategory is not null
            union 
            SELECT 	product_subcategory,
            campaign_no
            FROM 	cinelight_package
           where  product_subcategory is not null
            union       
            SELECT 	product_subcategory,
            campaign_no
            FROM 	inclusion
           where  product_subcategory is not null
            union 
            SELECT 	product_subcategory,
            campaign_no
            FROM 	outpost_package
                      where  product_subcategory is not null) as temp_table
group by    campaign_no
GO
