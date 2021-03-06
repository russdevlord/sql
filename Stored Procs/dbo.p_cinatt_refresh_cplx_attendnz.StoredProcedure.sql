/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_cplx_attendnz]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_refresh_cplx_attendnz]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_cplx_attendnz]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_refresh_cplx_attendnz]
as

set nocount on 

declare @error        			integer,
        @rowcount     			integer,
       -- @error                     tinyint,
        @provider_count         tinyint,
        @required_providers     tinyint,
        @max_warehouse_date     datetime,
        @max_attendance_date    datetime,
        @forecast_years         tinyint,
        @current_screening_date datetime


select @forecast_years = 3

select  @required_providers = count(provider_id)
from    external_data_providers
where   status = 'A'

 declare maxdate_csr cursor static for
 select  screening_date
   from  cinema_attendance
group by screening_date
  having count(distinct provider_id) = @required_providers
order by screening_date DESC
     for read only

open maxdate_csr
fetch maxdate_csr into @max_attendance_date
close maxdate_csr
deallocate  maxdate_csr

select  @max_warehouse_date = max(screening_date)
from    cinema_attendance_by_complex
where   actual = 1



select @max_warehouse_date = '1-jan-2002'
select @max_attendance_date = '21-aug-2004'


if @max_attendance_date > @max_warehouse_date
begin
	declare date_csr cursor static for
	select  screening_date
	from    film_screening_dates
	where   screening_date > @max_warehouse_date
	and     screening_date <= @max_attendance_date
	for read only

    open date_csr
    fetch date_csr into @current_screening_date
    while(@@fetch_status = 0)
    begin
        exec @error = p_cinatt_pop_cplx_attendnz @current_screening_date, @forecast_years

        fetch date_csr into @current_screening_date
    end 
    close date_csr
    deallocate  date_csr
end

return 0
GO
