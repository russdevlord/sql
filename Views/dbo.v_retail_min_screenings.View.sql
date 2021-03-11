USE [production]
GO
/****** Object:  View [dbo].[v_retail_min_screenings]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view		[dbo].[v_retail_min_screenings]
as
select		media_product_desc, 
					outpost_player.player_name, 
					internal_desc,
					screening_date, 
					sum(booking_count) as spots_booked,
					sum(days_taken) as days_booked
from			v_outpost_distinct_campaign_player, 
					outpost_player, 
					media_product
where		v_outpost_distinct_campaign_player.player_name = outpost_player.player_name
and				outpost_player.media_product_id = media_product.media_product_id
group by	media_product_desc, 
					outpost_player.player_name, 
					internal_desc,
					screening_date
having		sum(booking_count) < 3


GO
