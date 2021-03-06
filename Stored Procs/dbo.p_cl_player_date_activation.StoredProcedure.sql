/****** Object:  StoredProcedure [dbo].[p_cl_player_date_activation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_player_date_activation]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_player_date_activation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cl_player_date_activation] @player_name		varchar(40)

as

/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @errno								int,
        @screening_date						datetime,
        @screening_date_csr_open			tinyint,
		@max_ads							int,
		@max_time							int,
		@max_ads_trailers					int,
		@max_time_trailers					int,
        @min_ads                            int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Set max ads and max time
 */

select 	@max_ads = max_ads,
		@max_time = max_time,
		@max_ads_trailers = max_ads_trailers,
		@max_time_trailers = max_time_trailers,
        @min_ads = min_ads
from	cinelight_dsn_players
where 	player_name = @player_name

/*
 * Declare Cursor
 */

 declare screening_date_csr cursor static for
  select fsd.screening_date
    from film_screening_dates fsd
   where fsd.complex_date_removed = 'N'
order by fsd.screening_date
     for read only
 
/*
 * Loop Through Screening Dates
 */

open screening_date_csr
select @screening_date_csr_open = 1
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin

	/*
     * Check Complex Date Does Not Already Exist
     */

	select 	@rowcount = count(player_name)
     from 	cinelight_dsn_player_date
    where 	player_name = @player_name and
          	screening_date = @screening_date

	if(@rowcount = 0)
	begin

      /*
       * Insert Cinelight Date
       */

		insert into cinelight_dsn_player_date ( 
					player_name,   
					screening_date,   
					cinelight_generation_status,
					cinelight_locked,
					cinelight_revision,
					max_ads,
					max_time,
					max_ads_trailers,
					max_time_trailers,
                    min_ads) values (
					@player_name,
					@screening_date,
					'N',
					'N',
					-1,
					@max_ads,
					@max_time,
					@max_ads_trailers,
					@max_time_trailers,
                    @min_ads)
	
		select @errno = @@error
		if (@errno != 0)
			goto error

	end

	/*
    * Fetch Next Spot
    */

	fetch screening_date_csr into @screening_date

end
close screening_date_csr
select @screening_date_csr_open = 0
deallocate screening_date_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	 rollback transaction
	 if(@screening_date_csr_open = 1)
    begin
		 close screening_date_csr
		 deallocate screening_date_csr
	 end

	 return -1
GO
