/****** Object:  View [dbo].[v_dart_panel_matrix]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_panel_matrix]
GO
/****** Object:  View [dbo].[v_dart_panel_matrix]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create View [dbo].[v_dart_panel_matrix] AS
select		player_name,
			internal_desc, 
			outpost_panel_id,
			CASE  WHEN [1100] <> 'Supermarkets' Then 'Other' Else [1100] END retailer_group,
			[1200] as location,
			CASE  WHEN [2100] = 'Over 10,000pw' Then '<50,000pw'
				  WHEN [2100] = 'Over 50,000pw' Then '50,000 - 100,000 pw'
				  WHEN [2100] = 'Over 100,000pw' Then '100,000+ pw'
			END as foot_traffic,
			[1300] as screen_size,
			[2300] as network
FROM				(select		opx.player_name,
								outpost_retailer_group_id, 
								isnull(orc.outpost_retailer_category_desc, 'None') as outpost_retailer_category_desc,
								pan.outpost_panel_id,
								play.internal_desc
					From		outpost_panel pan
					JOIN		outpost_player_xref opx 
									on opx.outpost_panel_id = pan.outpost_panel_id
					JOIN		outpost_player play
									on opx.player_name = play.player_name
					left JOIN		outpost_retailer_player_xref orpx	 
									on opx.player_name = orpx.player_name
					LEFT JOIN	outpost_retailer ort
									ON orpx.outpost_retailer_id = ort.outpost_retailer_id
					Left JOIN	outpost_retailer_category orc
									ON orc.outpost_retailer_category_id = ort.outpost_retailer_category_id) as Orig
PIVOT(
MAX(outpost_retailer_category_desc)
FOR
outpost_retailer_group_id IN ([1100] ,[1200],[1300],[2100],[2300])) as pvt





GO
