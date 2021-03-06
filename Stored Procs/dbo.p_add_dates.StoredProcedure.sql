/****** Object:  StoredProcedure [dbo].[p_add_dates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_add_dates]
GO
/****** Object:  StoredProcedure [dbo].[p_add_dates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_add_dates]

as

declare		@screening_date		datetime

declare scr_csr cursor static for 
select	screening_date 
from	film_screening_dates
where	screening_date > '1-jan-2006'
and		screening_date not in (select screening_date from revenue_calendar_week)
order by screening_date 
for	read only

open scr_csr
fetch scr_csr into @screening_date
while(@@fetch_status=0)
begin
	
	exec p_insert_revenue_calendar @screening_date

	fetch scr_csr into @screening_date
end

return 0
GO
