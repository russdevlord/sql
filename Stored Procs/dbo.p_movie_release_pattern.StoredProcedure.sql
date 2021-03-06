/****** Object:  StoredProcedure [dbo].[p_movie_release_pattern]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_release_pattern]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_release_pattern]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_movie_release_pattern] @arg_movie_id int,
                                    @arg_start_date char(9),
				    @arg_end_date char(9),
                                    @arg_country_code char(1),
                                    @arg_film_market_no int

as
set nocount on 
declare     @screening_date     datetime,
            @week_number        int,
            @weeks              int,
            @max_screening_date datetime,
            @film_market_no     int

select @arg_start_date = right(@arg_start_date,8)

select @arg_end_date = right(@arg_end_date,8)

IF IsNull(@arg_start_date,'19000101') = '19000101'
    select @arg_start_date = ( select min(convert(char(8),screening_date,112))
    FROM   movie_history
    where  movie_id = @arg_movie_id )

IF IsNull(@arg_start_date,'19000101') = '19000101'
    begin
        Select 'No Data Returned' movie_name,
            null film_market_desc,
            null complex_id,
            null complex_name,
            convert(datetime,'1900-01-01 00:00:00.000',121) screening_date,
            null screens,
            null country_code,
            NULL week_number
        Return 0
    end


IF IsNull(@arg_end_date,'20991231') = '20991231'
    select @arg_end_date = ( select max(convert(char(8),screening_date,112))
    FROM   movie_history
    where  movie_id = @arg_movie_id )

 /*
 * Create Temp Table
 */

create table #screens
(     movie_name        varchar(100)    null,
      film_market_desc  varchar(100)    null,
      film_market_no    int              null,
      complex_id        int             null,
      complex_name      varchar(100)    null,
      screening_date    datetime        null,
      screens           int             null,
      country_code      char(1)         null,
      week_number       int             null
)

/*
 * Begin Processing
 */

/*
 * Declare Cursor
 */
declare     film_market_csr cursor static for
select      film_market_no
from        film_market
where       film_market_no = @arg_film_market_no
or          @arg_film_market_no = -1
order by    film_market_no
for         read only

open film_market_csr
fetch film_market_csr into @film_market_no
while(@@fetch_status = 0) 
begin

    declare     screening_csr cursor static for
	select      screening_date
	from        movie_history,
	            complex
	where       movie_id = @arg_movie_id 
	and         movie_history.complex_id = complex.complex_id 
	and         complex.film_market_no = @film_market_no
	and         convert(char(8),screening_date,112) >= @arg_start_date
	and	    convert(char(8),screening_date,112) <= @arg_end_date
	order by    screening_date
	for         read only

    open screening_csr
    fetch screening_csr into @screening_date   
    while(@@fetch_status = 0)
    begin
        insert into #screens
        (           movie_name,
                    film_market_desc,
                    film_market_no,
                    complex_id,
                    complex_name,
                    screening_date,
                    screens,
                    country_code,
                    week_number
        )
        select      movie.long_name,
                    film_market.film_market_desc,
                    film_market.film_market_no,
                    complex.complex_id,
                    complex.complex_name,
                    movie_history.screening_date,
                    count(movie.movie_id) as screens,
                    movie_country.country_code,
                    @week_number as week_number
        from        movie,
                    movie_history,
                    complex,
                    movie_country,
                    state,
                    film_market
        where       movie.movie_id = @arg_movie_id and
                    movie.movie_id = movie_history.movie_id and
                    movie_history.screening_date = @screening_date and
                    movie_history.complex_id = complex.complex_id and
        movie_country.movie_id = movie.movie_id and
                    movie_country.country_code = @arg_country_code and
                    complex.state_code = state.state_code and
                    state.country_code = @arg_country_code and
                    film_market.film_market_no = complex.film_market_no and
                    complex.film_market_no = @film_market_no
        group by    movie.long_name,
                    film_market.film_market_desc,
                    film_market.film_market_no,
                    complex.complex_id,
                    complex.complex_name,
                    movie_history.screening_date,
                    movie_country.country_code,
                    film_market.film_market_no
                    
        fetch screening_csr into  @screening_date
    end
    
    close screening_csr
	deallocate screening_csr

    fetch film_market_csr into @film_market_no
end

deallocate film_market_csr

select      movie_name,
            film_market_desc,
            complex_id,
            complex_name,
            screening_date,
            screens,
            country_code,
            week_number,
            film_market_no
from        #screens
order by    screening_date,
            film_market_no
          

return 0
GO
