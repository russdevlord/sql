/****** Object:  View [dbo].[v_product_category_combined]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_product_category_combined]
GO
/****** Object:  View [dbo].[v_product_category_combined]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_product_category_combined]
as
select product_category_sub_concat_id, 'No Product Category' as product_category_desc, '[00]' as product_code, 1 as active, 1 as sub_active 
from product_category_sub_concat
where product_category_id is null
and product_subcategory_id is null
union
select product_category_sub_concat_id, '[' + product_code + '] - ' + ltrim(rtrim(product_category_desc)), product_code, active, 1 as sub_active 
from product_category_sub_concat
inner join product_category on product_category_sub_concat.product_category_id = product_category.product_category_id
where product_subcategory_id is null
union
select product_category_sub_concat_id, '[' + product_code + '] - ' + ltrim(rtrim(product_category_desc)) + ' - [' + ltrim(rtrim(product_subcategory_desc)) + ']', product_code, product_category.active, product_subcategory.active as sub_active 
from product_category_sub_concat
inner join product_category on product_category_sub_concat.product_category_id = product_category.product_category_id
inner join product_subcategory on product_category_sub_concat.product_subcategory_id =  product_subcategory.product_subcategory_id 

/*

 select * from  product_category_sub_concat

 */

GO
