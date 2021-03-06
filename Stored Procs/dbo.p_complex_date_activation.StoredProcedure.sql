/****** Object:  StoredProcedure [dbo].[p_complex_date_activation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_date_activation]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_date_activation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_complex_date_activation] @complex_id		int
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
        @complex_date_id					int,
        @cd									int,
        @campaign_safety_limit				smallint,
        @clash_safety_limit					smallint,
        @movie_target						smallint,
        @session_target						smallint,
        @max_ads							smallint,
        @max_time							smallint,
        @mg_max_ads							smallint,
        @mg_max_time						smallint,
        @cplx_max_ads						smallint,
        @cplx_max_time						smallint,
        @certificate_confirmation			char(1),
		@session_threshold					int,
		@gold_rights						char(1),
		@cinatt_weighting					numeric(6,4)


/*
 * Initialise Cursor Flags
 */

select @screening_date_csr_open = 0

/*
 * Get Complex Settings
 */

select 	@campaign_safety_limit = campaign_safety_limit,
       	@clash_safety_limit = clash_safety_limit,
       	@movie_target = movie_target,
       	@session_target = session_target,
       	@max_ads = max_ads,
       	@max_time = max_time,
       	@mg_max_ads = mg_max_ads,
       	@mg_max_time = mg_max_time,
       	@cplx_max_ads = cplx_max_ads,
       	@cplx_max_time = cplx_max_time,
       	@certificate_confirmation = certificate_confirmation,
		@session_threshold = session_threshold,
		@gold_rights = gold_class_rights,
		@cinatt_weighting = cinatt_weighting
  from 	complex
 where 	complex_id = @complex_id

select @errno = @@error
if (@errno != 0)
	goto error

/*
 * Begin Transaction
 */

begin transaction

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

	select @cd = complex_date_id
     from complex_date
    where complex_id = @complex_id and
          screening_date = @screening_date

	select @rowcount = @@rowcount
	if(@rowcount = 0)
	begin

		/*
       * Get a New Complex Date Id
       */

		execute @errorode = p_get_sequence_number 'complex_date', 5, @complex_date_id OUTPUT
		if(@errorode < 0)
		begin
			select @errno = @@error
			goto error
		end

		/*
       * Insert Complex Date
       */

		insert into complex_date ( 
					complex_date_id,   
					complex_id,   
					screening_date,   
					certificate_status,   
					movies_confirmed,   
					certificate_confirmation,   
					certificate_locked,   
					certificate_revision,   
					campaign_safety_limit,   
					clash_safety_limit,   
					movie_target,   
					session_target,   
					max_ads,   
					max_time,   
					mg_max_ads,   
					mg_max_time,   
					cplx_max_ads,   
					cplx_max_time,   
					no_movies,
					session_threshold,
					gold_class_rights,
					cinatt_weighting ) values (
					@complex_date_id,
					@complex_id,
					@screening_date,
					'N',
					0,
					@certificate_confirmation,
					'N',
					-1,
					@campaign_safety_limit,
					@clash_safety_limit,
					@movie_target,
					@session_target,
					@max_ads,
					@max_time,
					@mg_max_ads,   
					@mg_max_time,   
					@cplx_max_ads,   
					@cplx_max_time,   
					
					0 ,
					@session_threshold,
					@gold_rights,
					@cinatt_weighting)
	
		select @errno = @@error
		if (@errno != 0)
			goto error

	end
	else
	begin

		/*
       * Update Complex Date
       */

		update complex_date  
			set campaign_safety_limit = @campaign_safety_limit,
				 clash_safety_limit = @clash_safety_limit,
				 movie_target = @movie_target,
				 session_target = @session_target,
				 max_ads = @max_ads,
				 max_time = @max_time,
				 mg_max_ads = @mg_max_ads,
				 mg_max_time = @mg_max_time,
				 cplx_max_ads = @cplx_max_ads,
				 cplx_max_time = @cplx_max_time,
				 session_threshold = @session_threshold,
				 gold_class_rights = @gold_rights,
				 cinatt_weighting = @cinatt_weighting
       where complex_date.complex_date_id = @cd

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
