/****** Object:  StoredProcedure [dbo].[p_op_player_date_activation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_player_date_activation]
GO
/****** Object:  StoredProcedure [dbo].[p_op_player_date_activation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[p_op_player_date_activation] @player_name			varchar(40),
										@mode					int,
										@max_ads				int,
										@max_time				int,
										@max_ads_trailers		int,
										@max_time_trailers		int,
										@min_ads				int


as

/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @errno								int,
        @screening_date						datetime,
        @screening_date_csr_open			tinyint

/*
 * Begin Transaction
 */

begin transaction

/*
 * Declare Cursor
 */

if @mode = 1 
	declare 	screening_date_csr cursor static for
	select 		fsd.screening_date
	from 		outpost_screening_dates fsd
	order by 	fsd.screening_date
	for 		read only
else if @mode = 2
	declare 	screening_date_csr cursor static for
	select 		fsd.screening_date
	from 		outpost_screening_dates fsd
	where		screening_date_status <> 'X'
	order by 	fsd.screening_date
	for 		read only

/*
 * Loop Through Screening Dates
 */

open screening_date_csr
select @screening_date_csr_open = 1
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin

	/*
     * Check outpost_venue Date Does Not Already Exist
     */

	select 	@rowcount = count(player_name)
     from 	outpost_player_date
    where 	player_name = @player_name and
          	screening_date = @screening_date

	if(@rowcount = 0)
	begin

      /*
       * Insert outpost_panel Date
       */

		insert into outpost_player_date ( 
					player_name,   
					screening_date,   
					generation_status,
					locked,
					revision,
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
	else
	begin

		update 	outpost_player_date
		set		max_ads = @max_ads,
				max_time = @max_time,
				max_ads_trailers = @max_ads_trailers,
				max_time_trailers = @max_time_trailers,  --added the '@' !!
				min_ads = @min_ads --added the '@' !!
		where	player_name = @player_name
		and		screening_date = @screening_date

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
