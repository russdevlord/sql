/****** Object:  StoredProcedure [dbo].[p_op_sales_tool_get_players]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_sales_tool_get_players]
GO
/****** Object:  StoredProcedure [dbo].[p_op_sales_tool_get_players]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_op_sales_tool_get_players] 

as

/*==============================================================*
 * DESC:- Gets the Outpost players and their tags               *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  24-May-2013 DH   Initial Build                           *
 *                                                              *
 *==============================================================*/

set nocount on

SELECT			OutP.player_name+' - '+ISNULL(OutP.internal_desc,'internal name missing') AS player_name,
						OP.outpost_panel_desc,
						OPX.outpost_panel_id,
						OutP.outpost_venue_id,
						OutP.location_desc,
						OutP.media_product_id,
						OutV.state_code,
						OutV.outpost_venue_name,
						'|'+STUFF( (SELECT '|'+CONVERT(VARCHAR(10),OutX.outpost_retailer_id) + '-' + CONVERT(VARCHAR(10),OutX.outpost_retailer_grade_id) + '|' FROM outpost_retailer_player_xref OutX WHERE OutX.player_name = OutP.player_name FOR XML PATH(''),TYPE).value('.', 'varchar(max)') ,1,1,'') AS xrefs,
						FM.film_market_no,
						CASE WHEN FM.film_market_no = 2 THEN 'New South Wales' ELSE FM.film_market_desc END AS film_market_desc,
						OutV.address_1,
						OutV.town_suburb,
						OutV.postcode,
						ISNULL((SELECT		TOP 1 outpost_retailer_id 
										 FROM			outpost_retailer_player_xref 
										 WHERE		player_name = OutP.player_name 
										 AND			outpost_retailer_id IN (448,449,450,451,452)),0) AS Traffic,
						ISNULL((SELECT		TOP 1 outpost_retailer_category_id 
										  FROM		outpost_retailer_player_xref,
															 outpost_retailer
										  WHERE		player_name = OutP.player_name 
										  and			outpost_retailer_player_xref.outpost_retailer_id =  outpost_retailer.outpost_retailer_id
										  AND			outpost_retailer_category_id in (29,30,31,47,48)),0) AS ScreenSize,
						1/*OutP.no_screens*/ as no_screens,
						isnull(foot_traffic,0) as foot_traffic,
						outpost_venue_group_name,
						opening_date
FROM				outpost_player OutP, 
						outpost_venue OutV, 
						outpost_player_xref OPX, 
						outpost_panel OP, 
						film_market FM,
						outpost_venue_group outgrp
WHERE			OutV.outpost_venue_id = OutP.outpost_venue_id
 AND				OutP.status = 'O'
 AND				OPX.player_name = OutP.player_name
 AND				OP.outpost_panel_id = OPX.outpost_panel_id
 AND				OP.outpost_panel_status = 'O'
 AND				FM.film_market_no = OutV.market_no
and					outv.outpost_venue_group_id = outgrp.outpost_venue_group_id 
ORDER  BY		FM.film_market_no,
						OutV.outpost_venue_name,
						OutP.player_name,
						OP.outpost_panel_desc

return 0
GO
