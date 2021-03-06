/****** Object:  StoredProcedure [dbo].[p_cl_certificate_makeup_cleanup]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_certificate_makeup_cleanup]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_certificate_makeup_cleanup]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_cl_certificate_makeup_cleanup]

as

declare		@error			int

begin transaction

delete	cinelight_spot_daily_segment 
where	spot_id in (	select	spot_id 
						from	cinelight_spot 
						where	spot_type = 'M'
						and		spot_status = 'U') 

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error deleting cinelight_spot_daily_segment for unused makeups', 16, 1)
	return -1
end

delete	cinelight_playlist_item_spot_xref
where	spot_id in (	select	spot_id 
						from	cinelight_spot 
						where	spot_type = 'M'
						and		spot_status = 'U') 

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error deleting cinelight_panel_playlist_item_spot_xref for unused makeups', 16, 1)
	return -1
end

delete	cinelight_playlist_spot_xref
where	spot_id in (	select	spot_id 
						from	cinelight_spot 
						where	spot_type = 'M'
						and		spot_status = 'U') 

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error deleting cinelight_panel_playlist_spot_xref for unused makeups', 16, 1)
	return -1
end

delete	cinelight_spot   
where	spot_type = 'M'
and		spot_status = 'U'

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error deleting cinelight_spot for unused makeups', 16, 1)
	return -1
end

commit transaction
return 0
GO
