/****** Object:  StoredProcedure [dbo].[p_cinelight_unlock]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_unlock]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_unlock]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[p_cinelight_unlock] @player_name			varchar(40),
                                 @screening_date	    datetime,
                                 @override			    char(1),
                                 @user					char(30),
                                 @generating            char(1)
as

declare @error     		int,
        @rowcount       int,
        @cinelight_date	int,
        @available		char(1),
        @lock_user	    char(30),
        @locked			char(1),
        @market         int

select @override  'Y'

if @generating = 'Y'
begin

    /*
     * Locate Complex Date
     */

      select @lock_user = cinelight_lock_user,
             @locked = cinelight_locked
        from cinelight_dsn_player_date
       where cinelight_dsn_player_date.player_name = @player_name
         and screening_date = @screening_date
    group by cinelight_lock_user,
             cinelight_locked 


      select @error = @@error,
             @rowcount = @@rowcount

    if (@error != 0)
    begin
        raiserror ('Error', 16, 1)
        return -1
    end	

    if (@rowcount != 1)
    begin
	    raiserror ('Error 1', 16, 1)
        return -1
    end	

    if (@override = 'N')
    begin
	    if (@lock_user != @user)
	    begin
		    raiserror ('User', 16, 1)
		    return -1
	    end	
    end

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to unlock the Complex Date
     */

    update cinelight_dsn_player_date
       set cinelight_locked = 'N',
           cinelight_lock_user = Null
      from cinelight_dsn_player_date
     where screening_date = @screening_date
       and (cinelight_lock_user = @user
        or @override = 'Y')
       and cinelight_locked = 'Y'
       and @player_name = cinelight_dsn_player_date.player_name

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ('Error 4', 16, 1)
        return @error
    end	
end
else if @generating = 'N'
begin

    /*
     * Locate Complex Date
     */

    select @lock_user = cinelight_lock_user,
           @locked = cinelight_locked
      from cinelight_dsn_player_date
     where player_name = @player_name and
           screening_date = @screening_date

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    raiserror ('Error 5', 16, 1)
       return -1
    end	

    if (@rowcount = 0)
    begin
	    raiserror ('Error 6', 16, 1)
       return -1
    end	

    if (@override = 'N')
    begin
	    if (@lock_user != @user)
	    begin
		    raiserror ('Error 7', 16, 1)
		    return -1
	    end	
    end

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to unlock the Complex Date
     */

    if (@override = 'N')
	    update cinelight_dsn_player_date
		    set cinelight_locked = 'N',
              cinelight_lock_user = Null
	     where player_name = @player_name and
			    screening_date = @screening_date and
			     cinelight_lock_user = @user and
			     cinelight_locked = 'Y'
    else
	    update cinelight_dsn_player_date
		    set cinelight_locked = 'N',
              cinelight_lock_user = Null
	     where player_name = @player_name and
			    screening_date = @screening_date and
			     cinelight_locked = 'Y'

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ( 'Error', 16, 1) 
       return @error
    end	
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
