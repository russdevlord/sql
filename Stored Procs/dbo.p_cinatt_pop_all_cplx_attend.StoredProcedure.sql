/****** Object:  StoredProcedure [dbo].[p_cinatt_pop_all_cplx_attend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_pop_all_cplx_attend]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_pop_all_cplx_attend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_pop_all_cplx_attend] @screening_date datetime,
                                         @country_code  char(1)
as

declare @error        			integer,
        @rowcount     			integer,
        @complex_id             integer,
        @attendance             integer,
        @actual_attendance      integer,
        @movie_id               integer,
        @errorode                  tinyint,
        @actual                 char(1),
        @cinatt_weighting       numeric(6,4)



declare complex_movie_csr cursor static for
select  distinct    movie_history.complex_id,
                    movie_history.movie_id,
                    complex.cinatt_weighting
from    movie_history, complex
where   movie_history.complex_id = complex.complex_id
and     movie_history.screening_date = @screening_date
and     movie_history.country = @country_code
order by movie_history.complex_id, movie_history.movie_id
for read only

begin transaction

    open complex_movie_csr
    fetch complex_movie_csr into @complex_id,@movie_id, @cinatt_weighting
    while(@@fetch_status = 0)
    begin
       
       	select  @attendance = 0,
                @actual_attendance = 0

    	exec @errorode = p_cinatt_get_movie_attendance    @screening_date,
													   @complex_id,
        											   @movie_id,
        											   @attendance OUTPUT,
        											   @actual OUTPUT

        select @actual_attendance = @actual_attendance + convert(int,(@attendance * @cinatt_weighting))

        delete  cinatt_by_movie_history
        where   screening_date = @screening_date
        and     complex_id = @complex_id
        and     movie_id = @movie_id
        if @@error <> 0
            goto error
            
        insert into cinatt_by_movie_history
                    (complex_id      ,
                     movie_id       ,
                     screening_date  ,
                     total_attendance,
                     actual          )
            select  @complex_id,
                    @movie_id,
                    @screening_date,
                    @actual_attendance,
                    @actual
        if @@error <> 0
            goto error

        fetch complex_movie_csr into @complex_id,@movie_id, @cinatt_weighting
    end 

    deallocate complex_movie_csr

commit transaction

return 0

error:
rollback transaction
deallocate complex_movie_csr
return -1
GO
