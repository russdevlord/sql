/****** Object:  StoredProcedure [dbo].[p_ipo_graph_4]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_ipo_graph_4]
GO
/****** Object:  StoredProcedure [dbo].[p_ipo_graph_4]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_ipo_graph_4]           @start_date         datetime,
                                    @end_date           datetime

as

declare        @error                   int,
               @campaign_no             int,
               @screening_date          datetime,
               @min_date                datetime,
               @max_date                datetime,
               @total_rate              money,
               @no_spots_paid           int,
               @no_spots_bonus          int,
               @campaign_attendance     int,
               @total_attendance        int,
               @follow_film             char(1)
               
set nocount on

create table #screenings
(
campaign_no             int,
min_date                datetime,
max_date                datetime,
total_rate              money,
no_spots_paid           int,
no_spots_bonus          int,
campaign_attendance     int,
total_attendance        int,
follow_film             char(1)
)


declare     screening_csr cursor forward_only for
select      distinct cs.campaign_no,
            max(cs.screening_date),
            min(cs.screening_date),
            follow_film
from        v_spots_redirected_xref cs,
		    v_certificate_item_distinct cert,
            campaign_package cp
where       cs.spot_id = cert.spot_reference
and         cs.package_id = cp.package_id
and         cs.screening_date between @start_date and @end_date
and         cs.campaign_no in (select campaign_no from film_campaign where branch_code <> 'Z')
group by    cs.campaign_no,
            follow_film

open screening_csr
fetch screening_csr into @campaign_no, @max_date, @min_date, @follow_film
while(@@fetch_status = 0)
begin

    select  @total_rate = 0,
            @no_spots_paid = 0,
            @no_spots_bonus = 0,
            @campaign_attendance = 0,
            @total_attendance = 0
               
    select  @total_rate = sum(isnull(cs.charge_rate,0)),
            @no_spots_paid = count(spot_id)
    from    v_spots_redirected_xref cs,
		    v_certificate_item_distinct cert,
            campaign_package cp          
    where   cs.spot_id = cert.spot_reference
    and     cs.package_id = cp.package_id
    and     cs.screening_date between @min_date and @max_date
    and     cp.follow_film = @follow_film
    and     cp.campaign_no = @campaign_no
    and     cs.orig_spot_type = 'S'
    
    select  @no_spots_bonus = count(spot_id)
    from    v_spots_redirected_xref cs,
		    v_certificate_item_distinct cert,
            campaign_package cp          
    where   cs.spot_id = cert.spot_reference
    and     cs.package_id = cp.package_id
    and     cs.screening_date between @min_date and @max_date
    and     cp.follow_film = @follow_film
    and     cp.campaign_no = @campaign_no
    and     cs.orig_spot_type in ('B','C','N')
    
    select  @campaign_attendance = sum(sub_campaign_attendance),
            @total_attendance = sum(awc.attendance)
    from    attendance_weekly_complex awc,
            (select mh.complex_id, 
                    mh.screening_date,
                    sub_campaign_attendance = sum(mh.attendance)
            from    v_spots_redirected_xref cs,
                    v_certificate_item_distinct cert,
                    campaign_package cp,
                    movie_history mh
            where   cs.spot_id = cert.spot_reference
            and     cs.package_id = cp.package_id
            and     cs.screening_date between @min_date and @max_date
            and     cp.follow_film = @follow_film
            and     cp.campaign_no = @campaign_no
            and		mh.certificate_group = cert.certificate_group
            and		mh.attendance <> 0
            and     mh.attendance is not null
            group by mh.complex_id, mh.screening_date) as temp_table
    where   temp_table.complex_id = awc.complex_id
    and     temp_table.screening_date = awc.screening_date   

    insert into #screenings
    values  (@campaign_no,
            @min_date,
            @max_date,
            @total_rate,
            @no_spots_paid,
            @no_spots_bonus,
            @campaign_attendance,
            @total_attendance,
            @follow_film 
            )

    fetch screening_csr into @campaign_no, @max_date, @min_date, @follow_film
end

select * from #screenings


return 0

grant all on p_ipo_graph_4 to public
GO
