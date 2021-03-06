/****** Object:  StoredProcedure [dbo].[p_cinatt_get_cplx_avg]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_get_cplx_avg]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_get_cplx_avg]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_get_cplx_avg] @screening_date datetime,
                                  @complex_id integer
as
set nocount on 
/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @film_market_no			integer,
        @spot_id					integer,
        @complex_id_store		integer,
        @package_id				integer,
        @spot_status				char(1),
        @pack_code				char(1),
        @charge_rate				money,
        @start						tinyint,
	     @actual_attendance		integer,
        @estimated_attendance	integer,
	     @location_cost			money,
	     @cancelled_cost			money,
        @attendance				integer,
        @movie_id					integer,
        @actual					char(1),
        @duration               smallint,
        @campaign_no            integer,
        @movie_csr_open         tinyint,
        @complex_csr_open       tinyint,
        @screening_date_csr_open tinyint,
        @complex_name               varchar(50),
        @branch_code                char(2),
        @state_code                 char(3),
        @number_of_movies           integer,
        @complex_region_class       char(1),
        @campaign_safety_limit       smallint,
        @movie_target               smallint


/*
 * Create Temporary Tables
 */


select @start = 0,
       @complex_id_store = 0,
	    @actual_attendance = 0,
       @estimated_attendance = 0,
	    @location_cost = 0,
	    @cancelled_cost = 0,
        @duration = 0,
        @movie_csr_open = 0,
        @complex_csr_open = 0,
        @screening_date_csr_open = 0

       	select  @attendance = 0,
                @actual_attendance = 0,
                @number_of_movies = 0


		/*
		 * Declare Cursor
		 */
		declare movie_csr cursor static for
		select  distinct cinema_attendance.movie_id
		from    cinema_attendance, movie_history
		where   cinema_attendance.screening_date = @screening_date
		and     cinema_attendance.complex_id = @complex_id
		and     cinema_attendance.screening_date = movie_history.screening_date
		and     cinema_attendance.complex_id = movie_history.complex_id
		order by cinema_attendance.movie_id
		for read only

        open movie_csr
        fetch movie_csr into @movie_id
        while(@@fetch_status = 0)
        begin
            select @movie_csr_open = 1

      		exec @errorode = p_cinatt_get_movie_attendance    @screening_date,
													       @complex_id,
        												   @movie_id,
        												   @attendance OUTPUT,
        												   @actual OUTPUT

       		if(@errorode !=0)
       		begin
       			goto error
       		end

       			select @actual_attendance = @actual_attendance + @attendance
                select @number_of_movies  = @number_of_movies + 1

            fetch movie_csr into @movie_id
    	end /*while*/
        close movie_csr
         deallocate  movie_csr
        select @movie_csr_open = 0


select @actual_attendance, @number_of_movies

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:


	 if(@movie_csr_open = 1)
    begin
		 close movie_csr
		 deallocate  movie_csr
	 end

	 return -1
GO
