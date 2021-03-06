/****** Object:  View [dbo].[v_dw_fact_complex_cinatt_by_acctperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dw_fact_complex_cinatt_by_acctperiod]
GO
/****** Object:  View [dbo].[v_dw_fact_complex_cinatt_by_acctperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_dw_fact_complex_cinatt_by_acctperiod]
AS
select  x.finyear_end 'finyear', 
        x.benchmark_end_dec04 'accounting_period',
        complex.complex_id 'complex_id',
        convert(int,sum((v_cinatt.prints * v_cinatt.attendance_per_print) * (convert(numeric(6,4),x.no_days)/7.0))) 'matched_attendance',
        convert(int,sum((v_cinatt.attendance_per_movie) * (convert(numeric(6,4),x.no_days)/7.0))) 'raw_attendance'        
from    v_cinatt, complex, film_screening_date_xref_historical x
where   v_cinatt.complex_id = complex.complex_id
and     v_cinatt.screening_date = x.screening_date
group by x.finyear_end,
         x.benchmark_end_dec04,
         complex.complex_id
GO
