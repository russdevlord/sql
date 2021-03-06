/****** Object:  StoredProcedure [dbo].[p_op_create_cinvendo_playlist]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_create_cinvendo_playlist]
GO
/****** Object:  StoredProcedure [dbo].[p_op_create_cinvendo_playlist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Create proc [dbo].[p_op_create_cinvendo_playlist]
@screening_date	datetime,
@player_name	varchar(40)
/*,
@return_information	        	varchar(255) OUTPUT*/
AS

begin transaction

--declare @print_id int, @print_revision int, @playlist_id int, 
declare @print_id int, 
 	@start_date datetime, 
	@end_date datetime,
	@error		int,
	@rowcount	int,
	@certificate_source char(1),
	@sequence_no int, 
@errtext varchar(20),
@print_package int,
@upd int


declare     op_certificate_prints cursor for 

SELECT     			outpost_playlist_segment.start_date, 
				outpost_playlist_segment.end_date,
				outpost_print.print_id, 
				outpost_certificate_item.sequence_no ,
				outpost_certificate_item.certificate_source ,
				dbo.f_outpost_print_package(outpost_certificate_item.certificate_item_id, outpost_certificate_item.print_id) as print_package,
			(select count(*) from outpost_print_files_upd 
			where print_package_id = dbo.f_outpost_print_package(outpost_certificate_item.certificate_item_id, outpost_certificate_item.print_id)) as upd
FROM 			outpost_certificate_item,
--				outpost_player,
--				outpost_venue ,
				outpost_print, outpost_playlist_segment     
WHERE 		--outpost_venue.outpost_venue_id = outpost_player.outpost_venue_id 
         outpost_print.print_id = outpost_certificate_item.print_id
--and			outpost_player.player_name = outpost_certificate_item.player_name
and 			outpost_playlist_segment.playlist_id = outpost_certificate_item.playlist_id
and	   	outpost_certificate_item.item_show = 'Y'
and  
(			outpost_certificate_item.screening_date = @screening_date
and			outpost_certificate_item.player_name = @player_name) 
order by outpost_playlist_segment.start_date, outpost_certificate_item.sequence_no

/*
 * verify the PlayList Media records
 */
DELETE outpost_dview_playlist WHERE player_name = @player_name and start_Date >=@screening_date and end_Date <= DateAdd(dd,7, @screening_date)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting outpost_dview_playlist', 16, 1)
	rollback transaction
	return -1
end


open op_certificate_prints
fetch op_certificate_prints into @start_date, @end_date, @print_id, @sequence_no, @certificate_source , @print_package , @upd
while(@@fetch_status = 0)
begin
        insert into outpost_dview_playlist --(playlist_id, player_name, print_id, print_revision, playOrder) 
	values (@player_name, @start_date, @end_date, @print_id, @sequence_no, @certificate_source, @print_package, @upd)
	IF @@ROWCOUNT != 1
	BEGIN
		--SELECT @return_information = 'INSERT failed - process aborted'
		raiserror ('INSERT failed - process aborted', 16, 1)
	    	rollback transaction
		RETURN -1
	END 
    fetch op_certificate_prints into @start_date, @end_date, @print_id, @sequence_no, @certificate_source , @print_package , @upd
end
deallocate op_certificate_prints

--DBCC CHECKIDENT(outpost_dview_playlist, RESEED, 0)

Update outpost_player_date set dview_scheduleStatus = 0 where player_name = @player_name and   screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating outpost_player_date', 16, 1)
	rollback transaction
	return -1
end


commit transaction
RETURN 0
GO
