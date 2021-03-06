/****** Object:  StoredProcedure [dbo].[p_mktg_top5_movies]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mktg_top5_movies]
GO
/****** Object:  StoredProcedure [dbo].[p_mktg_top5_movies]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_mktg_top5_movies]  @start_date         datetime,
                                @end_date           datetime,
                                @country_code       char(1),
                                @advertising_open   char(1)
                                
as

declare     @error                      int,
            @screening_date             datetime,
            @top5_attendance_all        int,
            @total_attendance_all       int,
            @top5_prints_all            int,
            @total_prints_all           int,
            @top5_attendance_paid       int,
            @total_attendance_paid      int,
            @top5_prints_paid           int,
            @total_prints_paid          int,
            @top5_revenue               money,
            @total_revenue              money

set nocount on 

create table #top5
(
screening_date         datetime,
top5_attendance_all    int,
total_attendance_all   int,
top5_prints_all        int,
total_prints_all       int,
top5_attendance_paid   int,
total_attendance_paid  int,
top5_prints_paid       int,
total_prints_paid      int,
top5_revenue           money,
total_revenue          money
)

create table #top5_movies_week
(
movie_id                int,
no_prints               int,
sum_attendance          int
)

declare     movie_csr cursor forward_only for
select      distinct screening_date
from        movie_history
where       country = @country_code
and         screening_date between @start_date and @end_date
group by    screening_date
order by    screening_date


open movie_csr
fetch movie_csr into @screening_date
while(@@fetch_status=0)
begin

    select      @total_revenue = sum(charge_rate)
    from	    movie_history,
                v_certificate_item_distinct,
                v_spots_redirected_xref
    where		v_spots_redirected_xref.spot_id = v_certificate_item_distinct.spot_reference
    and			v_certificate_item_distinct.certificate_group = movie_history.certificate_group
    and         movie_history.screening_date = @screening_date
    and         movie_history.country = @country_code
    and         ((movie_history.advertising_open = @advertising_open
    and         @advertising_open <> 'A')
    or          (@advertising_open = 'A'))
    
    select      @total_prints_all = count(movie_id),
                @total_attendance_all = sum(isnull(attendance,0))
    from	    movie_history
    where		movie_history.screening_date = @screening_date
    and         movie_history.country = @country_code
    and         ((movie_history.advertising_open = @advertising_open
    and         @advertising_open <> 'A')
    or          (@advertising_open = 'A'))
    
    select      @total_prints_paid = count(movie_id),
                @total_attendance_paid = sum(isnull(attendance,0))
    from	    movie_history
    where		movie_history.screening_date = @screening_date
    and         movie_history.country = @country_code
    and         ((movie_history.advertising_open = @advertising_open
    and         @advertising_open <> 'A')
    or          (@advertising_open = 'A'))
    and         certificate_group in (  select  certificate_group 
                                        from    v_certificate_item_distinct,
                                                v_spots_redirected_xref
                                        where	v_spots_redirected_xref.spot_id = v_certificate_item_distinct.spot_reference
                                        and     orig_spot_type = 'S'    )

    delete #top5_movies_week
    
    insert into #top5_movies_week
    select      top 5  movie_id,
                count(movie_id),
                sum(isnull(attendance,0)) as sum_attendance
    from	    movie_history
    where		movie_history.screening_date = @screening_date
    and         movie_history.country = @country_code
    and         ((movie_history.advertising_open = @advertising_open
    and         @advertising_open <> 'A')
    or          (@advertising_open = 'A'))
    group by    movie_id
    order by    sum_attendance desc
    
    select      @top5_revenue = sum(charge_rate)
    from	    movie_history,
                v_certificate_item_distinct,
                campaign_spot,
                #top5_movies_week
    where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
    and			v_certificate_item_distinct.certificate_group = movie_history.certificate_group
    and         movie_history.screening_date = @screening_date
    and         movie_history.country = @country_code
    and         movie_history.movie_id = #top5_movies_week.movie_id
    and         ((movie_history.advertising_open = @advertising_open
    and         @advertising_open <> 'A')
    or          (@advertising_open = 'A'))
    
    select      @top5_attendance_all = sum(sum_Attendance),
                @top5_prints_all = sum(no_prints)
    from        #top5_movies_week
    
    delete #top5_movies_week
    
    insert into #top5_movies_week
    select      top 5  movie_id,
                count(movie_id),
                sum(isnull(attendance,0)) as sum_attendance
    from	    movie_history
    where		movie_history.screening_date = @screening_date
    and         movie_history.country = @country_code
    and         ((movie_history.advertising_open = @advertising_open
    and         @advertising_open <> 'A')
    or          (@advertising_open = 'A'))
    and         certificate_group in (  select  certificate_group 
                                        from    v_certificate_item_distinct,
                                                v_spots_redirected_xref
                                        where	v_spots_redirected_xref.spot_id = v_certificate_item_distinct.spot_reference
                                        and     orig_spot_type = 'S'    )
    
    group by    movie_id
    order by    sum_attendance desc
    
    select      @top5_attendance_paid = sum(sum_Attendance),
                @top5_prints_paid = sum(no_prints)
    from        #top5_movies_week
    
    
    insert into #top5
    values
    (
    @screening_date,
    @top5_attendance_all,
    @total_attendance_all,
    @top5_prints_all,
    @total_prints_all,
    @top5_attendance_paid,
    @total_attendance_paid,
    @top5_prints_paid,
    @total_prints_paid,
    @top5_revenue,
    @total_revenue
    )

    fetch movie_csr into @screening_date
end

select * from #top5

return 0
GO
