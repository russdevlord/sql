/****** Object:  StoredProcedure [dbo].[p_movie_certgrp_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_certgrp_update]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_certgrp_update]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_movie_certgrp_update] @movie_id			integer,
                                   @complex_id		integer,
											  @screening_date datetime,	
                                   @occurence		smallint,
                                   @cert_group		integer
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          int,
        @rowcount			int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Movie History
 */

update movie_history
   set certificate_group = @cert_group
 where movie_id = @movie_id and
       complex_id = @complex_id and
		 screening_date = @screening_date and	
       occurence = @occurence

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'p_movie_certgrp_update:update', 16, 1) 
	return -1
end	

commit transaction
return 0
GO
