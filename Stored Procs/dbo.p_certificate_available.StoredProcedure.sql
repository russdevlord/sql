/****** Object:  StoredProcedure [dbo].[p_certificate_available]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_available]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_available]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_available] @complex_id			int,
                                    @screening_date	datetime
as

/*
 * Declare Variables
 */

declare @error     		int,
        @reason			varchar(255),
        @film_status		char(1),
        @no_movies		smallint

/*
 * Check the status of the complex
 */

select @film_status = film_complex_status
from complex
where complex_id = @complex_id

if (@film_status = 'C')
begin
	raiserror ('Error - Complex is closed', 16, 1)
   	return -1
end

/*
 * Check if complex has downtime
 */

select @reason = reason
  from film_complex_downtime
 where complex_id = @complex_id and
       screening_date = @screening_date

if(@@rowcount > 0)
begin
	raiserror ('Error - Complex is unavailable for this week', 16, 1)
	return -1
end

/*
 * Check if the No Movie Flag is Set on the Complex Date Table
 */

select @no_movies = no_movies
  from complex_date
 where complex_id = @complex_id and
       screening_date = @screening_date

if(@no_movies = 1)
begin
	raiserror ('Error - Complex is programmed for no movies this week', 16, 1)
	return -1
end

/*
 * Return
 */

return 0
GO
