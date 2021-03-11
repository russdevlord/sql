USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_date_activation]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_cinelight_date_activation] @cinelight_id		int
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
		@max_time_trailers					int



/*
 * Begin Transaction
 */

begin transaction

/*
 * Declare Cursor
 */

select 	@max_ads = max_ads,
       	@max_time = max_time,
       	@max_ads_trailers = max_ads_trailers,
       	@max_time_trailers = max_time_trailers
  from 	cinelight
 where 	cinelight_id = @cinelight_id


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

	select 	@rowcount = count(cinelight_id)
     from 	cinelight_date
    where 	cinelight_id = @cinelight_id and
          	screening_date = @screening_date

	if(@rowcount = 0)
	begin

      /*
       * Insert Cinelight Date
       */

		insert into cinelight_date ( 
					cinelight_id,   
					screening_date,   
					cinelight_generation_status,
					cinelight_locked,
					cinelight_revision,
					max_ads,
					max_time,
			       	max_ads_trailers,
       				max_time_trailers) values (
					@cinelight_id,
					@screening_date,
					'N',
					'N',
					-1,
					@max_ads,
			       	@max_time,
			       	@max_ads_trailers,
			       	@max_time_trailers)
	
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
