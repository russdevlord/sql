/****** Object:  StoredProcedure [dbo].[p_cinelight_lock]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_lock]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_lock]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_cinelight_lock] 	@player_name		        varchar(40),
                               	@screening_date	        	datetime,
                               	@user				    	varchar(30),
                               	@generating              	char(1)
as

declare @error     		int,
        @rowcount       int,
        @available		char(1),
        @lock_user		char(30),
        @locked			char(1),
        @error_msg		varchar(255)
       


if @generating = 'Y'
begin

    /*
     * Locate Complex Date
     */

	select 			@lock_user = cinelight_lock_user,
						@locked = cinelight_locked
	from 			cinelight_dsn_player_date
	where 		cinelight_dsn_player_date.player_name = @player_name
	and 			screening_date = @screening_date
	group by 	cinelight_lock_user,
						cinelight_locked   

    select	@error = @@error,
				@rowcount = @@rowcount

    if (@error != 0) or (@rowcount != 1)
    begin
	    raiserror ('Error obtaining lock details', 16, 1)
        return -1
    end	

    if (@locked = 'Y')
    begin
	    raiserror ('Error certificate already locked by %1', 16, 1, @lock_user)
        return -1
    end	

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to lock the Complex Date
     */

	update 		cinelight_dsn_player_date
	set 				cinelight_lock_user = @user,
						cinelight_locked = 'Y'
	where 		cinelight_locked <> 'Y'
	and 			cinelight_dsn_player_date.screening_date = @screening_date
	and 			cinelight_dsn_player_date.player_name = @player_name

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ('Error attempting to lock the certificate 1', 16, 1)
        return -1
    end	

end
else if @generating = 'N'
begin

    /*
     * Locate Complex Date
     */

	select			@lock_user = cinelight_lock_user,
						@locked = cinelight_locked
	from			cinelight_dsn_player_date
	where			player_name = @player_name 
	and				screening_date = @screening_date

    select	@error = @@error,
				@rowcount = @@rowcount

    if (@error != 0)
    begin
	    raiserror ('Error obtaining lock details', 16, 1)
		return -1
    end	

    if (@rowcount = 0)
    begin
	    raiserror ('Error obtaining lock details', 16, 1)
		return -1
    end	

    if (@locked = 'Y')
    begin
	    raiserror ('Error certificate already locked', 16, 1, @lock_user)
		return -1
    end	

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to lock the Complex Date
     */

	update 		cinelight_dsn_player_date
	set 				cinelight_lock_user = @user,
						cinelight_locked = 'Y'
	where 		player_name = @player_name
	and				screening_date = @screening_date
	and				cinelight_locked <> 'Y'

    select	@error = @@error,
				@rowcount = @@rowcount

    if (@error != 0) 
    begin
	    rollback transaction
	    raiserror ('Error attempting to lock the certificate 2', 16, 1)
        return -1
    end	

	if (@rowcount = 0)
    begin
	    rollback transaction
	    select  @error_msg = 'User: ' + @user + ', Player: ' + @player_name + ', Date: ' + CONVERT(varchar(30), @screening_date, 104) + ', Gen: ' + @generating
	    raiserror (@error_msg, 16, 1)
	    return -1
    end
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
