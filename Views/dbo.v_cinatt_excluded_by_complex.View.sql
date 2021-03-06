/****** Object:  View [dbo].[v_cinatt_excluded_by_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_excluded_by_complex]
GO
/****** Object:  View [dbo].[v_cinatt_excluded_by_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_excluded_by_complex]
AS
select  ce.screening_date as screening_date,
        tx.complex_id as complex_id,
        case when ce.provider_id <= 3 then 'A' else 'Z' end as country_code,
        count (distinct ce.movie_code) as movie_count,
        sum (ce.attendance) as attendance
from    cinema_attendance_excluded ce,
        translate_complex tx  
where   ce.complex_code = tx.complex_code
and     ce.provider_id = tx.provider_id
and     ce.include_in_reporting = 'Y'
group by ce.screening_date,
         tx.complex_id,
         ce.provider_id
GO
