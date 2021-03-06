/****** Object:  StoredProcedure [dbo].[p_cinatt_get_movie_test]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_get_movie_test]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_get_movie_test]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_get_movie_test]   @screening_date datetime,
                                            @complex_id     integer,
                                            @movie_id       integer,
                                            @attendance     integer OUTPUT,
                                            @actual         char(1) OUTPUT

as

declare @temp_attendance    integer,
        @error                 integer,
        @regional_indicator char(1)

select  @temp_attendance = cinema_attendance.attendance / ( select count(occurence) from movie_history
                                                            where complex_id = @complex_id
                                                            and movie_id = @movie_id
                                                            and screening_date = @screening_date)
from    cinema_attendance
where   cinema_attendance.complex_id = @complex_id
and     cinema_attendance.movie_id = @movie_id
and     cinema_attendance.screening_date = @screening_date
and     cinema_attendance.complex_id in (select complex_id from movie_history
                                         where complex_id = @complex_id and movie_id = @movie_id and screening_date = @screening_date )
select @error = 0
select @actual = 'Y'

select @temp_attendance, 'REAL'

if @@rowcount = 0 OR @temp_attendance is null
begin
    /* try and get the movie average */
    select @actual = 'N'

    select  @regional_indicator = complex_region_class.regional_indicator
    from    complex, complex_region_class
    where   complex.complex_id = @complex_id
    and     complex.complex_region_class = complex_region_class.complex_region_class

    exec @error = p_cinatt_get_avg_movie   @screening_date , @movie_id ,@regional_indicator, @temp_attendance OUTPUT
    select @temp_attendance, 'p_cinatt_get_avg_movie'
    if @error = -1 /*no data found*/
    begin
        exec @error = p_cinatt_get_avg_region   @screening_date , @regional_indicator, @temp_attendance OUTPUT
        select @temp_attendance, 'p_cinatt_get_avg_region'
    end
end

select @attendance =  @temp_attendance
select @attendance
return @error
GO
