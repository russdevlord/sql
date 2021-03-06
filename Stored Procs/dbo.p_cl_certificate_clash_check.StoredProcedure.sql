/****** Object:  StoredProcedure [dbo].[p_cl_certificate_clash_check]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_certificate_clash_check]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_certificate_clash_check]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cl_certificate_clash_check]	@screening_date			datetime,
											@player_name			varchar(40),
											@product_category_id	int,
											@client_id				int,
											@client_clash			char(1),
											@product_clash			char(1)

as	

declare		@error						int,
			@complex_id					int,
			@clash_count				int

select	@complex_id = complex_id
from	cinelight_dsn_players
where	@player_name = player_name

select @error = @@error
if @error != 0
begin
	raiserror ('Cinelight Clash Check: Error determining associated cinelight complex.', 16, 1)
	return -1
end

select	@clash_count = count(spot_id)
from	cinelight_spot,
		film_campaign,
		cinelight_package,
		cinelight,
		cinelight_dsn_player_xref
where	cinelight_spot.campaign_no = film_campaign.campaign_no
and		cinelight_package.campaign_no = film_campaign.campaign_no
and		cinelight_package.campaign_no = cinelight_spot.campaign_no
and		cinelight_spot.package_id = cinelight_package.package_id
and		cinelight_spot.cinelight_id = cinelight.cinelight_id
and		cinelight_spot.screening_date = @screening_date
and		cinelight.complex_id = @complex_id
and		cinelight_spot.spot_status <> 'P'
and		cinelight.cinelight_id = cinelight_dsn_player_xref.cinelight_id
and		cinelight_dsn_player_xref.player_name <> @player_name
and		cinelight_package.product_category = @product_category_id
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
	raiserror ('Cinelight Clash Check: Error determining no clashing cinelights.', 16, 1)
	return -1
end

select	@clash_count
return 0
GO
