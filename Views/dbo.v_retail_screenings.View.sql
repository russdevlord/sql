USE [production]
GO
/****** Object:  View [dbo].[v_retail_screenings]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_retail_screenings] as
select film_campaign.campaign_no, product_desc, business_unit.business_unit_id, business_unit.business_unit_desc, sum(outpost_spot.charge_rate * no_days / 7) as rev, outpost_screening_date_xref.benchmark_end, outpost_venue.outpost_venue_name, outpost_panel.outpost_panel_desc, outpost_player.player_name 
from film_campaign, business_unit, outpost_package, outpost_spot, outpost_venue, outpost_player, outpost_panel, outpost_player_xref, outpost_screening_date_xref
where film_campaign.campaign_no = outpost_package.campaign_no
and outpost_package.package_id = outpost_spot.package_id
and outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
and outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id
and	 outpost_player_xref.player_name = outpost_player.player_name
and outpost_player.outpost_venue_id = outpost_venue.outpost_venue_id
and outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and outpost_spot.screening_date > '1-jan-2015'
group by film_campaign.campaign_no, product_desc,   outpost_screening_date_xref.benchmark_end, outpost_venue.outpost_venue_name, outpost_panel.outpost_panel_desc, outpost_player.player_name, business_unit.business_unit_id, business_unit.business_unit_desc





GO
