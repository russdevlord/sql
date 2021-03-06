/****** Object:  StoredProcedure [dbo].[p_complex_revenue_makegood]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_revenue_makegood]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_revenue_makegood]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_revenue_makegood] 
as
set nocount on  
/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @spot_id							int,		
        @complex_id							int,
        @makegood_rate                      numeric(18,4),
        @billing_period                     datetime,
        @ultimate_spot_id                   int,
        @screening_date                     datetime,
        @billing_date                       datetime,        
        @revenue_source						char(1),                        
        @cancelled						    char(1),
        @takeout_rate                       numeric(18,4),
        @cinema_rate                        numeric(18,4),                                                                                
        @ultimate						    char(1),
        @campaign_no                        int,
        @exists                             int,
        @generation_date                    datetime,
        @accounting_period                  datetime

begin transaction

select      @cinema_rate = 0

select      @generation_date = (convert(char(4), YEAR(GETDATE())) + '/' + convert(varchar(2), MONTH(GETDATE())) + '/' + convert(varchar(2),DAY(GETDATE())))

select      @accounting_period = min(finyear_end)
from        accounting_period
where       status = 'O' 

declare     makegood_csr cursor static for
select      spot.campaign_no, 
            spot.complex_id, 
            sum(spot.makegood_rate), 
            spot.billing_period,
            pack.revenue_source,
            (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
            spot.billing_date,
            spot.screening_date
from        campaign_spot spot,
            campaign_package pack,
            film_screening_dates fsd
where       makegood_rate <> 0
and         fsd.finyear_end >= dateadd(yy, -1, @accounting_period)
and         spot.package_id = pack.package_id
and         spot.billing_date = fsd.screening_date           
group by    spot.campaign_no, 
            spot.complex_id, 
            spot.billing_period, 
            pack.revenue_source, 
            spot.spot_status, 
            spot.billing_date, 
            spot.screening_date
order by    spot.campaign_no, 
            spot.complex_id, 
            spot.billing_period, 
            pack.revenue_source, 
            spot.spot_status, 
            spot.billing_date, 
            spot.screening_date
for read only
        
	open makegood_csr
	fetch makegood_csr into @campaign_no, @complex_id, @makegood_rate, @billing_period, @revenue_source, @cancelled, @billing_date, @screening_date 
	while(@@fetch_status = 0)
	begin
        
        select @exists = 0
       
        select @exists = 1
          from complex_projected_revenue rev
         where rev.complex_id = @complex_id
           and rev.campaign_no = @campaign_no
           and rev.billing_period = @billing_period
           and rev.revenue_source = @revenue_source
           and rev.billing_date = @billing_date
           and rev.screening_date = @screening_date
           and generation_date = @generation_date
           
        /* Update complex_projected_revenue */ 
        if @exists = 1
   	    begin
            update complex_projected_revenue 
               set makegood_rate = @makegood_rate
             where complex_id = @complex_id
               and campaign_no = @campaign_no
               and billing_period = @billing_period  
               and revenue_source = @revenue_source
               and billing_date = @billing_date
               and screening_date = @screening_date 
               and generation_date = @generation_date
                             
         select @error = @@error
        if (@error !=0)
        begin
	        rollback transaction
	        goto error
        end

       end
        else
        /* Insert into Complex Projected Revenue */
        begin
        
	        insert into complex_projected_revenue(
		        generation_date,
		        complex_id,
		        campaign_no,
		        screening_date,
		        billing_date,
		        billing_period,
		        revenue_source,
		        cancelled,
		        cinema_rate,
		        makegood_rate,
		        takeout_rate) values (
		        @generation_date,  
		        @complex_id,
		        @campaign_no,
		        @screening_date,
		        @billing_date,
 		        @billing_period,
		        @revenue_source,
		        @cancelled, 
		        @cinema_rate, 
		        @makegood_rate,
		        0) 
									
	        select @error = @@error
	        if (@error !=0)
	        begin
		        rollback transaction
		        goto error
	        end
        end
            	
    	fetch makegood_csr into @campaign_no, @complex_id, @makegood_rate, @billing_period, @revenue_source, @cancelled, @billing_date, @screening_date

	end
	close makegood_csr
	deallocate makegood_csr


declare     makegood_csr cursor static for
select      spot.campaign_no, 
            cl.complex_id, 
            sum(spot.makegood_rate), 
            spot.billing_period,
            pack.revenue_source,
            (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
            spot.billing_date,
            spot.screening_date
from        cinelight_spot spot,
            cinelight cl,
            cinelight_package pack,
            film_screening_dates fsd
where       makegood_rate <> 0
and         fsd.finyear_end >= dateadd(yy, -1, @accounting_period)
and         spot.package_id = pack.package_id
and         spot.cinelight_id = cl.cinelight_id
and         spot.package_id = pack.package_id           
group by    spot.campaign_no, 
            cl.complex_id, 
            spot.billing_period, 
            pack.revenue_source, 
            spot.spot_status, 
            spot.billing_date, 
            spot.screening_date
order by    spot.campaign_no, 
            cl.complex_id, 
            spot.billing_period, 
            pack.revenue_source, 
            spot.spot_status, 
            spot.billing_date, 
            spot.screening_date
for read only

                   
                       
open makegood_csr
fetch makegood_csr into @campaign_no, @complex_id, @makegood_rate, @billing_period, @revenue_source, @cancelled, @billing_date, @screening_date 
while(@@fetch_status = 0)
begin
    
    select @exists = 0
   
    select @exists = 1
      from complex_projected_revenue rev
     where rev.complex_id = @complex_id
       and rev.campaign_no = @campaign_no
       and rev.billing_period = @billing_period
       and rev.revenue_source = @revenue_source
       and rev.billing_date = @billing_date
       and rev.screening_date = @screening_date
       and generation_date = @generation_date
       
       
    /* Update complex_projected_revenue */ 
    if @exists = 1
   	begin
        update complex_projected_revenue 
           set makegood_rate = @makegood_rate
         where complex_id = @complex_id
           and campaign_no = @campaign_no
           and billing_period = @billing_period  
           and revenue_source = @revenue_source
           and billing_date = @billing_date
           and screening_date = @screening_date  
           and generation_date = @generation_date

        select @error = @@error
        if (@error !=0)
        begin
	        rollback transaction
	        goto error
        end
           
    end
    else
    /* Insert into Complex Projected Revenue */
    begin
         
	    insert into complex_projected_revenue(
		    generation_date,
		    complex_id,
		    campaign_no,
		    screening_date,
		    billing_date,
		    billing_period,
		    revenue_source,
		    cancelled,
		    cinema_rate,
		    makegood_rate,
		    takeout_rate) values (
		    @generation_date,  
		    @complex_id, 
		    @campaign_no,
		    @screening_date,
		    @billing_date, 
 		    @billing_period,
		    @revenue_source,
		    @cancelled, 
		    @cinema_rate,
		    @makegood_rate,
		    0)
								
	    select @error = @@error
	    if (@error !=0)
	    begin
		    rollback transaction
		    goto error
	    end
    end
            
    fetch makegood_csr into @campaign_no, @complex_id, @makegood_rate, @billing_period, @revenue_source, @cancelled, @billing_date, @screening_date

end

close makegood_csr
deallocate makegood_csr

declare     makegood_csr cursor static for
select      spot.campaign_no, 
            spot.complex_id, 
            sum(spot.makegood_rate), 
            spot.billing_period,
            'I' as revenue_source,
            (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
            spot.billing_date,
            spot.screening_date
from        inclusion_spot spot,
            inclusion pack,
            film_screening_dates fsd
where       makegood_rate <> 0
and         fsd.finyear_end >= dateadd(yy, -1, @accounting_period)
and         spot.billing_date = fsd.screening_date    
and         spot.inclusion_id = pack.inclusion_id
and         pack.inclusion_type = 5
group by    spot.campaign_no, 
            spot.complex_id, 
            spot.billing_period, 
            spot.spot_status, 
            spot.billing_date, 
            spot.screening_date
order by    spot.campaign_no, 
            spot.complex_id, 
            spot.billing_period, 
            spot.spot_status, 
            spot.billing_date, 
            spot.screening_date
for         read only            

open makegood_csr
fetch makegood_csr into @campaign_no, @complex_id, @makegood_rate, @billing_period, @revenue_source, @cancelled, @billing_date, @screening_date 
while(@@fetch_status = 0)
begin
    
    select @exists = 0
   
    select @exists = 1
      from complex_projected_revenue rev
     where rev.complex_id = @complex_id
       and rev.campaign_no = @campaign_no
       and rev.billing_period = @billing_period
       and rev.revenue_source = @revenue_source
       and rev.billing_date = @billing_date
       and rev.screening_date = @screening_date
       and generation_date = @generation_date
       
    /* Update complex_projected_revenue */ 
    if @exists = 1
   	begin
        update complex_projected_revenue 
           set makegood_rate = @makegood_rate
         where complex_id = @complex_id
           and campaign_no = @campaign_no
           and billing_period = @billing_period  
           and revenue_source = @revenue_source
           and billing_date = @billing_date
           and screening_date = @screening_date 
           and generation_date = @generation_date
           
        select @error = @@error
        if (@error !=0)
        begin
	        rollback transaction
	        goto error
        end
    end
    else
    /* Insert into Complex Projected Revenue */
    begin
    
  	    insert into complex_projected_revenue(
		    generation_date,
		    complex_id,
		    campaign_no,
		    screening_date,
		    billing_date,
		    billing_period,
		    revenue_source,
		    cancelled,
		    cinema_rate,
		    makegood_rate,
		    takeout_rate) values (
		    @generation_date, 
		    @complex_id,
		    @campaign_no,
		    @screening_date,
		    @billing_date, 
 		    @billing_period,
		    @revenue_source,
		    @cancelled, 
		    @cinema_rate,
		    @makegood_rate,
		    0) 
								
	    select @error = @@error
	    if (@error !=0)
	    begin
		    rollback transaction
		    goto error
	    end
    end
            
    fetch makegood_csr into @campaign_no, @complex_id, @makegood_rate, @billing_period, @revenue_source, @cancelled, @billing_date, @screening_date 

end

close makegood_csr
deallocate makegood_csr

commit transaction
return 0

/* Error Handler */

error:

    raiserror ( 'Error: Failed to Generate Update of Makegood Rate for Complex Projected Revenue for Campaign %1!', 11, 1, @campaign_no)
    return -100
GO
