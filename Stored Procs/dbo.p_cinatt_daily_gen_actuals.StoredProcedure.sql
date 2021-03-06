/****** Object:  StoredProcedure [dbo].[p_cinatt_daily_gen_actuals]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_daily_gen_actuals]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_daily_gen_actuals]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_daily_gen_actuals]
as

/* This proc is run automatically every day from a batch process on server */

/*
 * Declare Variables
 */

declare @ret            integer,
        @campaign_no      integer

/*
 * Declare Cursor
 */

declare campaign_csr cursor static for
select  campaign_no
from    film_campaign
where   campaign_status = 'L'
and     attendance_analysis = 'Y'
order by campaign_no
for read only

/*
 * Loop Campaigns
 */
open campaign_csr
fetch campaign_csr into @campaign_no

while(@@fetch_status = 0)
begin

    exec @ret = p_cinatt_pop_film_actuals @campaign_no

    fetch campaign_csr into @campaign_no
end /*while*/
close campaign_csr
deallocate campaign_csr

/* Temporary run attendance by complex refresh proc here as well */
exec @ret = p_cinatt_refresh_cplx_attend 'A'
exec @ret = p_cinatt_refresh_cplx_attend 'Z'
/* refresh list of provider data that must be loaded - becomes required 8 days after last screening date */
exec p_cinatt_refresh_load_status

return 0
GO
