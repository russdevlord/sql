/****** Object:  StoredProcedure [dbo].[p_op_stamp]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_stamp]
GO
/****** Object:  StoredProcedure [dbo].[p_op_stamp]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_stamp]		@player_name				varchar(40),
                                 												@screening_date			datetime,
                                 												@user          						char(30),
                                 												@status							char(1)
as

declare			@error     											int,
						@sent_revision								smallint,
						@new_revision								smallint,
						@playlist_id									int,
						@outpost_playlist_item_id		int,
						@new_id											int,
						@print_id											int,
						@sequence_no							int,
						@item_comment							varchar(100),
						@item_show									char(1),
						@certificate_auto_create			char(1),
						@certificate_source						char(1),
						@campaign_summary				char(1),
						@weather_sequence						int,
						@resolve_sequence						int,
						@weather_count							int,
						@resolve_count							int
					   
/*
 * Get Revision Numbers
 */

select		@sent_revision = IsNull(max(revision),-1)
from			outpost_player_date
where		player_name = @player_name 
and				screening_date = @screening_date

/*
 * Calculate New revision
 */

select @new_revision = @sent_revision + 1

/*
 * Begin Transaction
 */

begin transaction

/*
 * Set the outpost_panel Generation and Revision
 */

update		outpost_player_date 
set				generation = getdate(),
					revision = @new_revision,
					generation_user = @user,
					generation_status = @status
where		player_name = @player_name 
and				screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

declare		playlist_csr cursor for
select			playlist_id 
from			outpost_playlist
where			player_name = @player_name
and				screening_date = @screening_date
order by		playlist_id
for				read only

open playlist_csr
fetch playlist_csr into @playlist_id
while(@@fetch_status = 0)
begin

		select		@weather_sequence = sequence_no,
						@weather_count = count(*)
		from		outpost_playlist_item
		where		playlist_id = @playlist_id 
		and			print_id in (4548, 7649)
		group by	sequence_no	
		
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error getting weather sequence', 16, 1)
			return -1
		end			

		select		@resolve_sequence	= sequence_no,
						@resolve_count = count(*)
		from		outpost_playlist_item
		where		playlist_id = @playlist_id 
		and			print_id = 6680
		group by	sequence_no	
				
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error getting resolve sequence', 16, 1)
			return -1
		end			

		if @resolve_count > 0 and @weather_count > 0 
		begin
			update	outpost_playlist_item
			set			sequence_no = @weather_sequence
			where		playlist_id = @playlist_id 
			and			print_id = 6680	

			select @error = @@error
			if (@error != 0)
			begin
				rollback transaction
				raiserror ('Error setting resolve sequence', 16, 1)
				return -1
			end			
			
			update	outpost_playlist_item
			set			sequence_no = @resolve_sequence
			where		playlist_id = @playlist_id 
			and			print_id in (4548, 7649)


			select @error = @@error
			if (@error != 0)
			begin
				rollback transaction
				raiserror ('Error setting weather sequence', 16, 1)
				return -1
			end			
		end 

	fetch playlist_csr into @playlist_id
end

close playlist_csr

/*
 * Commit and Return
 */

commit transaction
return 0
GO
