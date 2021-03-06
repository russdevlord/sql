/****** Object:  StoredProcedure [dbo].[p_delete_movie_programming]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_movie_programming]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_movie_programming]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_movie_programming]		@movie_id		integer,
											@country_code	char(1)

as

declare @error          			int,
        @rowcount					int,
		@current_screening_date		datetime

select 	@current_screening_date = screening_date 
from	film_screening_dates
where 	screening_date_status = 'C'

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: could not determine current screening date.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete movie country
 */

delete	movie_history
where 	movie_id = @movie_id
and		country = @country_code
and		screening_date >= @current_screening_date

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Commit and Return
 */

commit transaction
return 0
GO
