/****** Object:  View [dbo].[v_retail_spots_not_on_all_panels]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_retail_spots_not_on_all_panels]
GO
/****** Object:  View [dbo].[v_retail_spots_not_on_all_panels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_retail_spots_not_on_all_panels]
as
select			campaign_no, 
					package_id, 
					outpost_player.player_name,
					internal_desc,
					screening_date,
					no_panels,
					no_spots		
from			(select	campaign_no, 
									package_id, 
									player_name, 
									spot_id, 
									screening_date,
									(select		count(distinct sub_xref.outpost_panel_id)
									from			outpost_panel sub_panel, 
														outpost_player_xref sub_xref
									where			sub_panel.outpost_panel_id = sub_xref.outpost_panel_id 
									and				sub_xref.player_name = outpost_player_xref.player_name
									and				sub_panel.outpost_panel_status = 'O' ) as no_panels, 
									(select		count(distinct sub_xref.outpost_panel_id)
									from			outpost_spot sub_spot,
														outpost_player_xref sub_xref
									where			sub_spot.outpost_panel_id = sub_xref.outpost_panel_id
									and				sub_xref.player_name = outpost_player_xref.player_name
									and				sub_spot.package_id = outpost_spot.package_id
									and				sub_spot.screening_date = outpost_spot.screening_date) as no_spots 
					from outpost_player_xref, outpost_spot
					where outpost_player_xref.outpost_panel_id = outpost_spot.outpost_panel_id
					and screening_date > '1-may-2017') as temp_table,
					outpost_player
where			no_panels <> no_spots		
and				outpost_player.player_name = temp_table.player_name
and				outpost_player.media_product_id in (9, 10,11)
GO
