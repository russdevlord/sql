/****** Object:  StoredProcedure [dbo].[p_cinatt_get_avg_region]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_get_avg_region]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_get_avg_region]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_get_avg_region]   @screening_date datetime,
                                      @country_code char(1),
                                      @regional_indicator  char(1),
                                      @attendance     integer OUTPUT

as

-- if @country_code = 'Z' -- special case for NZ, taking the average of all complexes
--     select @attendance = sum(cinema_attendance.attendance / (select count(occurence) from movie_history
--                                                              where complex_id = complex.complex_id
--                                                              and movie_id = cinema_attendance.movie_id
--                                                              and screening_date = @screening_date) ) / count(complex.complex_id)
--     from    complex,
--             cinema_attendance,
--             branch
--     where   branch.branch_code = complex.branch_code
--     and     branch.country_code = @country_code
--     and     cinema_attendance.complex_id = complex.complex_id
--     and     cinema_attendance.screening_date = @screening_date
--     and     complex.complex_id in (select complex_id from movie_history
--                                    where complex_id = complex.complex_id
--                                    and  movie_id = cinema_attendance.movie_id
--                                    and screening_date = @screening_date )
-- else
--     select @attendance = sum(cinema_attendance.attendance / (select count(occurence) from movie_history
--                                                              where complex_id = complex.complex_id
--                                                              and movie_id = cinema_attendance.movie_id
--                                                              and screening_date = @screening_date) ) / count(complex.complex_id)
--     from    complex,
--             complex_region_class,
--             cinema_attendance,
--             branch
--     where   branch.branch_code = complex.branch_code
--     and     branch.country_code = @country_code
--     and     complex.complex_region_class = complex_region_class.complex_region_class
--     and     complex_region_class.regional_indicator = @regional_indicator
--     and     cinema_attendance.complex_id = complex.complex_id
--     and     cinema_attendance.screening_date = @screening_date
--     and     complex.complex_id in (select complex_id from movie_history
--                                    where complex_id = complex.complex_id
--                                    and  movie_id = cinema_attendance.movie_id
--                                    and screening_date = @screening_date )


if @country_code = 'Z' -- special case for NZ, taking the average of all complexes
begin
   select  @attendance = sum(temp_table.attendance / temp_table.occurence) / count(temp_table.count_complex)
   from    (select      complex.complex_id as complex_id,
                        cinema_attendance.attendance as attendance,
                        cinema_attendance.movie_id as movie,
                        count(complex.complex_id) as count_complex,
                        (select count(occurence) from movie_history
                        where   complex_id = complex.complex_id
                        and     movie_id = cinema_attendance.movie_id
                        and     screening_date = @screening_date) as occurence
            from        complex,
                        cinema_attendance,
                        branch
            where       branch.branch_code = complex.branch_code
            and         branch.country_code = @country_code
            and         cinema_attendance.complex_id = complex.complex_id
            and         cinema_attendance.screening_date = @screening_date
            and         complex.complex_id in   (select complex_id 
                                                from    movie_history
                                                where   complex_id = complex.complex_id
                                                and     movie_id = cinema_attendance.movie_id
                                                and     screening_date = @screening_date )
            group by    complex.complex_id,
                        cinema_attendance.attendance,
                        cinema_attendance.movie_id ) as temp_table
end
else
begin
    select  @attendance = sum (temp_table.attendance / temp_table.occurence) / count(temp_table.count_complex)
    from    (select     complex.complex_id as complex_id,
                        cinema_attendance.attendance as attendance,
                        cinema_attendance.movie_id as movie,
                        count(complex.complex_id) as count_complex,
                        (select count(occurence) from movie_history
                        where   complex_id = complex.complex_id
                        and     movie_id = cinema_attendance.movie_id
                        and     screening_date = @screening_date) as occurence
            from        complex,
                        complex_region_class,
                        cinema_attendance,
                        branch
            where       branch.branch_code = complex.branch_code
            and         branch.country_code = @country_code
            and         complex.complex_region_class = complex_region_class.complex_region_class
            and         complex_region_class.regional_indicator = @regional_indicator
            and         cinema_attendance.complex_id = complex.complex_id
            and         cinema_attendance.screening_date = @screening_date
            and         complex.complex_id in   (select complex_id 
                                                from    movie_history
                                                where   complex_id = complex.complex_id
                                                and     movie_id = cinema_attendance.movie_id
                                                and     screening_date = @screening_date )
            group by    complex.complex_id,
                        cinema_attendance.attendance,
                        cinema_attendance.movie_id) as temp_table
end

if @@rowcount = 0 or @attendance is null
return -1
else
return 0
GO
