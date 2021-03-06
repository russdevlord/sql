/****** Object:  StoredProcedure [dbo].[p_op_reset]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_reset]
GO
/****** Object:  StoredProcedure [dbo].[p_op_reset]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Create   PROC [dbo].[p_op_reset] 	@player_name		varchar(40),
                                @screening_date 	datetime
as

/*
 * Declare Variables
 */

declare @error     				int,
        @errorode                 int,
        @spot_id				int,
        @charge_rate			money,
		@rate					money

/*
 * Begin Transaction
 */

begin transaction

update outpost_player_date 
   set generation_user = Null,
       generation = Null,
       generation_status = 'N'
 where player_name = @player_name and
       screening_date = @screening_date

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

/**************/
delete  outpost_shell_certificate_xref --outpost_panel_certificate_xref
from	outpost_certificate_item  --outpost_panel_certificate_item
where	player_name = @player_name
and		screening_date = @screening_date
and 	outpost_shell_certificate_xref.certificate_item_id = outpost_certificate_item.certificate_item_id

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

delete tmp_op_prev_pl_det --temp_prev_pl_det 
from outpost_playlist 
where outpost_playlist.player_name = @player_name
and  outpost_playlist.screening_date = @screening_date
and tmp_op_prev_pl_det.playlist_id = outpost_playlist.playlist_id   

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

delete outpost_playlist_segment 
from outpost_playlist 
where  outpost_playlist.player_name = @player_name
and    outpost_playlist.screening_date = @screening_date
AND outpost_playlist_segment.playlist_id = outpost_playlist.playlist_id 

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

delete outpost_playlist_item_spot_xref
from outpost_playlist_item, outpost_playlist 
where  outpost_playlist.player_name = @player_name
and    outpost_playlist.screening_date = @screening_date
AND outpost_playlist_item.playlist_id = outpost_playlist.playlist_id 
and	 outpost_playlist_item_spot_xref.outpost_playlist_item_id = outpost_playlist_item.outpost_playlist_item_id

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

delete outpost_playlist_item
from outpost_playlist 
where  outpost_playlist.player_name = @player_name
and    outpost_playlist.screening_date = @screening_date
AND outpost_playlist_item.playlist_id = outpost_playlist.playlist_id 

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

delete outpost_playlist_spot_xref
from outpost_playlist 
where  outpost_playlist.player_name = @player_name
and    outpost_playlist.screening_date = @screening_date
AND outpost_playlist_spot_xref.playlist_id = outpost_playlist.playlist_id 

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

delete outpost_playlist where player_name = @player_name
and		screening_date = @screening_date

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	


delete  outpost_certificate_xref --outpost_panel_certificate_xref
from	outpost_certificate_item  --outpost_panel_certificate_item
where	player_name = @player_name
and		screening_date = @screening_date
and 	outpost_certificate_xref.certificate_item_id = outpost_certificate_item.certificate_item_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

delete	outpost_certificate_item --outpost_panel_certificate_item
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

update 		outpost_spot
set 		spot_status = 'A'
from		outpost_player_xref --outpost_panel_dsn_player_xref
where 		outpost_spot.outpost_panel_id = outpost_player_xref.outpost_panel_id and
			outpost_spot.screening_date = @screening_date and
			outpost_player_xref.player_name = @player_name and
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
