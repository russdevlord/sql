/****** Object:  View [dbo].[v_cinatt_raw_by_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_raw_by_complex]
GO
/****** Object:  View [dbo].[v_cinatt_raw_by_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_raw_by_complex]
AS

select  cinema_attendance.country,
        translate_complex.provider_id,
        cinema_attendance.screening_date,
        translate_complex.complex_code,
        translate_complex.complex_name,
        sum(cinema_attendance.attendance) 'raw_attendance_matched',
            (select isnull(sum(cae.attendance),0)
            from    cinema_attendance_excluded cae
            where   cae.complex_code = translate_complex.complex_code
            and     cae.provider_id = translate_complex.provider_id
            and     cae.include_in_reporting = 'Y'
            and     cae.screening_date = cinema_attendance.screening_date) 'raw_attendance_excluded'
from     cinema_attendance, translate_complex
where    cinema_attendance.complex_id = translate_complex.complex_id
and      cinema_attendance.provider_id = translate_complex.provider_id
group by cinema_attendance.country,
         translate_complex.provider_id,
         cinema_attendance.screening_date,
         translate_complex.complex_code,
         translate_complex.complex_name
GO
