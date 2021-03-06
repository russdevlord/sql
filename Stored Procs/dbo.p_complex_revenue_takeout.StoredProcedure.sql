/****** Object:  StoredProcedure [dbo].[p_complex_revenue_takeout]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_revenue_takeout]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_revenue_takeout]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_revenue_takeout] 
as
set nocount on  

/* Declare Variables */
declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @complex_id							int,
        @revenue_period                     datetime,
        @revenue_period_alt                 datetime,
        @billing_period                     datetime,        
        @revenue_source						char(1),                        
        @inclusion_category 			    char(1),
        @takeout_rate                       numeric(18,4),
        @cinema_rate                        numeric(18,4),                                                                                
        @campaign_no                        int,
        @count								int,
        @total_cinema_rate                  numeric(18,4),
        @percentage                         numeric(18,4), 
        @amount                             numeric(18,4),
        @screening_date                     datetime,
        @billing_date                       datetime,
        @cancelled                          char(1),
        @generation_date                    datetime,
        @business_unit_id                   int

begin transaction

select 	@generation_date = min(end_date)
from	accounting_period

/* fetch takeout rates */
declare     takeout_csr cursor static for
select      spot.campaign_no, 
            inc.inclusion_category, 
            sum(spot.takeout_rate), 
            spot.revenue_period,
            film_campaign.business_unit_id
from        inclusion_spot spot,
            inclusion inc,
            film_campaign
where       spot.inclusion_id = inc.inclusion_id
and         spot.campaign_no in (select distinct campaign_no from complex_projected_revenue where generation_date = @generation_date) 
and         spot.campaign_no = inc.campaign_no           
and         inc.inclusion_category <> 'S'
and         takeout_rate <> 0
and         spot.campaign_no = film_campaign.campaign_no
and         inc.campaign_no = film_campaign.campaign_no
group by    spot.campaign_no,
            inc.inclusion_category, 
            spot.revenue_period,
            film_campaign.business_unit_id
for read only

open takeout_csr
fetch takeout_csr into @campaign_no, @inclusion_category, @takeout_rate, @revenue_period, @business_unit_id
while(@@fetch_status = 0)
begin

    if @business_unit_id = 5 and (@inclusion_category = 'D' or @inclusion_category = 'F')
        select @inclusion_category = 'D'
        
    if @business_unit_id = 2 and @inclusion_category = 'D'
        select @inclusion_category = 'F'
   
    if @business_unit_id = 3 and @inclusion_category = 'F'
        select @inclusion_category = 'D'

    select  @total_cinema_rate = isnull(sum(cinema_rate), 0) + isnull(sum(makegood_rate),0)
    from    complex_projected_revenue com,
            film_screening_date_xref fsd
    where   com.campaign_no = @campaign_no
    and     fsd.benchmark_end = @revenue_period
    and     com.revenue_source = @inclusion_category  
    and     com.generation_date = @generation_date
    and     com.billing_date = fsd.screening_date
    
    if @total_cinema_rate > 0 
    begin
        /* split takeoutamount across records */
        declare split_csr cursor static for
        select  complex_id,
                com.screening_date,
                billing_date,
                billing_period,
                cancelled,
                isnull(com.cinema_rate, 0) + isnull(com.makegood_rate,0)
        from    complex_projected_revenue com,
                film_screening_date_xref fsd
        where   com.campaign_no = @campaign_no
        and     fsd.benchmark_end = @revenue_period
        and     com.revenue_source = @inclusion_category
        and     com.generation_date = @generation_date
        and     com.billing_date = fsd.screening_date
        and     (com.cinema_rate <> 0 or com.makegood_rate <> 0)
        for     read only

	    open split_csr
	    fetch split_csr into @complex_id, @screening_date, @billing_date, @billing_period, @cancelled, @cinema_rate
	    while(@@fetch_status = 0)
	    begin            
    
            select @percentage = (@cinema_rate/@total_cinema_rate)
        
            select @amount = @percentage * @takeout_rate
        
            update complex_projected_revenue
               set takeout_rate = isnull(takeout_rate,0) + @amount
             where campaign_no = @campaign_no
               and billing_period = @billing_period
               and revenue_source = @inclusion_category
               and screening_date = @screening_date
               and cancelled = @cancelled
               and billing_date = @billing_date
               and complex_id = @complex_id
               and revenue_source = @inclusion_category
               and generation_date = @generation_date
               
                           
	        select @error = @@error
	        if (@error !=0)
	        begin
		        rollback transaction
		        goto error
	        end

            select @percentage = 0
            select @amount= 0
    
		    /* Fetch next record */
    	    fetch split_csr into @complex_id, @screening_date, @billing_date, @billing_period, @cancelled, @cinema_rate

	    end

	    close split_csr
	    deallocate split_csr            
    end
    else if @total_cinema_rate = 0
    begin
    
        select  @total_cinema_rate = sum(isnull(cinema_rate,0)) + sum(isnull(makegood_rate,0))
        from    complex_projected_revenue com
        where   com.campaign_no = @campaign_no
        and     com.revenue_source = @inclusion_category  
        and     com.generation_date = @generation_date
        
        /* split takeoutamount across records */
        declare split_csr cursor static for
        select  complex_id,
                sum(isnull(cinema_rate,0)) + sum(isnull(makegood_rate,0))
        from    complex_projected_revenue com
        where   com.campaign_no = @campaign_no
        and     com.revenue_source = @inclusion_category
        and     com.generation_date = @generation_date
        group by complex_id
        for     read only

	    open split_csr
	    fetch split_csr into @complex_id, @cinema_rate
	    while(@@fetch_status = 0)
	    begin            
    
            select @percentage = (@cinema_rate/@total_cinema_rate)
        
            select @amount = @percentage * @takeout_rate
        
            insert into complex_projected_revenue
            (generation_date,
            complex_id,
            campaign_no,
            screening_date,
            billing_date,
            billing_period,
            revenue_source,
            cancelled,
            cinema_rate,
            makegood_rate,
            takeout_rate) values
            (@generation_date,
            @complex_id,
            @campaign_no,
            dateadd(dd, -6,@revenue_period),
            dateadd(dd, -6,@revenue_period),
            @revenue_period,
            @inclusion_category,
            'N',
            0,
            0,
            @amount)
            
	    select @error = @@error
	    if (@error !=0)
	    begin
		    rollback transaction
		    goto error
	    end


            select @percentage = 0
            select @amount= 0
    
		    /* Fetch next record */
	        fetch split_csr into @complex_id, @cinema_rate

	    end

	    close split_csr
	    deallocate split_csr            
        
    end        


	/* Fetch next record */
    fetch takeout_csr into @campaign_no, @inclusion_category, @takeout_rate, @revenue_period,@business_unit_id

end

close takeout_csr
deallocate takeout_csr

commit transaction
return 0

/* Error Handler */
error:

    raiserror ( 'Error: Failed to Update Takeout Rate on Complex Projected Revenue for Campaign %1!', 11, 1, @campaign_no)
    return -100
GO
