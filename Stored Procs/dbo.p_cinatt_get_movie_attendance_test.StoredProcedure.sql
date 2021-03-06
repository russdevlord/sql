/****** Object:  StoredProcedure [dbo].[p_cinatt_get_movie_attendance_test]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_get_movie_attendance_test]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_get_movie_attendance_test]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_get_movie_attendance_test]   @screening_date datetime,
                                            @complex_id     integer,
                                            @movie_id       integer,
                                            @attendance     integer OUTPUT,
                                            @actual         char(1) OUTPUT

as

declare @temp_attendance    integer,
        @error                 integer,
        @regional_indicator char(1),
        @country_code       char(1),
        @provider_id        integer,
        @data_load_status    char(1)

select  @error = 0
select  @actual = 'Y'
select  @temp_attendance = null

select  @country_code = branch.country_code
from    complex, branch
where   complex.complex_id = @complex_id
and     complex.branch_code = branch.branch_code

select  @provider_id = provider_id
from    translate_complex
where   complex_id = @complex_id

if @@rowcount = 0 or @provider_id is null
begin /* we don't collect data for this complex */
    select @data_load_status = 'Y'
end
else
begin
    /* check to see if the data has been loaded for this data and provider */
    select  @data_load_status = isnull(load_complete,'N')
    from    external_data_load_status
    where   external_data_type_id = 1
    and     provider_id = @provider_id
    and     required_load_date = @screening_date
    
    if @@rowcount = 0
        select @data_load_status = 'N'
    
    if @data_load_status = 'N'
        return -1
end

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

if @@rowcount = 0 OR @temp_attendance is null
begin
    /* make sure that all the providers have had data loaded for this country and date */
    if exists ( select 1 from external_data_load_status eds, external_data_providers edp
                where   edp.provider_id = eds.provider_id
                and     eds.external_data_type_id = 1
                and     eds.required_load_date = @screening_date
                and     edp.country_code = @country_code
                and     eds.load_complete = 'N')
    return -1   /* not all data available so cannot rely on average calculations.*/
                /* no need to check for 0 rows becasue this would have been caught earlier when complex checked for data */


    /* try and get the movie average */
    select @actual = 'N'

    select  @regional_indicator = complex_region_class.regional_indicator
    from    complex, complex_region_class
    where   complex.complex_id = @complex_id
    and     complex.complex_region_class = complex_region_class.complex_region_class

    exec @error = p_cinatt_get_avg_movie   @screening_date , @movie_id ,@country_code, @regional_indicator, @temp_attendance OUTPUT
    select @actual = 'M'
    if @error = -1 /*no data found*/
    begin
        exec @error = p_cinatt_get_avg_region   @screening_date , @country_code, @regional_indicator, @temp_attendance OUTPUT
        select @actual = 'R'
        if @error = -1 /* no attendance data at all */
        begin
            select @temp_attendance = 0
            select @error = -1
            if @country_code = 'Z'
                select @actual = 'M'
        end
    end
end

select @attendance =  isnull(@temp_attendance,0)

return @error
GO
