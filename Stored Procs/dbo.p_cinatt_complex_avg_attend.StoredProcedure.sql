/****** Object:  StoredProcedure [dbo].[p_cinatt_complex_avg_attend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_complex_avg_attend]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_complex_avg_attend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_complex_avg_attend] @min_date datetime, @max_date datetime
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
        @complex_id				integer,
        @complex_id_store		integer,
        @package_id				integer,
        @screening_date			datetime,
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

create table #results
(	screening_date      datetime    null,
    complex_id          integer null,
    complex_region_class char(1) null,
    film_market_no      integer null,
    campaign_safety_limit smallint null,
    movie_target smallint null,
    complex_name        varchar(50) null,
    branch_code         char(2) null,
    state_code          char(3) null,
    number_of_movies    integer null,
    attendance          integer null)


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

/*
 * Declare Cursor
 */
declare screening_date_csr cursor static for
select  distinct screening_date
from    cinema_attendance
where   screening_date >= @min_date
and     screening_date <= @max_date
order by screening_date
for read only

/*
 * Loop dates
 */
open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin
    select @screening_date_csr_open = 1
    /*
     * Loop Complexes
     */
	declare complex_csr cursor static for
	select  complex_id,
	        complex_name,
	        branch_code,
	        state_code,
	        complex_region_class,
	        film_market_no,
	        campaign_safety_limit,
	        movie_target
	from    complex
	where   complex_id in (select distinct complex_id
	                        from    cinema_attendance
	                        where   screening_date >= @min_date
	                        and     screening_date <= @max_date)
	order by complex_id
	for read only

    open complex_csr
    fetch complex_csr into @complex_id, @complex_name, @branch_code, @state_code, @complex_region_class, @film_market_no, @campaign_safety_limit, @movie_target
    while(@@fetch_status = 0)
    begin
        select @complex_csr_open = 1
        /*
         * Loop Movies
         */
       	select  @attendance = 0,
                @actual_attendance = 0,
                @number_of_movies = 0


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

          	if(@actual = 'Y')
            begin
       			select @actual_attendance = @actual_attendance + @attendance
                select @number_of_movies  = @number_of_movies + 1
            end


            fetch movie_csr into @movie_id
    	end /*while*/
        close movie_csr
        deallocate movie_csr
        select @movie_csr_open = 0

        insert #results(
               screening_date,
               complex_id   ,
               complex_region_class,
               film_market_no,
               campaign_safety_limit,
               movie_target,
               complex_name ,
               branch_code  ,
               state_code   ,
               number_of_movies,
               attendance)
         values( @screening_date,
                 @complex_id   ,
                 @complex_region_class,
                 @film_market_no,
                 @campaign_safety_limit,
                 @movie_target,
                 @complex_name ,
                 @branch_code  ,
                 @state_code   ,
                 @number_of_movies,
                 @actual_attendance)
        if (@@error != 0)
		  goto error

        fetch complex_csr into @complex_id, @complex_name, @branch_code, @state_code, @complex_region_class, @film_market_no, @campaign_safety_limit, @movie_target
    end /*while*/
    close complex_csr
    deallocate complex_csr
    select @complex_csr_open = 0
    fetch screening_date_csr into @screening_date
end /*while*/


	 if(@movie_csr_open = 1)
    begin
		 close movie_csr
		 deallocate  movie_csr
	 end

	 if(@complex_csr_open = 1)
    begin
		 close complex_csr
		 deallocate  complex_csr
	 end

	 if(@screening_date_csr_open  = 1)
    begin
		 close screening_date_csr
		 deallocate  screening_date_csr
	 end

/*
 * Return Dataset
 */

select 	convert(varchar(30),screening_date,103),
               complex_id   ,
               complex_region_class,
               film_market_no,
               campaign_safety_limit,
               movie_target,
               complex_name ,
               branch_code  ,
               state_code   ,
               number_of_movies,
               attendance
from #results
order by complex_id,
         screening_date

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

	 if(@complex_csr_open = 1)
    begin
		 close complex_csr
		 deallocate  complex_csr
	 end

	 if(@screening_date_csr_open  = 1)
    begin
		 close screening_date_csr
		 deallocate  screening_date_csr
	 end

	 return -1
GO
