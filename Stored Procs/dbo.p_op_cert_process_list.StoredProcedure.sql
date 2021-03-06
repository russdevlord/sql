/****** Object:  StoredProcedure [dbo].[p_op_cert_process_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_cert_process_list]
GO
/****** Object:  StoredProcedure [dbo].[p_op_cert_process_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_cert_process_list] @screening_date	datetime,
													@filter				char(1),
													@name_id				char(50)
as
  
/*
 * Select List
 */

select 		cplx.outpost_venue_id, 
			cplx.outpost_venue_name,
			cdpd.locked,
			cdpd.generation_user,
			cdpd.revision,
			'N' as print_cert,
			'N' as trans_cert,
			cplx.market_no,
			cplx.branch_code,
			cplx.state_code,
			cdp.player_name,
			cdp.ip_address,
			cdp.status,
           (select 	IsNull(max(revision),-1) 
			from 	outpost_cert_history 
			where 	player_name = cdpd.player_name 
			and 	screening_date = @screening_date
			and 	status = 'S') as last_revision,
			ISNULL(cdp.internal_desc,'**unknown**') AS internal_desc,
			cdpd.generation,
			(select max(print_time)
			from 	outpost_cert_history 
			where 	player_name = cdpd.player_name 
			and 	screening_date = @screening_date
			and 	status = 'S') as last_revision_sent
from 		outpost_player_date cdpd,
			outpost_player cdp,
			outpost_venue cplx
where 		cdpd.screening_date = @screening_date and
			cdpd.generation is not null and
			cdp.outpost_venue_id <> 462 and 
			cdp.internal_desc <> 'NSW_AustSquare_VMRM_800_FoodCourtA' and
			cdp.internal_desc <> 'NSW_AustSquare_VMRM_800_FoodCourtB' and 
			cdp.internal_desc <> 'WA_CarillonCity_VMRM_1062_FoodCourtSubway' and
			cdp.internal_desc <> 'WA_CarillonCity_VMRM_1062_FoodCourtHungryJacks' and
			cdp.internal_desc <> 'VIC_JamFactory_VMRM_602_Entry' and
			cdp.internal_desc <> 'VIC_JamFactory_VMRM_602_Cinema' and
			cdp.internal_desc <> 'VIC_JamFactory_VMRM_602_ChapelStreet' and
			cdp.internal_desc <> 'NSW_HunterConnection_VMRM_644_4x2_PlayerA' and
			cdp.internal_desc <> 'VIC_Southgate_VMRM_694_FoodCourt55' and
			cdp.internal_desc <> 'VIC_Southgate_VMRM_694_FoodCourtBoost' and
			cdp.internal_desc <> 'VIC_Southgate_VMRM_694_FoodCourtMuffinBreak' and
			cdp.internal_desc <> 'VIC_PranCentral_VMRM_453_FoodCourtA' and
			cdp.internal_desc <> 'VIC_PranCentral_VMRM_453_FoodCourtB' and
			cdp.internal_desc <> 'VIC_PranCentral_VMRM_453_FoodCourtB' and
			cdp.internal_desc <> 'VIC_GreensboroughPlaza_VMRM_864_2x3Travelator' and
			cdp.internal_desc <> 'VIC_GreensboroughPlaza_VMRM_864_2x3FoodCourt' and
			--cdp.internal_desc <> 'NSW_BigBearComplex_VMRM_772_BakersDelight' and
			--cdp.internal_desc <> 'NSW_BigBearComplex_VMRM_772_SuperscreenEntrance' and
			cdp.internal_desc <> 'NSW_BigBearComplex_VMRM_772_OfficeLobby' and
			cdp.internal_desc <> 'VIC_Galleria_VMRM_732_FoodCourtNorth' and
			cdp.internal_desc <> 'VIC_Galleria_VMRM_882_FoodCourtSouth' and
			cdp.internal_desc <> 'NSW_AshfieldMall_VMRM_850_TravelatorUltra' and
			cdp.internal_desc <> 'VIC_BrandonPark_VMRM_10_TravelatorUltraA' and 
			cdp.internal_desc <> 'NSW_CarlingfordCourt_VMRM_34_WoolworthsUltraA' and
			cdp.internal_desc <> 'NSW_CarlingfordCourt_VMRM_34_InfoUltraA' and
			cdp.internal_desc <> 'NSW_ManlyWharf_VMRM_1072_UltraStreet' and
			cdp.internal_desc <> 'NSW_ManlyWharf_VMRM_1072_UltraSeaside' and
			cdp.internal_desc <> 'NSW_ManlyWharf_VMRM_1072_AldiWalkwayA' and
			cdp.internal_desc <> 'NSW_ManlyWharf_VMRM_1072_AldiWalkwayB' and
			cdp.internal_desc <> 'VIC_MorningtonCentral_VMRM_091_TravelatorUltra' and
			cdp.internal_desc <> 'NSW_Alexandria_VMRM_32_TheGoodGuys' and
			cdp.internal_desc <> 'NSW_Alexandria_VMRM_1092_Beacon' and			
			cdp.internal_desc <> 'QLD_Chevron_VMRM_1075_LED' and			
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_CarparkLift' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_FlowerShopRHS' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_FlowerShopLHS' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_FCDoughnut' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_DeliEntry' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_DeliExit' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_CarparkExitATM' and
			cdp.internal_desc <> 'VIC_DandenongMP_VMRM_1091_CarparkWalkway' and
			cdp.internal_desc <> 'NSW_Chatswood_VMRM_1241_ConcourseLevel_PostOfficeLHS' and
			cdp.internal_desc <> 'NSW_Chatswood_VMRM_1241_ConcourseLevel_PostOfficeRHS' and
			cdp.internal_desc <> 'VIC_WerribeePlaza_VMRM_1260_Kmart' and
			cdp.internal_desc <> 'VIC_WerribeePlaza_VMRM_1261_CinemaEntry' and
			cdp.internal_desc <> 'VIC_WerribeePlaza_VMRM_1261_MyerEntry' and
			cdp.internal_desc <> 'VIC_WilliamsLandingSC_VMRM_1252_WWLHS' and
			cdp.internal_desc <> 'VIC_WilliamsLandingSC_VMRM_1252_WWRHS' and
			cdp.internal_desc <> 'NSW_AlburyCP_VMRM_560_Woolworths' and
			cdp.internal_desc <> 'QLD_CaboolturePark_VMRM_201_Coles' and
			cdp.internal_desc <> 'QLD_Pialba_VMRM_634_BigW' and
			cdp.internal_desc <> 'QLD_VictoriaPoint_VMRM_334_Coles' and
			cdp.internal_desc <> 'VIC_OceanGroveWOW_VMRM_530_WoolworthsRight' and
			cdp.internal_desc <> 'VIC_Parkmore_VMRM_104_Coles' and
			cdp.internal_desc <> 'VIC_PolarisTC_VMRM_504_Butcher' and
			cdp.internal_desc <> 'VIC_Southgate_VMRM_694_FoodCourtTravelator' and
			cdp.internal_desc <> 'VIC_Southgate_VMRM_694_FoodCourtTravelator ' and
			cdpd.player_name = cdp.player_name and
			cplx.outpost_venue_id = cdp.outpost_venue_id and
			(cdpd.generation_status = 'G' or
			cdpd.generation_status = 'E') and
			((@filter = 'U' and cdpd.generation_user = @name_id) or
			(@filter = '@')) and
			cdp.status in  ('O','H')
order by 	cplx.market_no,
			cplx.outpost_venue_name
GO
