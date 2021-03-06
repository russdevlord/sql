/****** Object:  View [dbo].[v_campaign_product]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_product]
GO
/****** Object:  View [dbo].[v_campaign_product]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_campaign_product] 
AS
select      max(product_category) as  product_category_id,
            campaign_no
from        (SELECT 	product_category,
            campaign_no
            FROM 	campaign_package
            union 
            SELECT 	product_category,
            campaign_no
            FROM 	cinelight_package
            union       
            SELECT 	product_category_id,
            campaign_no
            FROM 	inclusion
            where   product_category_id is not null
            union 
            SELECT 	product_category,
            campaign_no
            FROM 	outpost_package) as temp_table
group by    campaign_no
GO
