/****** Object:  View [dbo].[v_dw_fact_complex_cinatt]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dw_fact_complex_cinatt]
GO
/****** Object:  View [dbo].[v_dw_fact_complex_cinatt]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_dw_fact_complex_cinatt]
AS
select  branch.country_code 'country_code',
        branch.branch_code 'branch_code',
        ex.exhibitor_id 'exhibitor_id',
        ex.exhibitor_name 'exhibitor_name',
        v_cinatt.screening_date 'screening_date',
        complex.complex_id 'complex_id',
        complex.complex_name 'complex_name',
        crc.region_class_desc 'complex_region_class',
        case when crc.regional_indicator = 'Y' then 'Regional' else 'Metro' end 'regional_indicator',
        film_market.film_market_no 'film_market_no',
        film_market.film_market_desc 'film_market_desc',
        sum(v_cinatt.attendance_per_movie) 'raw_attendance',
        sum(v_cinatt.prints * v_cinatt.attendance_per_print) 'matched_attendance',
        (select isnull(sum(isnull(attendance,0)),0)
         from  v_cinatt_excluded_by_complex 
         where screening_date = v_cinatt.screening_date
         and   complex_id = complex.complex_id) 'excluded_attendance'
from    v_cinatt, complex, film_market, branch, exhibitor ex, complex_region_class crc
where   ex.exhibitor_id = complex.exhibitor_id
and     complex.complex_region_class = crc.complex_region_class
and     v_cinatt.complex_id = complex.complex_id
and     complex.film_market_no = film_market.film_market_no
and     complex.branch_code = branch.branch_code
group by branch.country_code,
         branch.branch_code,
         ex.exhibitor_id,
         ex.exhibitor_name,
         v_cinatt.screening_date,
         complex.complex_id,
         complex.complex_name,
         crc.region_class_desc,
         crc.regional_indicator,
         film_market.film_market_no,
         film_market.film_market_desc
GO
