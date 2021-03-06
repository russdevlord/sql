/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_cplx_attend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_refresh_cplx_attend]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_cplx_attend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_refresh_cplx_attend]    @country_code char(1)
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
       -- @error                     tinyint,
        @provider_count         tinyint,
        @required_providers     tinyint,
        @max_warehouse_date     datetime,
        @max_attendance_date    datetime,
        @forecast_years         tinyint,
        @current_screening_date datetime


/* this cursor lists all screening dates that have valid data loaded that are not in the cinema_attendance_by_complex table */
declare date_csr cursor static for
/*select  distinct eds.required_load_date
from    external_data_load_status eds, external_data_providers edp
where   eds.provider_id = edp.provider_id
and     edp.country_code = @country_code
and     eds.required_load_date not in (
                                        select  distinct eds.required_load_date
                                        from    external_data_load_status eds, external_data_providers edp
                                        where   eds.provider_id = edp.provider_id
                                        and     edp.country_code = @country_code
                                        and     eds.load_complete = 'N')
and     eds.required_load_date not in (
                                        select  distinct cac.screening_date
                                        from    cinema_attendance_by_complex cac, translate_complex tc, external_data_providers edp
                                        where   cac.complex_id = tc.complex_id
                                        and     tc.provider_id = edp.provider_id
                                        and     edp.country_code = @country_code
                                        and     cac.actual = 1)
order by eds.required_load_date */
select screening_date from film_screening_dates where screening_date >= '1-jul-2004' and screening_date <= '30-jun-2005'
order by screening_date
for read only

/* forecast 3 years into future */
select @forecast_years = 3

open date_csr
fetch date_csr into @current_screening_date
while(@@fetch_status = 0)
begin
    exec @error = p_cinatt_pop_cplx_attend @current_screening_date, @forecast_years, @country_code

    fetch date_csr into @current_screening_date
end /*while*/
close date_csr
deallocate date_csr

return 0
GO
