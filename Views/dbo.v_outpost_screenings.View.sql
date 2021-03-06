/****** Object:  View [dbo].[v_outpost_screenings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_outpost_screenings]
GO
/****** Object:  View [dbo].[v_outpost_screenings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_outpost_screenings]
as
SELECT        outpost_package.package_desc, outpost_panel.outpost_panel_desc, outpost_player.player_name, outpost_venue.outpost_venue_name, 
                         film_campaign.campaign_no, film_campaign.product_desc, outpost_print.print_name, outpost_spot.screening_date, outpost_spot.spot_status
FROM            outpost_player_xref INNER JOIN
                         outpost_panel ON outpost_player_xref.outpost_panel_id = outpost_panel.outpost_panel_id INNER JOIN
                         outpost_player ON outpost_player_xref.player_name = outpost_player.player_name INNER JOIN
                         outpost_spot ON outpost_panel.outpost_panel_id = outpost_spot.outpost_panel_id INNER JOIN
                         outpost_package ON outpost_spot.package_id = outpost_package.package_id INNER JOIN
                         outpost_venue ON outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id AND 
                         outpost_player.outpost_venue_id = outpost_venue.outpost_venue_id INNER JOIN
                         film_campaign ON outpost_spot.campaign_no = film_campaign.campaign_no AND outpost_package.campaign_no = film_campaign.campaign_no INNER JOIN
                         outpost_print_package ON outpost_package.package_id = outpost_print_package.package_id INNER JOIN
                         outpost_print ON outpost_print_package.print_id = outpost_print.print_id
where outpost_spot.screening_date > '1-jan-2013'


GO
