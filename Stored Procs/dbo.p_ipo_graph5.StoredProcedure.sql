/****** Object:  StoredProcedure [dbo].[p_ipo_graph5]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_ipo_graph5]
GO
/****** Object:  StoredProcedure [dbo].[p_ipo_graph5]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_ipo_graph5]        @start_date         datetime,
                                @end_date           datetime
                                
as 

declare     @error                  int,
            @benchmark_end          datetime,
            @paid_attend_util       int,
            @bonus_attend_util      int,
            @total_avail_attend     int,
            @no_paid_spots          int,
            @no_bonus_spots         int,
            @revenue                money,
            @screening_date         datetime


set nocount on

create table #graph5
(
benchmark_end           datetime    null,
screening_date          datetime    null,
paid_attend_util        int         null,
bonus_attend_util       int         null,
total_avail_attend      int         null,
no_paid_spots           int         null,
no_bonus_spots          int         null,
revenue                 money       null
)                                


declare     date_csr cursor forward_only for
select      benchmark_end,
            screening_Date
from        film_screening_date_xref
where       screening_date between @start_date and @end_date
group by    benchmark_end,
            screening_date
order by    benchmark_end,
            screening_date
for         read only

open date_csr
fetch date_csr into @benchmark_end,@screening_date
while(@@fetch_status = 0)
begin

    select  @paid_attend_util = 0,
            @bonus_attend_util = 0,
            @total_avail_attend = 0,
            @no_paid_spots = 0,
            @no_bonus_spots = 0,
            @revenue = 0 


    select  @revenue = sum(isnull(cs.charge_rate,0)),
            @no_paid_spots = count(spot_id)
    from    v_spots_redirected_xref cs,
		    v_certificate_item_distinct cert,
            campaign_package cp,
            film_screening_date_xref fsdx            
    where   cs.spot_id = cert.spot_reference
    and     cs.package_id = cp.package_id
    and     fsdx.screening_date = cs.screening_date
    and     fsdx.benchmark_end = @benchmark_end
    and     fsdx.screening_date = @screening_date
    and     cs.campaign_no in (select campaign_no from film_campaign where branch_code <> 'Z')
--    and   cp.follow_film = @follow_film
    --and   cp.campaign_no = @campaign_no
    and     cs.orig_spot_type = 'S'
    
    select  @no_bonus_spots = count(spot_id)
    from    v_spots_redirected_xref cs,
		    v_certificate_item_distinct cert,
            campaign_package cp,
            film_screening_date_xref fsdx                  
    where   cs.spot_id = cert.spot_reference
    and     cs.package_id = cp.package_id
    and     fsdx.screening_date = cs.screening_date
    and     fsdx.benchmark_end = @benchmark_end
    and     fsdx.screening_date = @screening_date
    and     cs.campaign_no in (select campaign_no from film_campaign where branch_code <> 'Z')
    --and   cp.follow_film = @follow_film
    --and   cp.campaign_no = @campaign_no
    and     cs.orig_spot_type in ('B','C','N')
    
--     select  @paid_attend_util = sum(mh.attendance)
--     from    v_spots_redirected_xref cs,
--             v_certificate_item_distinct cert,
--             campaign_package cp,
--             movie_history mh,
--             film_screening_date_xref fsdx            
--     where   cs.spot_id = cert.spot_reference
--     and     cs.package_id = cp.package_id
--     and     cs.campaign_no in (select campaign_no from film_campaign where branch_code <> 'Z')
--     --and   cp.follow_film = @follow_film
--     --and   cp.campaign_no = @campaign_no
--     and		mh.certificate_group = cert.certificate_group
--     and		mh.attendance <> 0
--     and     mh.attendance is not null
--     and     fsdx.screening_date = cs.screening_date
--     and     fsdx.benchmark_end = @benchmark_end
--     and     fsdx.screening_date = @screening_date
--     and     cs.orig_spot_type = 'S'

    select  @paid_attend_util = isnull(sum(sub_campaign_attendance),0),
            @total_avail_attend = isnull(sum(awc.attendance),0)
    from    attendance_weekly_complex awc,
            (select     mh.complex_id, 
                        mh.screening_date,
                        sub_campaign_attendance = sum(mh.attendance),
                        cs.campaign_no
            from        v_spots_redirected_xref cs,
                        v_certificate_item_distinct cert,
                        campaign_package cp,
                        movie_history mh,
                        film_screening_date_xref fsdx            
            where       cs.spot_id = cert.spot_reference
            and         cs.package_id = cp.package_id
            and         cs.campaign_no in (select campaign_no from film_campaign where branch_code <> 'Z')
            --and       cp.follow_film = @follow_film
            --and       cp.campaign_no = @campaign_no
            and		    mh.certificate_group = cert.certificate_group
            and		    mh.attendance <> 0
            and         mh.attendance is not null
            and         fsdx.screening_date = cs.screening_date
            and         fsdx.benchmark_end = @benchmark_end
            and         fsdx.screening_date = @screening_date
            and         cs.orig_spot_type = 'S'
            group by    mh.complex_id, 
                        mh.screening_date,
                        cs.campaign_no) as temp_table
    where   temp_table.complex_id = awc.complex_id
    and     temp_table.screening_date = awc.screening_date   
    
    select  @bonus_attend_util = sum(sub_campaign_attendance),
            @total_avail_attend = @total_avail_attend  + isnull(sum(awc.attendance),0)
    from    attendance_weekly_complex awc,
            (select     mh.complex_id, 
                        mh.screening_date,
                        sub_campaign_attendance = sum(mh.attendance),
                        cs.campaign_no
            from        v_spots_redirected_xref cs,
                        v_certificate_item_distinct cert,
                        campaign_package cp,
                        movie_history mh,
                        film_screening_date_xref fsdx            
            where       cs.spot_id = cert.spot_reference
            and         cs.package_id = cp.package_id
            --and       cp.follow_film = @follow_film
            and         cs.campaign_no in (select campaign_no from film_campaign where branch_code <> 'Z')
            --and       cp.campaign_no = @campaign_no
            and		    mh.certificate_group = cert.certificate_group
            and		    mh.attendance <> 0
            and         mh.attendance is not null
            and         fsdx.screening_date = cs.screening_date
            and         fsdx.benchmark_end = @benchmark_end
            and         fsdx.screening_date = @screening_date
            and         cs.orig_spot_type  in ('B','C','N')
            group by    mh.complex_id, 
                        mh.screening_date,
                        cs.campaign_no) as temp_table
    where   temp_table.complex_id = awc.complex_id
    and     temp_table.screening_date = awc.screening_date   


    insert into #graph5
    values
    (
    @benchmark_end,
    @screening_date,
    @paid_attend_util,
    @bonus_attend_util,
    @total_avail_attend,
    @no_paid_spots,
    @no_bonus_spots,
    @revenue
    )


    fetch date_csr into @benchmark_end, @screening_date
end


select * from #graph5
return 0
GO
