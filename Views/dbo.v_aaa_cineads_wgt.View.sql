/****** Object:  View [dbo].[v_aaa_cineads_wgt]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_aaa_cineads_wgt]
GO
/****** Object:  View [dbo].[v_aaa_cineads_wgt]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_aaa_cineads_wgt]
as
select spot.spot_id, 
convert(float, spot.charge_rate) / (select sum(charge_rate) from campaign_spot where tran_id = spot.tran_id) as weighting 
from campaign_spot spot 
where spot.campaign_no in (select campaign_no from film_campaign where business_unit_id = 9) 
and spot.tran_id is not null
--and	spot.spot_weighting is null
and spot.tran_id in (select tran_id from campaign_spot group by tran_id having sum(charge_rate) <> 0)
GO
