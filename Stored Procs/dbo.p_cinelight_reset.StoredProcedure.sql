/****** Object:  StoredProcedure [dbo].[p_cinelight_reset]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_reset]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_reset]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinelight_reset] 	@player_name		varchar(40),
                                @screening_date 	datetime
as

/*
 * Declare Variables
 */

declare @error     				int,
        @errorode                 int,
        @spot_id				int,
        @charge_rate			money,
		@rate					money,
		@spot_redirect          int


begin transaction
/*
 * Declare Makeup Csr
 */

 declare makeup_csr cursor static for
  select spot.spot_id,  --unalloc
         spot.spot_redirect  --makeup
    from cinelight_spot spot
   where spot_redirect in (select spot_id
                           from cinelight_spot
                           where cinelight_id in (select cinelight_id from cinelight_dsn_player_xref
												  where player_name = @player_name)
                           and screening_date = @screening_date
                           and spot_type = 'M' )

order by spot.spot_id
     for read only

/*
 * Process Spot Liability and Spot Redirect Rollbacks of Makeup/Manual Spots
 */

open makeup_csr
fetch makeup_csr into @spot_id, @spot_redirect
while(@@fetch_status=0)
begin

    execute @errorode =  p_ffin_cl_unallocate_makeup @spot_redirect

    if @errorode != 0
    begin
        rollback transaction
        raiserror ('Failed to Remove makeup spot liability and spot redirect', 16, 1)
        return -1
    end

    fetch makeup_csr into @spot_id, @spot_redirect
end

close makeup_csr
deallocate makeup_csr

commit transaction




/*
 * Begin Transaction
 */


begin transaction
/*
 * Reset cinelight Date Record
 */

update cinelight_dsn_player_date
   set cinelight_generation_user = Null,
       cinelight_generation = Null,
       cinelight_generation_status = 'N'
 where player_name = @player_name and
       screening_date = @screening_date

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end

delete  cinelight_certificate_xref
from	cinelight_certificate_item
where	player_name = @player_name
and		screening_date = @screening_date
and 	cinelight_certificate_xref.certificate_item_id = cinelight_certificate_item.certificate_item_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

delete  cinelight_shell_certificate_xref
from	cinelight_certificate_item
where	player_name = @player_name
and		screening_date = @screening_date
and 	cinelight_shell_certificate_xref.certificate_item_id = cinelight_certificate_item.certificate_item_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

delete  cinelight_playlist_item_spot_xref
from cinelight_playlist_item
where player_name = @player_name
and screening_date = @screening_date
and cinelight_playlist_item_spot_xref.cinelight_playlist_item_id = cinelight_playlist_item.cinelight_playlist_item_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

delete  cinelight_playlist_item
where player_name = @player_name
and screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

delete  cinelight_playlist_spot_xref
from cinelight_playlist
where player_name = @player_name
and screening_date = @screening_date
and cinelight_playlist_spot_xref.playlist_id = cinelight_playlist.playlist_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

delete  cinelight_playlist
where player_name = @player_name
and screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end


delete	cinelight_certificate_item
where	player_name = @player_name
and		screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

/*
 * Reset All Allocated, Unallocated and No Shows
 */

update 		cinelight_spot
set 		spot_status = 'A'
from		cinelight_dsn_player_xref
where 		cinelight_spot.cinelight_id = cinelight_dsn_player_xref.cinelight_id and
			cinelight_spot.screening_date = @screening_date and
			cinelight_dsn_player_xref.player_name = @player_name and
			( spot_status = 'X' or
			spot_status = 'U' or
			spot_status = 'N'  )

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
