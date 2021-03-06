/****** Object:  View [dbo].[v_cinatt_excluded_by_complex_by_accperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_excluded_by_complex_by_accperiod]
GO
/****** Object:  View [dbo].[v_cinatt_excluded_by_complex_by_accperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_excluded_by_complex_by_accperiod]
AS
select  x.finyear_end 'finyear', 
        x.benchmark_end_dec04 'accounting_period',
        tx.complex_id as complex_id,
        count (distinct ce.movie_code) as movie_count,
        convert(int,sum((ce.attendance) * (convert(numeric(6,4),x.no_days)/7.0))) 'attendance'        
from    cinema_attendance_excluded ce,
        translate_complex tx,
        film_screening_date_xref_historical x
where   ce.complex_code = tx.complex_code
and     ce.provider_id = tx.provider_id
and     ce.screening_date = x.screening_date
and     ce.include_in_reporting = 'Y'
group by x.finyear_end,
         x.benchmark_end_dec04,
         tx.complex_id
GO
