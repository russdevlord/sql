/****** Object:  StoredProcedure [dbo].[p_activate_movies]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activate_movies]
GO
/****** Object:  StoredProcedure [dbo].[p_activate_movies]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Proc name:   p_activate_movies
 * Author:      
 * Modified: Victoria Tyshchenko
 * Description: 
 *      This procedure adds and removes movies from the active movie list.
 *      This procedure will normally be called during the closure of the
 *      screening date.
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Aug 26 2004 09:10:22  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   activate_movies.sql  $
 *
*/ 


CREATE PROC [dbo].[p_activate_movies] @opening_date        datetime,
                              @closing_date			datetime,
                              @min_active_period	smallint,
                              @activate_period		smallint
as

/*
 * Declare Variables
 */

declare @error     		int,
        @count			smallint,
        @active_start	datetime,
        @active_end		datetime,
        @proc_name      varchar(30),
        @country_code   varchar(2),
        @err_msg        varchar(255)
        
select @proc_name = 'p_activate_movies'
/*
 * Calculate Active Period
 */

select @active_end = dateadd(Week,@activate_period,@opening_date)
select @active_start = dateadd(Week,0 - @min_active_period,@opening_date)

/*
 * Begin Transaction
 */

begin transaction

/*
 * Remove all Movies from the active movie list
 */

/*update movie
   set active = 'N'
where active = 'Y'
*/
update movie_country
   set active = 'N'
where active = 'Y'

select @error = @@error
if @error != 0
   goto error 


/*update movie
   set active = 'Y'
  from movie,
       movie_history hist
 where movie.movie_id = hist.movie_id and
       hist.screening_date = @closing_date
*/
declare cur_country cursor static for
select  country_code
from    country       

open cur_country
select @error = @@error
if @error != 0
   goto error 

fetch cur_country into @country_code
while (@@fetch_status = 0)
    begin
        /*
         * Add all movies that were entered in as apart of the closing weeks programming
         */
        update  movie_country
        set     active = 'Y'
        where   country_code = @country_code
        and     movie_id in (select movie_id from movie_history 
                            where movie_history.screening_date = @closing_date and country = @country_code )
        and     movie_id in (select movie_id from movie_country where country_code = @country_code and release_date <= @opening_date)                            
                            
        select @error = @@error
        if @error != 0
           goto error 
    
    
        /*
         * Add all movies due to be released in the 2 weeks along with any
         * that have been released for less than the minimum active period
         */
        /*update movie
           set active = 'Y'
          from movie,
               movie_country mc
         where movie.movie_id = mc.movie_id and
               mc.release_date >= @active_start and
               mc.release_date <= @active_end */
    
        update  movie_country
        set     active = 'Y'
        from    movie_country mc
        where   mc.release_date >= @active_start and
                mc.release_date <= @active_end and
                mc.country_code = @country_code
                
        select @error = @@error
        if @error != 0
           goto error 
    
        fetch cur_country into @country_code
    end


deallocate cur_country

/*
 * Commit Transaction and Return
 */

commit transaction
return 0


error:
    deallocate cur_country
    
    if @error >= 50000 -- developer generated errors
    begin
        select @err_msg = @proc_name + ': ' + isnull(@err_msg, 'Error occured')
        raiserror (@err_msg, 16, 1)
    end     
--    else
--        raiserror ( @error, 16, 1)

    return -100
GO
