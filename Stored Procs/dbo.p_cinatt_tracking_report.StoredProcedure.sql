/****** Object:  StoredProcedure [dbo].[p_cinatt_tracking_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_tracking_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_tracking_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_tracking_report] @max_pct_diff integer
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @campaign_no      integer,
        @product_desc    varchar(100),
        @branch_code     char(2),
        @rep_id          integer,
        @est_attendance  integer,
        @act_attendance  integer ,
        @pct_diff        float,
        @abs_diff        integer,
        @max_actual_date datetime

/*
 * Create Temporary Tables
 */

create table #results
(	campaign_no      integer    null,
    product_desc    varchar(100) null,
    branch_code     char(2) null,
    rep_id          integer null,
    est_attendance  integer null,
    act_attendance  integer null
)


/*
 * Declare Cursor
 */

declare campaign_csr cursor static for
select  campaign_no,
        product_desc,
        branch_code,
        rep_id
from    film_campaign
where   campaign_status = 'L'
and     attendance_analysis = 'Y'
order by campaign_no
for read only


/*
 * Loop Campaigns
 */
open campaign_csr
fetch campaign_csr into @campaign_no, @product_desc, @branch_code, @rep_id
while(@@fetch_status = 0)
begin
    select  @max_actual_date = max(screening_date) from film_cinatt_actuals where campaign_no = @campaign_no

    select  @est_attendance = sum(attendance)
    from    film_cinatt_estimates
    where   campaign_no = @campaign_no
    and     screening_date <= @max_actual_date

    select  @act_attendance = sum(attendance)
    from    film_cinatt_actuals
    where   campaign_no = @campaign_no
    and     screening_date <= @max_actual_date

    if @act_attendance < @est_attendance
    begin
        select @abs_diff = (@est_attendance - @act_attendance)
        select @pct_diff = ((@abs_diff * 1.0) / (@est_attendance * 1.0)) * 100

        if @pct_diff > @max_pct_diff
        begin
            insert into #results
            values (@campaign_no, @product_desc, @branch_code, @rep_id, @est_attendance, @act_attendance)
        end
    end

    fetch campaign_csr into @campaign_no, @product_desc, @branch_code, @rep_id
end /*while*/
close campaign_csr
deallocate campaign_csr

/*
 * Return Dataset
 */

select  campaign_no,
        product_desc   ,
        branch_code    ,
        rep_id         ,
        est_attendance ,
        act_attendance 
from    #results
order by campaign_no

/*
 * Return Success
 */

return 0
GO
