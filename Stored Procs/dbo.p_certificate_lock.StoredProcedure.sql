/****** Object:  StoredProcedure [dbo].[p_certificate_lock]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_lock]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_lock]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROC [dbo].[p_certificate_lock] @complex_id		        int,
                               @screening_date	        datetime,
                               @user				    char(30),
                               @generating              char(1)
as

declare @error     		int,
        @rowcount       int,
        @complex_date	int,
        @available		char(1),
        @lock_user		char(30),
        @locked			char(1),
        @market         int

if @generating = 'Y'
begin

    /* 
     * Get Film Market
     */
     
    select @market = film_market_no
      from complex
     where complex_id = @complex_id

    select @error = @@error

    if (@error != 0)
    begin
	    raiserror ( 'Error', 16, 1) 
        return -1
    end	

    /*
     * Locate Complex Date
     */

      select @lock_user = certificate_lock_user,
             @locked = certificate_locked
        from complex_date,
             complex
       where complex_date.complex_id = complex.complex_id
         and screening_date = @screening_date
         and complex.film_market_no = @market
         and complex.film_complex_status <> 'C'
    group by certificate_lock_user,
             certificate_locked   

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    raiserror ('Error', 16, 1)
        return -1
    end	

    if (@rowcount != 1)
    begin
	    raiserror ('A certificate is locked within the market preventing the market being locked', 16, 1)
        return -1
    end	

    if (@locked = 'Y')
    begin
	    raiserror ('Certificate locked by %s', 16, 1, @lock_user)
        return -1
    end	

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to lock the Complex Date
     */

    update complex_date
       set certificate_lock_user = @user,
           certificate_locked = 'Y'
      from complex
     where certificate_locked = 'N'
       and complex_date.screening_date = @screening_date
       and complex.complex_id = complex_date.complex_id
       and complex.film_market_no = @market
       and complex.film_complex_status <> 'C'
           

    select @error = @@error

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ( 'Error', 16, 1) 
        return -1
    end	

end
else if @generating = 'N'
begin

    /*
     * Locate Complex Date
     */

    select @complex_date = complex_date_id,
           @lock_user = certificate_lock_user,
           @locked = certificate_locked
      from complex_date
     where complex_id = @complex_id and
           screening_date = @screening_date

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    raiserror ( 'Error', 16, 1) 
       return -1
    end	

    if (@rowcount != 1)
    begin
	    raiserror ('Error - more than one row found to unlock in complex_date table', 16, 1)
        return -1
    end	

    if (@locked = 'Y')
    begin
	    raiserror ('Certificate locked by %s', 16, 1, @lock_user)
        return -1
    end	

    /*
     * Begin Transaction
     */

    begin transaction

    /*
     * Attempt to lock the Complex Date
     */

    update complex_date
       set certificate_lock_user = @user,
           certificate_locked = 'Y'
     where complex_date_id = @complex_date and
           certificate_locked = 'N'

    select @error = @@error,
           @rowcount = @@rowcount

    if (@error != 0)
    begin
	    rollback transaction
	    raiserror ( 'Error', 16, 1) 
       return -1
    end	

    if (@rowcount = 0)
    begin
	    rollback transaction
	    raiserror ('Error - no row found to unlock in complex_date table', 16, 1)
	    return -1
    end
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
