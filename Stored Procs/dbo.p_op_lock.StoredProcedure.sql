/****** Object:  StoredProcedure [dbo].[p_op_lock]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_lock]
GO
/****** Object:  StoredProcedure [dbo].[p_op_lock]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_lock] 	@player_name		        varchar(40),
                               	@screening_date	        	datetime,
                               	@user				    	char(30),
                               	@generating              	char(1)
as

declare @error     		int,
        @rowcount       int,
        @available		char(1),
        @lock_user		char(30),
        @locked			char(1)

if @generating = 'Y'
begin

    /*
     * Locate outpost_venue Date
     */

	select 		@lock_user = lock_user,
				@locked = locked
	from 		outpost_player_date
	where 		outpost_player_date.player_name = @player_name
	and 		screening_date = @screening_date
	group by 	lock_user,
				locked   

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    raiserror ('Error locking player date', 16, 1)
        return -1
    end	

    if (@rowcount != 1)
    begin
	    raiserror ('Error locking player date - no record to lock', 16, 1)
        return -1
    end	

    if (@locked = 'Y')
    begin
	    raiserror ('Player is already locked', 16, 1)
        return -1
    end	

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to lock the outpost_venue Date
     */

	update 		outpost_player_date
	set 		lock_user = @user,
				locked = 'Y'
	where 		locked <> 'Y'
	and 		outpost_player_date.screening_date = @screening_date
	and 		outpost_player_date.player_name = @player_name

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ('Error locking player date', 16, 1)
        return -1
    end	

end
else if @generating = 'N'
begin

    /*
     * Locate outpost_venue Date
     */

    select @lock_user = lock_user,
           @locked = locked
      from outpost_player_date
     where player_name = @player_name and
           screening_date = @screening_date

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    raiserror ('Error locking player date', 16, 1)
	    rollback transaction
       return -1
    end	

    if (@rowcount = 0)
    begin
	    raiserror ('Error locking player date - no rows found 2', 16, 1)
       return -1
    end	

    if (@locked = 'Y')
    begin
	    raiserror ('Error locking player date - record locked by another user', 16, 1)
	    return -1
    end	

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to lock the outpost_venue Date
     */

	update 		outpost_player_date
	set 		lock_user = @user,
				locked = 'Y'
	where 		player_name = @player_name
	and			screening_date = @screening_date
	and			locked <> 'Y'

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ('Error locking player date', 16, 1)
        return -1
    end	

    if (@rowcount = 0)
    begin
	    rollback transaction
	    raiserror ('Error locking player date - no rows found 3', 16, 1)
	    return -1
    end
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
