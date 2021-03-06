/****** Object:  StoredProcedure [dbo].[p_op_certificate_clash_check]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_certificate_clash_check]
GO
/****** Object:  StoredProcedure [dbo].[p_op_certificate_clash_check]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Create proc [dbo].[p_op_certificate_clash_check]	@screening_date			datetime,
											@player_name			varchar(40),
											@product_category_id	int,
											@client_id				int,
											@client_clash			char(1),
											@product_clash			char(1)

as	

declare		@error						int,
			@outpost_panel_id					int,
			@clash_count				int

select	@outpost_panel_id = outpost_panel_id
from	outpost_player_xref
where	@player_name = player_name

select @error = @@error
if @error != 0
begin
	raiserror ('outpost_panel Clash Check: Error determining associated outpost_panel outpost_venue.', 16, 1)
	return -1
end

select	@clash_count = count(spot_id)
from	outpost_spot,
		film_campaign,
		outpost_package,
		outpost_panel,
		outpost_player_xref --outpost_panel_dsn_player_xref
where	outpost_spot.campaign_no = film_campaign.campaign_no
and		outpost_package.campaign_no = film_campaign.campaign_no
and		outpost_package.campaign_no = outpost_spot.campaign_no
and		outpost_spot.package_id = outpost_package.package_id
and		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
and		outpost_spot.screening_date = @screening_date
and		outpost_panel.outpost_panel_id = @outpost_panel_id
and		outpost_spot.spot_status <> 'P'
and		outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id
and		outpost_player_xref.player_name <> @player_name
and		outpost_package.product_category = @product_category_id
and		((@client_clash = 'Y'
and     @product_clash = 'N'
and		client_id <> @client_id)
or		(@product_clash = 'Y'
and		allow_product_clashing <>'Y')
or		(@product_clash = 'N'
and		@client_clash = 'N'
and		client_id <> @client_id
or		(@client_clash = 'Y'
and		client_clash = 'N')))

select @error = @@error
if @error != 0
begin
	raiserror ('outpost_panel Clash Check: Error determining no clashing outpost_panels.', 16, 1)
	return -1
end

select	@clash_count
return 0
GO
