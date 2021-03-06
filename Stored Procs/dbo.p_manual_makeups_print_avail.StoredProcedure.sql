/****** Object:  StoredProcedure [dbo].[p_manual_makeups_print_avail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_manual_makeups_print_avail]
GO
/****** Object:  StoredProcedure [dbo].[p_manual_makeups_print_avail]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_manual_makeups_print_avail]        @campaign_no        int,
                                                @package_id         int,
                                                @complex_id         int,
                                                @screening_date     datetime,
                                                @mode               char(1)
                                                
                                                
as

set nocount on

declare     @complex_35mm_qty       int,
            @complex_2d_qty         int,
            @complex_3d_qty         int,
            @used_35mm_qty          int,
            @used_2d_qty            int,
            @used_3d_qty            int,
            @print_package_id       int,
            @print_id               int, 
            @generated              char(1),
            @print_medium           char(1),
            @three_d_type           int
            
                                              

create table #prints_avail
(
    campaign_no             int             not null,
    start_date              datetime        not null,
    package_id              int             not null,
    used_by_date            datetime        not null,     
    screening_trailers      char(1)         not null,
    print_id                int             not null,
    shell_section           int             not null,
    print_sequence          int             not null,
    print_spacing           int             not null,
    print_package_id        int             not null,
    print_status            char(1)         not null,
    key_ref                 varchar(30)      null,
    actual_duration         int             not null,
    print_name              varchar(50)     not null,
    complex_35mm_qty        int             null,
    complex_2d_qty          int             null,
    complex_3d_qty          int             null,
    used_35mm_qty           int             null,
    used_2d_qty             int             null,
    used_3d_qty             int             null,
    print_medium            char(1)         null,
    three_d_type            int             null
)

if @mode = 'S'
    insert into #prints_avail
    (
    campaign_no,
    start_date,
    package_id,
    used_by_date,     
    screening_trailers,
    print_id,
    shell_section,
    print_sequence,
    print_spacing,
    print_package_id,
    print_status,
    key_ref,
    actual_duration,
    print_name)
    select      film_campaign.campaign_no,
                film_campaign.start_date,
                campaign_package.package_id,
                campaign_package.used_by_date,     
                campaign_package.screening_trailers,
                print_package.print_id,
                print_package.shell_section,
                print_package.print_sequence,
                print_package.print_spacing,
                print_package.print_package_id,
                film_print.print_status,
                film_print.key_ref,
                film_print.actual_duration,
                film_print.print_name
    from        campaign_package,
                print_package,
                film_print,
                film_campaign
    where       campaign_package.campaign_no = film_campaign.campaign_no 
    and         campaign_package.package_id = print_package.package_id 
    and         print_package.print_id = film_print.print_id 
    and         campaign_package.package_id = @package_id 
    group by    film_campaign.campaign_no,
                film_campaign.start_date,
                campaign_package.package_id,
                campaign_package.used_by_date,     
                campaign_package.screening_trailers,
                print_package.print_id,
                print_package.shell_section,
                print_package.print_sequence,
                print_package.print_spacing,
                print_package.print_package_id,
                film_print.print_status,
                film_print.key_ref,
                film_print.actual_duration,
                film_print.print_name
    order by    film_campaign.campaign_no ASC,
                print_package.print_id ASC
else
    insert into #prints_avail
    (
    campaign_no,
    start_date,
    package_id,
    used_by_date,     
    screening_trailers,
    print_id,
    shell_section,
    print_sequence,
    print_spacing,
    print_package_id,
    print_status,
    key_ref,
    actual_duration,
    print_name,
    print_medium,
    three_d_type)
    select      film_campaign.campaign_no,
                film_campaign.start_date,
                campaign_package.package_id,
                campaign_package.used_by_date,     
                campaign_package.screening_trailers,
                print_package.print_id,
                print_package.shell_section,
                print_package.print_sequence,
                print_package.print_spacing,
                print_package.print_package_id,
                film_print.print_status,
                film_print.key_ref,
                film_print.actual_duration,
                film_print.print_name,
                print_package_medium.print_medium,
                print_package_three_d.three_d_type
    from        campaign_package,
                print_package,
                film_print,
                film_campaign,
                print_package_medium,
                print_package_three_d
    where       campaign_package.campaign_no = film_campaign.campaign_no 
    and         campaign_package.package_id = print_package.package_id 
    and         print_package.print_id = film_print.print_id 
    and         campaign_package.package_id = @package_id 
    and         print_package.print_package_id = print_package_medium.print_package_id
    and         print_package.print_package_id = print_package_three_d.print_package_id
    group by    film_campaign.campaign_no,
                film_campaign.start_date,
                campaign_package.package_id,
                campaign_package.used_by_date,     
                campaign_package.screening_trailers,
                print_package.print_id,
                print_package.shell_section,
                print_package.print_sequence,
                print_package.print_spacing,
                print_package.print_package_id,
                film_print.print_status,
                film_print.key_ref,
                film_print.actual_duration,
                film_print.print_name,
                print_package_medium.print_medium,
                print_package_three_d.three_d_type
    order by    film_campaign.campaign_no ASC,
                print_package.print_id ASC

            
select      @generated = certificate_status
from        complex_date
where       complex_id = @complex_id
and         screening_date = @screening_date    
            
declare     prints_csr cursor forward_only for
select      print_package_id,
            print_id,
            print_medium,
            three_d_type
from        #prints_avail
where       print_medium is not null
and         three_d_type is not null
group by    print_package_id,
            print_id,
            campaign_no,
            print_medium,
            three_d_type
union
select      print_package_id,
            print_id,
            null,
            null
from        #prints_avail
where       print_medium is null
and         three_d_type is null
group by    print_package_id,
            print_id,
            campaign_no
order by    print_package_id,
            print_id

open prints_csr
fetch prints_csr into @print_package_id, @print_id, @print_medium, @three_d_type
while(@@fetch_status=0)
begin

    --complex_35mm_qty         
    select  @complex_35mm_qty = isnull(sum(cinema_qty),0)
    from 	print_transactions,
            print_package_medium,
            print_package_three_d
    where 	complex_id = @complex_id 
    and		ptran_status = 'C'
    and		campaign_no = @campaign_no
    and		print_transactions.print_id = @print_id
    and		@print_package_id = print_package_medium.print_package_id
    and		@print_package_id = print_package_three_d.print_package_id
    and		print_transactions.print_medium = print_package_medium.print_medium
    and		print_transactions.three_d_type = print_package_three_d.three_d_type
    and		print_transactions.print_medium = 'F'
    and		print_transactions.three_d_type = 1
    and     (print_transactions.print_medium = @print_medium
    or      @print_medium is null)
    and     (print_transactions.three_d_type = @three_d_type
    or      @three_d_type is null)
    
    --complex_2d_qty
    select 	@complex_2d_qty = isnull(sum(cinema_qty),0)
    from 	print_transactions,
            print_package_medium,
            print_package_three_d
    where 	complex_id = @complex_id 
    and		ptran_status = 'C'
    and		campaign_no = @campaign_no
    and		print_transactions.print_id = @print_id
    and		@print_package_id = print_package_medium.print_package_id
    and		@print_package_id = print_package_three_d.print_package_id
    and		print_transactions.print_medium = print_package_medium.print_medium
    and		print_transactions.three_d_type = print_package_three_d.three_d_type
    and		print_transactions.print_medium = 'D'
    and		print_transactions.three_d_type = 1
    and     (print_transactions.print_medium = @print_medium
    or      @print_medium is null)
    and     (print_transactions.three_d_type = @three_d_type
    or      @three_d_type is null)

    --complex_3d_qty        
    select  @complex_3d_qty = isnull(sum(cinema_qty),0)
    from    print_transactions,
            print_package_medium,
            print_package_three_d
    where 	complex_id = @complex_id 
    and		ptran_status = 'C'
    and		campaign_no = @campaign_no
    and		print_transactions.print_id = @print_id
    and		@print_package_id = print_package_medium.print_package_id
    and		@print_package_id = print_package_three_d.print_package_id
    and		print_transactions.print_medium = print_package_medium.print_medium
    and		print_transactions.three_d_type = print_package_three_d.three_d_type
    and		print_transactions.print_medium = 'D'
    and		print_transactions.three_d_type > 1
    and     (print_transactions.print_medium = @print_medium
    or      @print_medium is null)
    and     (print_transactions.three_d_type = @three_d_type
    or      @three_d_type is null)
    
    if @generated = 'G' or @generated = 'E'
    begin
        select  @used_35mm_qty = isnull(count(ci.print_id),0) 
        from    certificate_item ci,
                certificate_group cg,
                campaign_spot spot
        where   ci.certificate_group = cg.certificate_group_id 
        and     cg.complex_id = @complex_id 
        and     cg.screening_date = @screening_date 
        and     ci.item_show = 'Y' 
        and     ci.print_id = @print_id 
        and     ci.spot_reference = spot.spot_id 
        and     spot.campaign_no = @campaign_no
        and     ci.print_medium = 'F'
        and     ci.three_d_type = 1
        and     (ci.print_medium = @print_medium
        or      @print_medium is null)
        and     (ci.three_d_type = @three_d_type
        or      @three_d_type is null)
        
        select  @used_2d_qty = isnull(count(ci.print_id),0) 
        from    certificate_item ci,
                certificate_group cg,
                campaign_spot spot
        where   ci.certificate_group = cg.certificate_group_id 
        and     cg.complex_id = @complex_id 
        and     cg.screening_date = @screening_date 
        and     ci.item_show = 'Y' 
        and     ci.print_id = @print_id 
        and     ci.spot_reference = spot.spot_id 
        and     spot.campaign_no = @campaign_no
        and     ci.print_medium = 'D'
        and     ci.three_d_type = 1
        and     (ci.print_medium = @print_medium
        or      @print_medium is null)
        and     (ci.three_d_type = @three_d_type
        or      @three_d_type is null)

        select  @used_3d_qty = isnull(count(ci.print_id),0) 
        from    certificate_item ci,
                certificate_group cg,
                campaign_spot spot
        where   ci.certificate_group = cg.certificate_group_id 
        and     cg.complex_id = @complex_id 
        and     cg.screening_date = @screening_date 
        and     ci.item_show = 'Y' 
        and     ci.print_id = @print_id 
        and     ci.spot_reference = spot.spot_id 
        and     spot.campaign_no = @campaign_no        
        and     ci.print_medium = 'D'
        and     ci.three_d_type > 1
        and     (ci.print_medium = @print_medium
        or      @print_medium is null)
        and     (ci.three_d_type = @three_d_type
        or      @three_d_type is null)
    end
    else if @generated = 'N'
    begin
        select  @used_35mm_qty = isnull(max(temp_table.count),0)
        from    (select     count(ppack.print_id) as count
                from        campaign_spot spot,
                            campaign_package cp,
                            print_package ppack,
                            print_package_medium ppack_med,
                            print_package_three_d ppack_three_d
                where       spot.package_id = cp.package_id 
                and         cp.package_id = ppack.package_id 
                and         ppack.print_id = @print_id 
                and         spot.complex_id = @complex_id 
                and         spot.campaign_no = @campaign_no 
                and         spot.screening_date = @screening_date
                and         ppack.print_package_id = ppack_med.print_package_id
                and         ppack_med.print_medium = 'F'
                and         (ppack_med.print_medium = @print_medium
                or          @print_medium is null)
                and         ppack.print_package_id = ppack_three_d.print_package_id
                and         ppack_three_d.three_d_type = 1 
                and         (ppack_three_d.three_d_type = @three_d_type
                or          @three_d_type is null)) as temp_table

        select  @used_2d_qty = isnull(max(temp_table.count),0)
        from    (select     count(ppack.print_id) as count
                from        campaign_spot spot,
                            campaign_package cp,
                            print_package ppack,
                            print_package_medium ppack_med,
                            print_package_three_d ppack_three_d
                where       spot.package_id = cp.package_id 
                and         cp.package_id = ppack.package_id 
                and         ppack.print_id = @print_id 
                and         spot.complex_id = @complex_id 
                and         spot.campaign_no = @campaign_no 
                and         spot.screening_date = @screening_date
                and         ppack.print_package_id = ppack_med.print_package_id
                and         ppack_med.print_medium = 'D'
                and         (ppack_med.print_medium = @print_medium
                or          @print_medium is null)
                and         ppack.print_package_id = ppack_three_d.print_package_id
                and         ppack_three_d.three_d_type = 1 
                and         (ppack_three_d.three_d_type = @three_d_type
                or          @three_d_type is null)) as temp_table

        select  @used_3d_qty = isnull(max(temp_table.count),0)
        from    (select     count(ppack.print_id) as count
                from        campaign_spot spot,
                            campaign_package cp,
                            print_package ppack,
                            print_package_medium ppack_med,
                            print_package_three_d ppack_three_d
                where       spot.package_id = cp.package_id 
                and         cp.package_id = ppack.package_id 
                and         ppack.print_id = @print_id 
                and         spot.complex_id = @complex_id 
                and         spot.campaign_no = @campaign_no 
                and         spot.screening_date = @screening_date
                and         ppack.print_package_id = ppack_med.print_package_id
                and         ppack_med.print_medium = 'D'
                and         (ppack_med.print_medium = @print_medium
                or          @print_medium is null)
                and         ppack.print_package_id = ppack_three_d.print_package_id
                and         ppack_three_d.three_d_type > 1 
                and         (ppack_three_d.three_d_type = @three_d_type
                or          @three_d_type is null)) as temp_table

    end
    else if @generated = 'U'
        select  @used_35mm_qty = @complex_35mm_qty,
                @used_2d_qty = @complex_2d_qty,
                @used_3d_qty = @complex_3d_qty
    

    if @print_medium is null
        update  #prints_avail
        set     used_35mm_qty = isnull(@used_35mm_qty,0),
                used_2d_qty = isnull(@used_2d_qty,0),
                used_3d_qty = isnull(@used_3d_qty,0),
                complex_35mm_qty = isnull(@complex_35mm_qty,0),
                complex_2d_qty = isnull(@complex_2d_qty,0),
                complex_3d_qty = isnull(@complex_3d_qty,0)
        where   print_id = @print_id
        and     print_package_id = @print_package_id
    else
        update  #prints_avail
        set     used_35mm_qty = isnull(@used_35mm_qty,0),
                used_2d_qty = isnull(@used_2d_qty,0),
                used_3d_qty = isnull(@used_3d_qty,0),
                complex_35mm_qty = isnull(@complex_35mm_qty,0),
                complex_2d_qty = isnull(@complex_2d_qty,0),
                complex_3d_qty = isnull(@complex_3d_qty,0)
        where   print_id = @print_id
        and     print_package_id = @print_package_id
        and     print_medium = @print_medium
        and     three_d_Type = @three_d_type
    
    
    fetch prints_csr into @print_package_id, @print_id, @print_medium, @three_d_type
end
         
         
select  campaign_no,
        start_date,
        package_id,
        used_by_date,     
        screening_trailers,
        print_id,
        shell_section,
        print_sequence,
        print_spacing,
        print_package_id,
        print_status,
        key_ref,
        actual_duration,
        print_name,
        complex_35mm_qty,
        complex_2d_qty,
        complex_3d_qty,
        used_35mm_qty,
        used_2d_qty,
        used_3d_qty,
        print_medium,
        three_d_type        
from    #prints_avail
GO
