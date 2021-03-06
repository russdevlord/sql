/****** Object:  StoredProcedure [dbo].[p_cinatt_pop_cplx_attendnz]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_pop_cplx_attendnz]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_pop_cplx_attendnz]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_pop_cplx_attendnz] @screening_date datetime,
                                     @forecast_years tinyint
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @current_year_offset    tinyint,
        @current_screening_date datetime,
        @complex_id             integer,
        @movie_csr_open         tinyint,
        @complex_csr_open       tinyint,
        @attendance             integer,
        @actual_attendance      integer,
        @movie_id               integer,
        @number_of_movies       integer,
        @errorode                  tinyint,
        @actual                 char(1),
        @period_no              tinyint,
        @base_finyear           datetime,
        @next_finyear           datetime


select  @movie_csr_open = 0,
        @complex_csr_open = 0

select  @base_finyear = finyear_end,
        @period_no = period_no
from    film_screening_dates
where   screening_date = @screening_date
if @@rowcount = 0
    return -1

begin transaction

	/* modify to only process NZ complexes to force NZ refresh */
	declare complex_csr cursor static for
	select  distinct complex_id
	from    cinema_attendance
	where   screening_date = @screening_date
	and     country = 'Z'
	order by complex_id
	for read only

    open complex_csr
    fetch complex_csr into @complex_id
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
       			goto error

   			select @actual_attendance = @actual_attendance + @attendance
            select @number_of_movies  = @number_of_movies + 1

            fetch movie_csr into @movie_id
    	end /*while*/

        close movie_csr
        deallocate movie_csr
        select @movie_csr_open = 0

        if @number_of_movies > 0
        begin
            /* insert new data into warehouse table */
            select @current_year_offset = 0
            while (@current_year_offset <= @forecast_years)
            begin
                select  @next_finyear = dateadd(yy,@current_year_offset,@base_finyear)

                select  @current_screening_date = screening_date
                from    film_screening_dates
                where   finyear_end = @next_finyear
                and     period_no = @period_no

                if (@@rowcount <> 0) and (@current_screening_date is not null)
                begin
                    /*always delete any existing warehouse data for selected period*/
                    delete  cinema_attendance_by_complex
                    where   screening_date = @current_screening_date
                    and     complex_id = @complex_id
                    if @@error <> 0
                        goto error

                    insert into cinema_attendance_by_complex
                                (complex_id      ,
                                 screening_date  ,
                                 total_attendance,
                                 avg_per_movie   ,
     actual          )
                    select  @complex_id,
                            @current_screening_date,
                            @actual_attendance,
                            @actual_attendance / @number_of_movies,
                            case when @current_year_offset = 0 then 1 else 0 end
                    if @@error <> 0
                        goto error

                    /* handle special case for period 53's, try and see if there is one */
                    if @period_no = 52
                    begin
                        select  @current_screening_date = screening_date
                        from    film_screening_dates
                        where   finyear_end = @next_finyear
                        and     period_no = @period_no + 1

                        if (@@rowcount <> 0) and (@current_screening_date is not null)
                        begin
                            /*always delete any existing warehouse data for selected period*/
                            delete  cinema_attendance_by_complex
                            where   screening_date = @current_screening_date
                            and     complex_id = @complex_id
                            if @@error <> 0
                                goto error

                            insert into cinema_attendance_by_complex
                                        (complex_id      ,
                                         screening_date  ,
                                         total_attendance,
                                         avg_per_movie   ,
                                         actual          )
                            select  @complex_id,
                                    @current_screening_date,
                                    @actual_attendance,
                                    @actual_attendance / @number_of_movies,
                                    case when @current_year_offset = 0 then 1 else 0 end
                            if @@error <> 0
                                goto error
                        end
                    end
                end

                select @current_year_offset = @current_year_offset + 1

            end /*while*/
        end/*if*/

        fetch complex_csr into @complex_id
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

commit transaction

return 0

error:
    rollback transaction
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

	 return -1
GO
