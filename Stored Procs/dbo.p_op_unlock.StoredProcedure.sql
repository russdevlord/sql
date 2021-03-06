/****** Object:  StoredProcedure [dbo].[p_op_unlock]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_unlock]
GO
/****** Object:  StoredProcedure [dbo].[p_op_unlock]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_unlock] @player_name			varchar(40),
                                 @screening_date	    datetime,
                                 @override			    char(1),
                                 @user					char(30),
                                 @generating            char(1)
as

declare @error     		int,
        @rowcount       int,
        @outpost_panel_date	int,
        @available		char(1),
        @lock_user	    char(30),
        @locked			char(1),
        @market         int


if @generating = 'Y'
begin

    /*
     * Locate outpost_venue Date
     */

      select @lock_user = lock_user,
             @locked = locked
        from outpost_player_date
       where outpost_player_date.player_name = @player_name
         and screening_date = @screening_date
    group by lock_user,
             locked 


      select @error = @@error,
             @rowcount = @@rowcount

    if (@error != 0)
    begin
        raiserror ('Error unlocking player date', 16, 1)
        return -1
    end	

    if (@rowcount != 1)
    begin
	    raiserror ('Error unlocking player date - no record to update', 16, 1)
        return -1
    end	

    if (@override = 'N')
    begin
	    if (@lock_user != @user)
	    begin
		    raiserror ('You are not the locker - please contact  to get them to unlock', 16, 1)
		    return -1
	    end	
    end

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to unlock the outpost_venue Date
     */

    update outpost_player_date
       set locked = 'N',
           lock_user = Null
      from outpost_player_date
     where screening_date = @screening_date
       and (lock_user = @user
        or @override = 'Y')
       and locked = 'Y'
       and @player_name = outpost_player_date.player_name

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	            raiserror ('Error unlocking player date', 16, 1)
        return @error
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
	    raiserror ('Error unlocking player date', 16, 1)
       return -1
    end	

    if (@rowcount = 0)
    begin
	            raiserror ( 'Error unlocking player date - no record to update', 16, 1)
       return -1
    end	

    if (@override = 'N')
    begin
	    if (@lock_user != @user)
	    begin
		    raiserror ('You are not the locker - please contact  to get them to unlock', 16, 1)
		    return -1
	    end	
    end

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to unlock the outpost_venue Date
     */

    if (@override = 'N')
	    update outpost_player_date
		    set locked = 'N',
              lock_user = Null
	     where player_name = @player_name and
			    screening_date = @screening_date and
			     lock_user = @user and
			     locked = 'Y'
    else
	    update outpost_player_date
		    set locked = 'N',
              lock_user = Null
	     where player_name = @player_name and
			    screening_date = @screening_date and
			     locked = 'Y'

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ('Error unlocking player date', 16, 1)
       return @error
    end	
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
