/****** Object:  StoredProcedure [dbo].[p_ipo_graph3]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_ipo_graph3]
GO
/****** Object:  StoredProcedure [dbo].[p_ipo_graph3]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_ipo_graph3]        @start_date         datetime,
                                @end_date           datetime
                                
as 

declare     @error                  int,
            @campaign_no            int,
            @follow_film            char(1),
            @no_paid_spots          int,
            @no_bonus_spots         int,
            @revenue                money,
            @duration               int,
            @avail_time             int,
            @media_product_id       int

set nocount on

create table #graph3
(
campaign_no             int         null,
follow_film             char(1)     null,
media_product_id        int         null,
duration                int         null,
no_paid_spots           int         null,
no_bonus_spots          int         null,
revenue                 money       null,
avail_time              int         null
)                                

declare     camp_csr cursor forward_only for
select      campaign_spot.campaign_no,
            follow_film,
            duration,
            media_product_id
FROM 		campaign_spot,
			campaign_package,
            film_campaign
WHERE 		campaign_package.package_id = campaign_spot.package_id
AND 		campaign_spot.spot_status != 'P'
and         film_campaign.campaign_no = campaign_spot.campaign_no
and         film_campaign.branch_code <> 'Z'
and         billing_date between @start_date and @end_date
GROUP BY 	campaign_spot.campaign_no,
            follow_film,
            duration,
            media_product_id
order BY 	campaign_spot.campaign_no,
            follow_film,
            duration,
            media_product_id
            

open camp_csr
fetch camp_csr into @campaign_no, @follow_film,@duration,@media_product_id
while(@@fetch_status = 0)
begin

    select  @no_paid_spots = count(spot_id),
            @revenue = sum(campaign_spot.charge_rate)
    from    campaign_spot,
            campaign_package
    where   spot_status <> 'P'
    and     campaign_spot.campaign_no = @campaign_no
    and     spot_type = 'S'
    and     billing_date between @start_date and @end_date
    and     follow_film = @follow_film
    and     duration = @duration
    and     campaign_spot.package_id = campaign_package.package_id
    and     media_product_id = @media_product_id
                
    select  @no_bonus_spots = count(spot_id)
    from    campaign_spot,
            campaign_package
    where   spot_status <> 'P'
    and     campaign_spot.campaign_no = @campaign_no
    and     spot_type in ('B','C','N')
    and     billing_date between @start_date and @end_date
    and     follow_film = @follow_film
    and     duration = @duration
    and     campaign_spot.package_id = campaign_package.package_id    
    and     media_product_id = @media_product_id
    
    if @media_product_id = 1
    begin
        select  @avail_time = sum(max_time)
        from    complex_date,
                campaign_spot,
                campaign_package
        where   complex_date.complex_id = campaign_spot.complex_id
        and     complex_date.screening_date = campaign_spot.screening_date
        and     campaign_spot.campaign_no = @campaign_no  
        and     billing_date between @start_date and @end_date
        and     follow_film = @follow_film
        and     duration = @duration    
        and     media_product_id = @media_product_id
        and     campaign_spot.package_id = campaign_package.package_id
    end
    else        
    begin
        select  @avail_time = sum(mg_max_time)
        from    complex_date,
                campaign_spot,
                campaign_package
        where   complex_date.complex_id = campaign_spot.complex_id
        and     complex_date.screening_date = campaign_spot.screening_date
        and     campaign_spot.campaign_no = @campaign_no  
        and     billing_date between @start_date and @end_date
        and     follow_film = @follow_film
        and     duration = @duration    
        and     media_product_id = @media_product_id
        and     campaign_spot.package_id = campaign_package.package_id
    end    
    
 /*   select @avail_time = 0*/
    
    insert into #graph3
    values
    (
    @campaign_no,
    @follow_film,
    @media_product_id,
    @duration,
    @no_paid_spots,
    @no_bonus_spots,
    @revenue,
    @avail_time
    )
    
    fetch camp_csr into @campaign_no, @follow_film,@duration,@media_product_id
 
end


select      campaign_no,
            follow_film,
            media_product_id,
            duration,
            no_paid_spots,
            no_bonus_spots,
            revenue,
            avail_time, 
            (no_paid_spots * duration /30 ) as no_norm_paid_spots, 
            (no_bonus_spots * duration / 30) as no_norm_bonus_spots
from        #graph3
order by    campaign_no,
            follow_film,
            no_paid_spots,
            no_bonus_spots,
            revenue,
            duration  

return 0
GO
