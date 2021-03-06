/****** Object:  StoredProcedure [dbo].[p_outpost_change_player_name]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_outpost_change_player_name]
GO
/****** Object:  StoredProcedure [dbo].[p_outpost_change_player_name]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_outpost_change_player_name]			@new_player_name			varchar(100),
																										@old_player_name				varchar(100)

as

declare				@error					int,
							@count					int

/*
 * Begin transaction
 */
set nocount on

begin transaction

insert into outpost_player
select		@new_player_name,
					outpost_venue_id,
					ip_address,
					no_screens,
					bandwidth,
					site_no,
					subnet,
					switch_ip_address,
					status,
					max_time,
					max_ads,
					max_time_trailers,
					max_ads_trailers,
					presentation_format,
					min_ads,
					location_desc,
					media_product_id,
					dview_playlist_name,
					dview_group_id,
					internal_desc,
					dcmedia_playlist_name,
					dcmedia_playlist_created
from outpost_player
where player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_player_location_xref', 16, 1)
	return -1
end


update	outpost_player_location_xref
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_player_location_xref', 16, 1)
	return -1
end

update	outpost_activeperiod_date
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_activeperiod_date', 16, 1)
	return -1
end

update	outpost_player_xref
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_player_xref', 16, 1)
	return -1
end


delete	outpost_player_date
where	player_name = @new_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete table outpost_player_date', 16, 1)
	return -1
end


insert into outpost_player_date
select screening_date,
      @new_player_name,
      generation_status,
      generation_user,
      generation,
      lock_user,
      locked,
      revision,
      max_time,
      max_ads,
      max_time_trailers,
      max_ads_trailers,
      min_ads,
      dview_scheduleStatus
  FROM outpost_player_date
  where player_name = @old_player_name
select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert table outpost_player_date', 16, 1)
	return -1
end

update	outpost_cert_history
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_cert_history', 16, 1)
	return -1
end
  
  
delete	outpost_player_date
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_player_date', 16, 1)
	return -1
end

update	outpost_dview_playlist
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_dview_playlist', 16, 1)
	return -1
end

update	outpost_certificate_item
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_certificate_item', 16, 1)
	return -1
end



update	outpost_shell_xref
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_shell_xref', 16, 1)
	return -1
end

/*update	outpost_retailer_player_xref
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_retailer_player_xref', 16, 1)
	return -1
end*/

update	outpost_playlist
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_playlist', 16, 1)
	return -1
end

update	outpost_playlist_item
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table outpost_playlist_item', 16, 1)
	return -1
end

delete	outpost_player
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete old player', 16, 1)
end

/*
 * Commit and Return
*/
 
commit transaction
return 0
GO
