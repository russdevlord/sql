/****** Object:  View [dbo].[v_retail_screening_playlist]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_retail_screening_playlist]
GO
/****** Object:  View [dbo].[v_retail_screening_playlist]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_retail_screening_playlist]
as
select		media_product.media_product_desc, 
					outpost_player.player_name, 
					outpost_player.internal_desc, 
					film_campaign.campaign_no, 
					film_campaign.product_desc, 
					outpost_package.package_code, 
					outpost_package.package_desc, 
					outpost_print.print_name, 
					v_outpost_distinct_campaign_player.screening_date, 
					outpost_package_burst.start_date, 
					outpost_package_burst.end_date,
					v_outpost_distinct_campaign_player.booking_count
from			film_campaign, 
					outpost_package,  
					v_outpost_distinct_campaign_player, 
					outpost_player, 
					outpost_print, 
					outpost_print_package, 
					outpost_package_burst, 
					media_product
where		film_campaign.campaign_no = outpost_package.campaign_no
and				film_campaign.campaign_no = v_outpost_distinct_campaign_player.campaign_no
and				outpost_package.package_id = v_outpost_distinct_campaign_player.package_id
and				outpost_package.package_id = outpost_print_package.package_id
and				outpost_print_package.print_id = outpost_print.print_id
and				v_outpost_distinct_campaign_player.player_name = outpost_player.player_name
and				outpost_player.status <> 'N'
and				v_outpost_distinct_campaign_player.screening_date > '1-jan-2016'
and				outpost_package.package_id = outpost_package_burst.package_id
and				outpost_package_burst.start_date <= dateadd(dd, 6,  screening_date)
and				outpost_package_burst.end_date >= dateadd(dd, -6, screening_date)
and				outpost_player.media_product_id = media_product.media_product_id
group by	media_product.media_product_desc, 
					outpost_player.player_name, 
					outpost_player.internal_desc, 
					film_campaign.campaign_no, 
					film_campaign.product_desc, 
					outpost_package.package_code, 
					outpost_package.package_desc, 
					outpost_print.print_name, 
					v_outpost_distinct_campaign_player.screening_date, 
					outpost_package_burst.start_date, 
					outpost_package_burst.end_date,
					v_outpost_distinct_campaign_player.booking_count
GO
