/****** Object:  StoredProcedure [dbo].[p_rpt_outpost_under_bookings]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_outpost_under_bookings]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_outpost_under_bookings]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rpt_outpost_under_bookings] 
	
		@start_date			datetime,
		@end_date				datetime,
		@media_product_id		varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select * into #location_dates
	from (select fm.film_market_desc
				 ,fm.film_market_no
			     ,ov.outpost_venue_id
				 ,ov.outpost_venue_name
				 ,op.player_name
				 ,op.internal_desc
				 ,opp.outpost_panel_id
				 ,opp.outpost_panel_desc 
		  from outpost_panel as opp
		  inner join outpost_player_xref as opx on opx.outpost_panel_id = opp.outpost_panel_id
		  inner join outpost_player as op on op.player_name = opx.player_name
		  inner join outpost_venue as ov on ov.outpost_venue_id = op.outpost_venue_id
		  inner join film_market as fm on fm.film_market_no = ov.market_no
		  inner join media_product as mp on mp.media_product_id = op.media_product_id
		  where ((@media_product_id = 0 and mp.media_product_id in (select media_product_id 
																	from media_product 
																	where media_product_id in (select media_product_id 
																							   from outpost_player)))
				 or
				  (@media_product_id <> 0 and mp.media_product_id = @media_product_id))
				) as a
	CROSS JOIN 	(select screening_date
				 from outpost_screening_dates
				 where screening_date between @start_date and @end_date) as b


	select ld.*
		   ,isnull(spots.spot_count,0) as spot_count
		   into #output
	from #location_dates as ld
	left join (select screening_date, outpost_panel_id, count(*) as spot_count
			   from outpost_spot as os
			   inner join outpost_package as oppk on oppk.package_id = os.package_id
			   inner join film_campaign as fc on fc.campaign_no = oppk.campaign_no
			   where fc.outpost_status <> 'P'
			   and screening_date between @start_date and @end_date

			   group by os.screening_date, outpost_panel_id
			  ) as spots on spots.outpost_panel_id = ld.outpost_panel_id
																 and spots.screening_date = ld.screening_date

	select * 
	from #output
	where spot_count < 4
	order by film_market_no asc
			 ,outpost_venue_name
			 ,player_name
			 ,outpost_panel_desc
			 ,screening_date
END
GO
