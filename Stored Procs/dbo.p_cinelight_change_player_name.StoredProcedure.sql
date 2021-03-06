/****** Object:  StoredProcedure [dbo].[p_cinelight_change_player_name]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_change_player_name]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_change_player_name]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_cinelight_change_player_name]			@new_player_name			varchar(100),
																											@old_player_name				varchar(100)

as

declare				@error					int,
							@count					int

/*
 * Begin transaction
 */
set nocount on

begin transaction

insert into	cinelight_dsn_players
select			@new_player_name,
					complex_id,
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
					mu_dcmedia_flag,
					dcmedia_playlist_name,
					dcmedia_playlist_created
from cinelight_dsn_players
where player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_player_location_xref', 16, 1)
	return -1
end


update	cinelight_activeperiod_date
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_activeperiod_date', 16, 1)
	return -1
end

update	cinelight_dsn_player_xref
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ( 'Error: Failed to Update table cinelight_player_xref', 16, 1)
	return -1
end

delete	cinelight_dsn_player_date
where	player_name = @new_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete table new cinelight_dsn_player_date', 16, 1)
	return -1
end


insert into cinelight_dsn_player_date
select screening_date,
      @new_player_name,
      cinelight_generation_status,
      cinelight_generation_user,
      cinelight_generation,
      cinelight_lock_user,
      cinelight_locked,
      cinelight_revision,
      max_time,
      max_ads,
      max_time_trailers,
      max_ads_trailers,
      min_ads
  FROM cinelight_dsn_player_date
  where player_name = @old_player_name
  
  
select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert table cinelight_player_date', 16, 1)
	return -1
end


update	cinelight_dsn_cert_history
set			player_name = @new_player_name
where		player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_cert_history', 16, 1)
	return -1
end
  
delete	cinelight_dsn_player_date
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete table old cinelight_dsn_player_date', 16, 1)
	return -1
end

update	cinelight_playlist
set			player_name = @new_player_name
where		player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_dview_playlist', 16, 1)
	return -1
end

update	cinelight_certificate_item
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_certificate_item', 16, 1)
	return -1
end

update	cinelight_shell_xref
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_shell_xref', 16, 1)
	return -1
end

update	cinelight_playlist_item
set			player_name = @new_player_name
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to Update table cinelight_playlist_item', 16, 1)
	return -1
end

delete	cinelight_dsn_players
where	player_name = @old_player_name

select	@error = @@error
if	@error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete old player', 16, 1)
	return -1
end

/*
 * Commit and Return
*/
 
commit transaction
return 0
GO
