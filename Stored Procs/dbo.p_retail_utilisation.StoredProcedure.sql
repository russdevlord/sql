/****** Object:  StoredProcedure [dbo].[p_retail_utilisation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_retail_utilisation]
GO
/****** Object:  StoredProcedure [dbo].[p_retail_utilisation]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_retail_utilisation]   	@arg_start_date		    datetime,
											@arg_end_date		    datetime
as

set nocount on

/*
 * Declare Variables
 */

declare @book_time			int,
        @book_ads			int,
        @errorode				int,
        @screening_date     datetime,
        @outpost_panel_id	int

/*
 * Create Table to Hold Utilization Information
 */

create table #utilization
(
	outpost_panel_id			int				null,
	outpost_panel_desc			varchar(100)    null,
	player_name		            varchar(100)    null,
	internal_desc	            varchar(100)    null,
	media_product_desc	        varchar(100)    null,
	market_no					int				null,
	market_desc					varchar(30)		null,
	screening_date				datetime		null,				
	max_ads	                    int				null,
    max_time	                int				null,
	booked_ads	                int				null,
    booked_time	                int				null
)

insert into #utilization
			(outpost_panel_id,
			outpost_panel_desc,
			player_name, 
			internal_desc,
			media_product_desc,
			market_no,
			market_desc,
			screening_date,
			max_ads,
			max_time)
select		outpost_panel.outpost_panel_id, 
			outpost_panel_desc,
			outpost_player.player_name, 
			outpost_player.internal_desc,
			media_product_desc,
			market_no,
			film_market_desc,
			outpost_screening_dates.screening_date,
			outpost_player_date.max_ads,
			outpost_player_date.max_time
from		outpost_panel,
			outpost_player_xref,
			outpost_player,
			media_product,
			film_market,
			outpost_venue,
			outpost_screening_dates,
			outpost_player_date
where		outpost_panel.outpost_panel_id = outpost_player_Xref.outpost_panel_id
and			outpost_player_xref.player_name = outpost_player.player_name
and			outpost_player.media_product_id = media_product.media_product_id
and			outpost_player.outpost_venue_id = outpost_venue.outpost_venue_id
and			outpost_venue.market_no = film_market.film_market_no
and			outpost_screening_dates.screening_date between @arg_start_date and @arg_end_date
and			outpost_player_date.screening_date = outpost_screening_dates.screening_date
and			outpost_player_date.player_name = outpost_player.player_name
and			outpost_player.status = 'O'
order by	outpost_player.player_name, outpost_panel.outpost_panel_id


/*
 * Declare Cursors
 */
  
declare		player_csr cursor static for
select		outpost_panel_id,
			screening_date
from		#utilization
order by	player_name,
			screening_date			
for read only

/*
 * Loop Through Players
 */

open player_csr
fetch player_csr into @outpost_panel_id, @screening_date
while(@@fetch_status=0)
begin

	/*
	* Calculate Bookings per month
	*/
	
	select	@book_time = Isnull(sum(pack.duration),0),
			@book_ads = Isnull(sum(pack.prints),0)
	from	outpost_spot spot,
			outpost_package pack,
			film_campaign fc
	where	spot.outpost_panel_id = @outpost_panel_id 
	and		spot.screening_date = @screening_date
	and		spot.spot_status <> 'D' 
	and		spot.spot_status <> 'P' 
	and		spot.package_id = pack.package_id 
	and		spot.campaign_no = fc.campaign_no 
	and		pack.campaign_no = fc.campaign_no 

	update	#utilization 
	set		booked_ads = @book_ads,
			booked_time = @book_time
	where	outpost_panel_id = @outpost_panel_id
	and		screening_date = @screening_date

	/*
	 * Fetch Next
	 */

    fetch player_csr into @outpost_panel_id, @screening_date
end

/*
 * Return Overbooked Data
 */

select      *
from        #utilization utl

/*
 * Return Success
 */

return 0
GO
