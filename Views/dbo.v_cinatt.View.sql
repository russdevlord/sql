/****** Object:  View [dbo].[v_cinatt]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt]
GO
/****** Object:  View [dbo].[v_cinatt]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_cinatt]
AS

    select  movie_id 'movie_id',
            complex_id 'complex_id',            
            screening_date 'screening_date',
            attendance 'attendance_per_movie',
            ( select count(occurence) from movie_history
              where complex_id = cinema_attendance.complex_id
              and movie_id = cinema_attendance.movie_id
              and screening_date = cinema_attendance.screening_date ) 'prints' ,    
            (select case count(occurence) when 0 then 0 else cinema_attendance.attendance / count(occurence) end from movie_history
             where complex_id = cinema_attendance.complex_id
             and movie_id = cinema_attendance.movie_id
             and screening_date = cinema_attendance.screening_date) 'attendance_per_print' ,
            country 'country_code'
    from    cinema_attendance where movie_id <> 102
GO
