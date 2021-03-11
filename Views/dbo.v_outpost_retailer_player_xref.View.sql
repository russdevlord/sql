USE [production]
GO
/****** Object:  View [dbo].[v_outpost_retailer_player_xref]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create	view [dbo].[v_outpost_retailer_player_xref]
as
select			outpost_retailer_group_desc,
					outpost_retailer_category_desc,
					outpost_retailer_desc,
					player_name,
					outpost_retailer_grade_desc,
					outpost_retailer_group_desc + ' - ' + outpost_retailer_category_desc + ' - ' + outpost_retailer_desc + ' - ' + outpost_retailer_grade_desc as full_desc
from			outpost_retailer_group, outpost_retailer_category, outpost_retailer, outpost_retailer_player_xref, outpost_retailer_grade
where			outpost_retailer_group.outpost_retailer_group_id = outpost_retailer_category.outpost_retailer_group_id
and				outpost_retailer.outpost_retailer_category_id = outpost_retailer_category.outpost_retailer_category_id
and				outpost_retailer_player_xref.outpost_retailer_grade_id = outpost_retailer_grade.outpost_retailer_grade_id
and				outpost_retailer_player_xref.outpost_retailer_id = outpost_retailer.outpost_retailer_id
--and				outpost_retailer_group.outpost_retailer_group_id in (2300,2200,1200)

GO
