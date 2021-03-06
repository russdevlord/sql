/****** Object:  View [dbo].[v_retail_screenings_allocated]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_retail_screenings_allocated]
GO
/****** Object:  View [dbo].[v_retail_screenings_allocated]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create view [dbo].[v_retail_screenings_allocated] as
select  business_unit.business_unit_id, business_unit.business_unit_desc, film_campaign.campaign_no, product_desc, sum(outpost_spot.charge_rate * (no_days / 7)) as rev, outpost_screening_date_xref.benchmark_end, outpost_venue.outpost_venue_name, outpost_panel.outpost_panel_desc, outpost_player.player_name, spot_status
from business_unit, film_campaign, outpost_package, outpost_spot, outpost_venue, outpost_player, outpost_panel, outpost_player_xref, outpost_screening_date_xref
where film_campaign.campaign_no = outpost_package.campaign_no
and	film_Campaign.business_unit_id = business_unit.business_unit_id
and outpost_package.package_id = outpost_spot.package_id
and outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
and outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id
and	 outpost_player_xref.player_name = outpost_player.player_name
and outpost_player.outpost_venue_id = outpost_venue.outpost_venue_id
and outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and outpost_spot.screening_date > '1-jan-2009'
and		film_campaign.campaign_status <> 'P'
group by  business_unit.business_unit_id, business_unit.business_unit_desc,film_campaign.campaign_no, product_desc,   outpost_screening_date_xref.benchmark_end, outpost_venue.outpost_venue_name, outpost_panel.outpost_panel_desc, outpost_player.player_name, spot_status






GO
