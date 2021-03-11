USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_all_cplx]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_refresh_all_cplx]    @country_code char(1)
as



declare @error        			integer,
        @rowcount     			integer,
       -- @error                     tinyint,
        @current_screening_date datetime

declare date_csr cursor static for
select  distinct screening_date
from    movie_history
where   screening_date > '1-jan-2003'
and     screening_date < '31-dec-2003'
order by screening_date
for read only

open date_csr
fetch date_csr into @current_screening_date
while(@@fetch_status = 0)
begin
    exec @error = p_cinatt_pop_all_cplx_attend @current_screening_date, @country_code
    fetch date_csr into @current_screening_date
end 
close date_csr
deallocate date_csr

return 0
GO
