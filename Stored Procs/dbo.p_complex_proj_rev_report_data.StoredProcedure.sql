/****** Object:  StoredProcedure [dbo].[p_complex_proj_rev_report_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_proj_rev_report_data]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_proj_rev_report_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_complex_proj_rev_report_data]  
                                                @report_start_date      datetime, 
                                                @report_end_date        datetime,
                                                @generation_date        datetime
                                               
                                                
as

declare @error     				int,
        @err_msg                varchar(150),
		@cinema_agreement_id    int,
        @start_date             datetime,
        @end_date               datetime,
        @revenue_source         char(1),
        @count                  int,
        @billing_period         datetime,
        @complex_id             int,
        @complex_name           varchar(150),
        @revenue                varchar(15),        
        @total                  money,
        @exists                 char(1),
        @date1                  datetime,
        @date2                  datetime,
        @date3                  datetime,
        @date4                  datetime,
        @date5                  datetime,
        @date6                  datetime,
        @date7                  datetime,
        @date8                  datetime,
        @date9                  datetime,  
        @date10                 datetime, 
        @date11                 datetime,
        @date12                 datetime,
        @future_total           money,
        @agreement_desc         varchar(150),
        @accounting_periods     int        
        

begin

CREATE TABLE #result_set
(   complex_id      int             NOT NULL,
    billing_period  datetime        NOT NULL,
    revenue_source  char(1)         NOT NULL,
    complex_name    varchar(250)    NOT NULL,
    revenue_type    varchar(30)     NOT NULL,
    month1          money           NULL,
    month2          money           NULL,
    month3          money           NULL,      
    month4          money           NULL,      
    month5          money           NULL,
    month6          money           NULL,
    month7          money           NULL,
    month8          money           NULL,  
    month9          money           NULL,
    month10         money           NULL,
    month11         money           NULL,
    month12         money           NULL,
    future_total    money           NULL,
    agreement_desc  varchar(150)    NULL
 )

declare     complex_csr cursor static for
select      distinct rev.revenue_source,
            rev.complex_id,
            fsdx.benchmark_end,
            com.complex_name,
            revenue_desc,
            (sum(isnull(rev.cinema_rate, 0)) + sum(isnull(rev.makegood_rate, 0)) - sum(isnull(rev.takeout_rate, 0))) * (1 - fc.commission),
            cag.agreement_desc
from        complex_projected_revenue rev, 
            complex com, 
            cinema_agreement_policy cap, 
            cinema_agreement cag, 
            film_screening_date_xref fsdx,
            cinema_revenue_source,
            film_campaign fc
where       cap.cinema_agreement_id = @cinema_agreement_id
and         fsdx.screening_date = rev.billing_date
and         fsdx.benchmark_end between @report_start_date and @report_end_date 
and         cap.cinema_agreement_id = cag.cinema_agreement_id 
and         rev.complex_id = com.complex_id
and         cap.complex_id = com.complex_id
and         cap.revenue_source = rev.revenue_source
and         cap.policy_status_code = 'A' 
and         rev.cancelled = 'N'
and         fc.campaign_no = rev.campaign_no
and         isnull(cap.rent_inclusion_start, '1-jan-1900') <= rev.billing_period
and         isnull(cap.rent_inclusion_end, '1-jan-2050') >= rev.billing_period   
and         cinema_revenue_source.revenue_source = rev.revenue_source    
group by    rev.complex_id, 
            fsdx.benchmark_end, 
            com.complex_name, 
            revenue_desc,
            rev.revenue_source,
            fc.commission, 
            cag.agreement_desc    
order by    com.complex_name, 
            fsdx.benchmark_end, 
            revenue_desc
for read only 

       
open complex_csr
fetch complex_csr into @revenue_source, @complex_id, @billing_period, @complex_name, @revenue, @total, @agreement_desc
while(@@fetch_status = 0)
begin
    
    select      @count = 0 
    select      @future_total = 0     
 
    select      @future_total = (sum(isnull(rev.cinema_rate, 0)) + sum(isnull(rev.makegood_rate, 0)) - sum(isnull(rev.takeout_rate, 0))) * (1 - fc.commission)
    from        complex_projected_revenue rev, 
                complex com, 
                cinema_agreement_policy cap, 
                film_screening_date_xref fsdx,
                film_campaign fc
    where       cinema_agreement_id = @cinema_agreement_id
    and         fsdx.screening_date = rev.billing_date
    and         fsdx.benchmark_end > @report_end_date 
    and         rev.revenue_source = @revenue_source 
    and         rev.complex_id = @complex_id
    and         rev.complex_id = com.complex_id
    and         cap.complex_id = com.complex_id
    and         cap.revenue_source = rev.revenue_source
    and         cap.policy_status_code = 'A' 
    and         rev.cancelled = 'N'
    and         fc.campaign_no = rev.campaign_no
    and         isnull(cap.rent_inclusion_start, '1-jan-1900') <= rev.billing_period
    and         isnull(cap.rent_inclusion_end, '1-jan-2050') >= rev.billing_period       
    group by    fc.commission        
    
    declare     accounting_periods_csr cursor static for
    select      benchmark_end
    from        accounting_period
    where       benchmark_end >= @report_start_date 
    and         benchmark_end <= @report_end_date
    order by    end_date
    for         read only
    
	open accounting_periods_csr
	fetch accounting_periods_csr into @end_date
	while(@@fetch_status = 0)
	begin
        
        select @count = @count + 1
            
        select @exists = 0
        
        /* check if record exists so we know whether to update or insert */
        select @exists = 1
          from #result_set
         where complex_id = @complex_id
           and revenue_source = @revenue_source
           
        if @billing_period = @end_date
        begin
            if @exists > 0
            /* update */
            begin
                if @count = 1
                begin
                    update #result_set 
                       set month1 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
                       
                    if @date1 = null
                        select @date1 = @end_date
                end
                
                if @count = 2
                begin
                    update #result_set 
                       set month2 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source

                    if @date2 = null
                        select @date2 = @end_date
                end
                
                if @count = 3
                begin
                    update #result_set 
                       set month3 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source

                    if @date3 = null                
                        select @date3 = @end_date
                end
                                       
                if @count = 4
                begin
                    update #result_set 
                       set month4 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
             
                    if @date4 = null                
                        select @date4 = @end_date
                end
                                       
                if @count = 5
                begin
                    update #result_set 
                       set month5 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
                     
                    if @date5 = null                
                        select @date5 = @end_date
                end
                                       
                if @count = 6
                begin
                    update #result_set 
                       set month6 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
                
                    if @date6 = null
                        select @date6 = @end_date
                end
                       
                if @count = 7
                begin
                    update #result_set 
                       set month7 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
                       
                    if @date7 = null                
                        select @date7 = @end_date
                end
                                       
                if @count = 8
                begin
                    update #result_set 
                       set month8 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source

                    if @date8 = null                
                        select @date8 = @end_date
                end
                                       
                if @count = 9
                begin
                    update #result_set 
                       set month9 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
                    
                    if @date9 is null                
                       select @date9 = @end_date
                end
                
                if @count = 10
                begin
                    update #result_set 
                       set month10 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source

                    if @date10 = null               
                       select @date10 = @end_date
                end
                                       
                if @count = 11
                begin
                    update #result_set 
                       set month11 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
            
                    if @date11 = null                        
                        select @date11 = @end_date
                end
                                       
                if @count = 12
                begin
                    update #result_set 
                       set month12 = @total,
                           future_total = @future_total
                     where complex_id = @complex_id 
                       and revenue_source = @revenue_source
       
                    if @date12 = null
                        select @date12 = @end_date 
                 end                                
            end
            else
            /* insert */
            begin
            if @count = 1
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month1, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)

                    if @date1 = null
                        select @date1 = @end_date
                end
                
                if @count = 2
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month2, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                

                    if @date2 = null
                        select @date2 = @end_date                
                end
                    
                if @count = 3
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month3, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                

                    if @date3 = null
                        select @date3 = @end_date
                end
                                    
                if @count = 4
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month4, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                

                    if @date4 = null
                        select @date4 = @end_date
                end
                                    
                if @count = 5
                begin                    
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month5, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                

                    if @date5 = null
                        select @date5 = @end_date
                end
                                    
                if @count = 6
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month6, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                                                                                

                    if @date6 = null
                        select @date6 = @end_date
                end
                                        
                if @count = 7
                begin                    
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month7, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)

                    if @date7 = null
               select @date7 = @end_date
                end
                                                        
                if @count = 8
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month8, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                
                     
                    if @date8 = null
                        select @date8 = @end_date
                end                            
                                    
                if @count = 9
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month9, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                
                    
                    if @date9 = null                
                        select @date9 = @end_date
                end
                    
                if @count = 10
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month10, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                
                     
                    if @date10 = null                
                     select @date10 = @end_date
                end
                                    
                if @count = 11
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month11, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                
                       
                    if @date11 = null                
                        select @date11 = @end_date
                end
                    
                if @count = 12
                begin
                    insert into #result_set (complex_id, billing_period, revenue_source, complex_name, revenue_type, month12, future_total, agreement_desc) 
                    values (@complex_id, @billing_period, @revenue_source, @complex_name, @revenue, @total, @future_total, @agreement_desc)                                                                                                
                    
                    if @date12 = null
                        select @date12 = @end_date                        
                 end                            

             end
   								
	            select @error = @@error
	            if (@error !=0)
	            begin
		            rollback transaction
		            goto error
	            end
            end    
            else
            begin -- add dates to values to pass back to report
                if @count = 1
                    if @date1 = null
                        select @date1 = @end_date    
                if @count = 2
                    if @date2 = null
                        select @date2 = @end_date    
                if @count = 3
                    if @date3 = null
                        select @date3 = @end_date    
                if @count = 4
                    if @date4 = null
                        select @date4 = @end_date    
                if @count = 5
                    if @date5 = null
                        select @date5 = @end_date    
                if @count = 6
                    if @date6 = null
                        select @date6 = @end_date    
                if @count = 7
                    if @date7 = null
                        select @date7 = @end_date    
                if @count = 8
                    if @date8 = null
                        select @date8 = @end_date    
                if @count = 9
                    if @date9 = null
                        select @date9 = @end_date    
                if @count = 10
                    if @date10 = null
                        select @date10 = @end_date    
                if @count = 11
                    if @date11 = null
                        select @date11 = @end_date    
                if @count = 12
                    if @date12 = null
                        select @date12 = @end_date    
            end
                
    	    fetch accounting_periods_csr into @end_date

	        end
	        close accounting_periods_csr
	        deallocate accounting_periods_csr
            
    fetch complex_csr into @revenue_source, @complex_id, @billing_period, @complex_name, @revenue, @total, @agreement_desc
    
end

close complex_csr
deallocate complex_csr

-- extract number of accounting periods for x Month Total column text 
select @accounting_periods = count(*)
from        accounting_period
where       benchmark_end >= @report_start_date 
and         benchmark_end <= @report_end_date

-- return results to datawindow
select complex_id,
       billing_period,
       revenue_source,
       complex_name,
       revenue_type,
       isnull(month1, 0) month1,
       isnull(month2, 0) month2,
       isnull(month3, 0) month3, 
       isnull(month4, 0) month4,
       isnull(month5, 0) month5,
       isnull(month6, 0) month6,
       isnull(month7, 0) month7,
       isnull(month8, 0) month8,
       isnull(month9, 0) month9,
       isnull(month10, 0) month10,
       isnull(month11, 0) month11,
       isnull(month12, 0) month12,
       @date1,
       @date2,  
       @date3,     
       @date4,      
       @date5, 
       @date6,
       @date7,
       @date8,
       @date9,
       @date10,
       @date11,
       @date12,
       future_total,
       agreement_desc,
       @report_start_date start_date, 
       @report_end_date end_date,
       @accounting_periods        
  from #result_set
order by complex_name, revenue_source

end

error:
        
if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
return 0
GO
