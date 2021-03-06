/****** Object:  View [dbo].[v_retail_min_screenings]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_retail_min_screenings]
GO
/****** Object:  View [dbo].[v_retail_min_screenings]    Script Date: 12/03/2021 10:03:48 AM ******/
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
