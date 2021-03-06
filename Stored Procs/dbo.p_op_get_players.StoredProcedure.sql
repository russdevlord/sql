/****** Object:  StoredProcedure [dbo].[p_op_get_players]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_get_players]
GO
/****** Object:  StoredProcedure [dbo].[p_op_get_players]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_op_get_players] 

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

SELECT OutP.player_name+' - '+ISNULL(OutP.internal_desc,'internal name missing') AS player_name,OP.outpost_panel_desc,OPX.outpost_panel_id,OutP.outpost_venue_id,OutP.location_desc,OutP.media_product_id,OutV.state_code,OutV.outpost_venue_name,'|'+STUFF( (SELECT '|'+CONVERT(VARCHAR(10),OutX.outpost_retailer_id)+'-'+CONVERT(VARCHAR(10),OutX.outpost_retailer_grade_id)+'|' FROM outpost_retailer_player_xref OutX WHERE OutX.player_name = OutP.player_name FOR XML PATH(''), TYPE).value('.', 'varchar(max)') ,1,1,'') AS xrefs,FM.film_market_no,FM.film_market_desc
FROM   outpost_player OutP, outpost_venue OutV, outpost_player_xref OPX, outpost_panel OP, film_market FM
WHERE  OutV.outpost_venue_id = OutP.outpost_venue_id
 AND   OutP.status = 'O'
 AND   OPX.player_name = OutP.player_name
 AND   OP.outpost_panel_id = OPX.outpost_panel_id
 AND   OP.outpost_panel_status = 'O'
 AND   FM.film_market_no = OutV.market_no
ORDER  BY FM.film_market_no,OutV.outpost_venue_name,OutP.player_name,OP.outpost_panel_desc

return 0
GO
