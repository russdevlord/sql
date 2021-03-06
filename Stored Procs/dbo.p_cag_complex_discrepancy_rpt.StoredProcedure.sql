/****** Object:  StoredProcedure [dbo].[p_cag_complex_discrepancy_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_complex_discrepancy_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_complex_discrepancy_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROC [dbo].[p_cag_complex_discrepancy_rpt]	as

/*
 * Declare
 */

declare	@error							integer,
		@complex_id						integer,
		@cinema_agreement_id			integer,
		@rent_inclusion_start			datetime,
		@rent_inclusion_end				datetime,
		@complex_name					varchar(50),
		@agreement_desc					varchar(50),
		@agreement_start				datetime,
		@agreement_end					datetime,
        @close_date                     datetime,
		@agreement_status    			char(1),
		@category_message   			varchar(100),
		@branch_code					char(2),
		@exhibitor_id					integer,
		@exhibitor_name		    		varchar(50),
        @policy_id						integer,
        @complex_status					char(1),
        @valid_policies					integer,
        @multiple_valid_policies		integer,
        @cnt							integer,
        @policy_expires_date			datetime,
        @revenue_source					char(1),
        @policy_status_code				char(1),
        @message						char(255),
        @processing_start_date			datetime,
        @processing_end_date			datetime,
        @cnt_overlaping_policies		tinyint,
        @temp							varchar(100),
		@missing_periods				varchar(max),
		@current_period					datetime

create table #result_set
(
	complex_id					integer			null,
	complex_name				varchar(50)		null,
	exhibitor_name			    varchar(50)		null,
	category_message			varchar(max)	null,
	agreement_status		    char(1)			null,
	agreement_id				integer			null,
	agreement_desc			    varchar(50)		null,
	agreement_start				datetime		null,
	agreement_end				datetime		null,
	revenue_source				char(1)         null,
	policy_id					integer         null,
	rent_inclusion_start	    datetime		null,
	rent_inclusion_end		    datetime		null,
	policy_status				char(1)         null,   
	branch_code					char(2)			null,
	processing_start_date		datetime        null,
	processing_end_date			datetime        null
 )

select			@current_period = min(end_date)
from			accounting_period 
where			status = 'O'
/*
 * Declare complex cursor
 */

declare			complex_csr cursor static for
select			complex.complex_id,
				complex.complex_name,
				complex.branch_code,
				exhibitor.exhibitor_id,
				exhibitor.exhibitor_name,
				complex.film_complex_status
from			complex
inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id 
where			complex_id not in (1,2)
order by		complex.complex_id
for				read only


open complex_csr
fetch complex_csr into @complex_id, @complex_name, @branch_code, @exhibitor_id, @exhibitor_name, @complex_status
while(@@fetch_status=0)
begin
	if @complex_status <> 'C'
		select			@complex_status = 'A'
    
    select			@valid_policies = 0 
        
	/*
	 * Delcare cursor static for the complex ACTIVE, NEW policies
	 */

	declare			complex_active_policy_csr cursor static for
	select			cinema_agreement.cinema_agreement_id,   
					cinema_agreement.agreement_desc,   
					cinema_agreement.agreement_status,   
					cinema_agreement.agreement_start,   
					cinema_agreement.close_date,   
					cinema_agreement_policy.policy_id,   
					cinema_agreement_policy.policy_status_code,   
					cinema_agreement_policy.rent_inclusion_start,   
					cinema_agreement_policy.rent_inclusion_end ,
					cinema_agreement_policy.processing_start_date,
					cinema_agreement_policy.processing_end_date,
					cinema_agreement_policy.revenue_source
	from			cinema_agreement   
	inner join		cinema_agreement_policy on cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id
	where			complex_id = @complex_id 
	and				policy_status_code in ('A', 'N')
	and				revenue_source <> 'S'
                              
	open complex_active_policy_csr
	fetch complex_active_policy_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
	@close_date, @policy_id, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end, 
	@processing_start_date, @processing_end_date, @revenue_source
            
	while(@@fetch_status = 0)  
	begin    
		select			@valid_policies = @valid_policies + 1
                               
		select			@cnt_overlaping_policies = isnull(count(policy_id),0)
		from			cinema_agreement_policy  
		where			complex_id = @complex_id 
		and				revenue_source = @revenue_source 
		and				policy_status_code in ('A', 'N')
		and not			(policy_id = @policy_id 
		and				revenue_source = @revenue_source 
		and				complex_id = @complex_id 
		and				policy_status_code in ('A', 'N') 
		and				cinema_agreement_id = @cinema_agreement_id)
		and				((isnull(rent_inclusion_start, '1980-01-01') between isnull(@rent_inclusion_start, '1980-01-01') and IsNull(@rent_inclusion_end, convert(datetime,'2200-01-01')) 
		or				isNull(rent_inclusion_end, convert(datetime,'2200-01-01')) between isnull(@rent_inclusion_start,'1980-01-01') and IsNull(@rent_inclusion_end, convert(datetime,'2200-01-01'))) 
		or				(isnull(@rent_inclusion_start, '1980-01-01') between isnull(rent_inclusion_start, '1980-01-01') and IsNull(rent_inclusion_end, convert(datetime,'2200-01-01')) 
		or				isNull(@rent_inclusion_end, convert(datetime,'2200-01-01')) between isnull(rent_inclusion_start,'1980-01-01') and IsNull(rent_inclusion_end, convert(datetime,'2200-01-01'))))
		and				((processing_start_date between @processing_start_date and IsNull(@processing_end_date, convert(datetime,'2100-01-01')) 
		or				isNull(processing_end_date, processing_start_date) between @processing_start_date and IsNull(@processing_end_date, convert(datetime,'2100-01-01'))) 
		or				(@processing_start_date between processing_start_date and IsNull(processing_end_date, convert(datetime,'2100-01-01')) 
		or				isNull(@processing_end_date, @processing_start_date) between processing_start_date and IsNull(processing_end_date, convert(datetime,'2100-01-01'))))

		if isnull(@cnt_overlaping_policies, 0) > 0
		begin
			/*checks if the 'overlap' MESSAGE is already in the #result_set table for the @complex + @revenue_source + @policy_id*/
			select			@cnt = isnull(count(policy_id), 0)  from #result_set
			where			complex_id = @complex_id 
			and				agreement_id = @cinema_agreement_id  
			and				revenue_source = @revenue_source 
			and				policy_id = @policy_id 
			and				@category_message = 'Complex on Multiple Active Policies which Overlap'
                                            
			
			insert into #result_set (complex_id, complex_name, exhibitor_name, category_message, agreement_status, agreement_id,
			agreement_desc, agreement_start, agreement_end, revenue_source, policy_id,
			rent_inclusion_start, rent_inclusion_end, policy_status, branch_code, processing_start_date, processing_end_date)
			values (@complex_id, @complex_name, @exhibitor_name, 'Complex on Multiple Active Policies which Overlap', @agreement_status, @cinema_agreement_id,
			@agreement_desc, @agreement_start, @agreement_end, @revenue_source, @policy_id,
			@rent_inclusion_start, @rent_inclusion_end, @policy_status_code, @branch_code, @processing_start_date, @processing_end_date)  
		end /*@cnt_overlaping_policies > 0*/
                                    
                                
		if @complex_status = 'A' /*Complex is Active */
		begin
		/*Check the latest when complex expires from all policies  */                                    
			select			@policy_expires_date = max( isnull(cinema_agreement_policy.processing_end_date, convert(datetime, '2200-01-01')))
			from			cinema_agreement   
			inner join		cinema_agreement_policy on cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id
			where			complex_id = @complex_id 
			and				policy_status_code in ('A', 'N')
                                    
			--print @policy_expires_date

			if datediff(month, getdate(), @policy_expires_date) <= 3
				insert into #result_set (complex_id, complex_name, exhibitor_name, category_message, agreement_status, agreement_id,
				agreement_desc, agreement_start, agreement_end,  revenue_source, policy_id,
				rent_inclusion_start, rent_inclusion_end, policy_status, branch_code, processing_start_date, processing_end_date)
				values (@complex_id, @complex_name, @exhibitor_name, 'Complex Expires from all agreements within 3 months', '', 0,
				'', null, null,  '', 0, null, null, '', @branch_code, @processing_start_date, @processing_end_date)  

			select			@missing_periods = null
	
			select			@missing_periods = dbo.Concatenate(convert(varchar(20), end_date, 106)) 
			from			accounting_period
			cross join		complex
			where			complex.complex_id = @complex_id
			and				accounting_period.end_date between isnull(complex.opening_date, '1-jan-1900') and isnull(complex.closing_date, '31-dec-3000')
			and				accounting_period.end_date not in (	select distinct end_date
																from accounting_period
																inner join cinema_agreement_policy cap on accounting_period.end_date between isnull(cap.rent_inclusion_start, '1-jan-1900') and isnull(cap.rent_inclusion_end, '31-dec-3000')
																where cap.complex_id = @complex_id
																and policy_status_code in ('A', 'N')
																and	revenue_source = @revenue_source)
			and				accounting_period.end_date >= @current_period

			if len(@missing_periods) > 0
				insert into #result_set (complex_id, complex_name, exhibitor_name, category_message, agreement_status, agreement_id,
				agreement_desc, agreement_start, agreement_end,  revenue_source, policy_id,
				rent_inclusion_start, rent_inclusion_end, policy_status, branch_code, processing_start_date, processing_end_date)
				values (@complex_id, @complex_name, @exhibitor_name, 'Complex missing rent inclusion policy for these months: ' + @missing_periods, '', 0,
				'', null, null,  @revenue_source, 0, null, null, '', @branch_code, @processing_start_date, @processing_end_date)  


		end    /*END for 'Complex is Active' */ 

                        
		fetch complex_active_policy_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
		@close_date, @policy_id, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end  ,
		@processing_start_date, @processing_end_date, @revenue_source
	end /*END for while() - loop over active policies*/                              
           
	deallocate complex_active_policy_csr    
          
    if @complex_status = 'C' and @valid_policies > 0
    begin
        insert into #result_set (complex_id, complex_name, exhibitor_name, category_message, agreement_status, agreement_id,
                    agreement_desc, agreement_start, agreement_end, revenue_source, policy_id,
                    rent_inclusion_start, rent_inclusion_end, policy_status, branch_code, processing_start_date, processing_end_date)
            values (@complex_id, @complex_name, @exhibitor_name, 'Closed Complex Active on a Valid Agreement', @agreement_status, @cinema_agreement_id,
                    @agreement_desc, @agreement_start, @agreement_end,  @revenue_source, @policy_id,
                    @rent_inclusion_start, @rent_inclusion_end, @policy_status_code, @branch_code, @processing_start_date, @processing_end_date)   
    end
          
    
    /* Check if Active Complex has at least one active policy */
    if @complex_status = 'A' and @valid_policies = 0 
        insert into #result_set (complex_id, complex_name, exhibitor_name, category_message, agreement_status, agreement_id,
                agreement_desc, agreement_start, agreement_end, revenue_source, policy_id,
                rent_inclusion_start, rent_inclusion_end, policy_status, branch_code, processing_start_date, processing_end_date)
        values (@complex_id, @complex_name, @exhibitor_name, 'No Valid Policies for this Complex', '', 0,
            '', null, null,  '', 0, null, null, '', @branch_code, null, null)  
    
    fetch complex_csr into @complex_id, @complex_name, @branch_code, @exhibitor_id, @exhibitor_name, @complex_status
end
deallocate complex_csr



select distinct * from #result_set order by category_message, complex_name

return 0
GO
