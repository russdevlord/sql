/****** Object:  View [dbo].[v_dart_dcmedia_player_pop_matrix]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_dcmedia_player_pop_matrix]
GO
/****** Object:  View [dbo].[v_dart_dcmedia_player_pop_matrix]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create View [dbo].[v_dart_dcmedia_player_pop_matrix] AS
select 
player_name,
campaign_no,
pvt.dart_demographics_id,
dart_demographics.dart_demographics_desc,
screening_date,
start_time,
outpost_panel_id,
viewers,
dwell_avg,
dwell_min,
dwell_max,
attention_avg,
attention_min,
attention_max,
0 ots,
0 conversion_ratio,
CASE  WHEN [1100] <> 'Supermarkets' Then 'Other' Else [1100] END Retailer_group,
[1200] as 'Location',
CASE  WHEN [2100] = 'Over 10,000pw' Then '<50,000pw'
	  WHEN [2100] = 'Over 50,000pw' Then '50,000 - 100,000 pw'
	  WHEN [2100] = 'Over 100,000pw' Then '100,000+ pw'
END Foot_traffic,
[1300] Screen_size,
[2300] as network
FROM
(
SELECT DISTINCT 
opx.player_name,
outpost_retailer_group_id, 
orc.outpost_retailer_category_desc,
dcpa.*
From dart_dcmedia_player_pop dcpa
JOIN outpost_player_xref opx
on opx.outpost_panel_id = dcpa.outpost_panel_id
JOIN outpost_retailer_player_xref orpx
ON opx.player_name = orpx.player_name
LEFT JOIN outpost_retailer ort
ON orpx.outpost_retailer_id = ort.outpost_retailer_category_id
Left JOIN outpost_retailer_category orc
ON orc.outpost_retailer_category_id = ort.outpost_retailer_category_id) as Orig
PIVOT(
MAX(outpost_retailer_category_desc)
FOR
outpost_retailer_group_id IN ([1100] ,[1200],[1300],[2100],[2300])) as pvt
JOIN
dart_demographics
ON pvt.dart_demographics_id = dart_demographics.dart_demographics_id


GO
