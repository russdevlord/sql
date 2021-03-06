/****** Object:  View [dbo].[v_retail_screenings_statrev]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_retail_screenings_statrev]
GO
/****** Object:  View [dbo].[v_retail_screenings_statrev]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO





create view		[dbo].[v_retail_screenings_statrev] 
as
select			film_campaign.campaign_no, 
				product_desc, 
				outpost_venue.outpost_venue_name, 
				outpost_panel.outpost_panel_desc, 
				outpost_player.player_name, 
				sum(statrev_spot_rates.avg_rate * no_days / 7) as rev, 
				outpost_screening_date_xref.benchmark_end, 
				business_unit.business_unit_id, 
				business_unit.business_unit_desc
from			film_campaign 
inner join		business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
inner join		outpost_package on film_campaign.campaign_no = outpost_package.campaign_no
inner join		outpost_spot on outpost_package.package_id = outpost_spot.package_id
inner join		outpost_panel on outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
inner join		outpost_player_xref on outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id
inner join		outpost_player on outpost_player_xref.player_name = outpost_player.player_name
inner join		outpost_venue on outpost_player.outpost_venue_id = outpost_venue.outpost_venue_id
inner join		outpost_screening_date_xref on outpost_spot.screening_date = outpost_screening_date_xref.screening_date
inner join		statrev_spot_rates on outpost_spot.spot_id = statrev_spot_rates.spot_id
where			outpost_spot.screening_date > '1-jan-2015'
and				spot_status <> 'P'
and				statrev_spot_rates.revenue_group >= 50
group by		film_campaign.campaign_no, 
				product_desc,
				outpost_screening_date_xref.benchmark_end,
				outpost_venue.outpost_venue_name,
				outpost_panel.outpost_panel_desc,
				outpost_player.player_name,
				business_unit.business_unit_id,
				business_unit.business_unit_desc







GO
