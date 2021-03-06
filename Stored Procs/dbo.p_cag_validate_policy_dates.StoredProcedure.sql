/****** Object:  StoredProcedure [dbo].[p_cag_validate_policy_dates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_validate_policy_dates]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_validate_policy_dates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_validate_policy_dates] @arg_cinema_agreement_id int,
                                        @arg_complex_id		     int,
                                        @arg_revenue_source	     char,
                                        @arg_start_date		     datetime,
                                        @arg_end_date            datetime,
                                        @arg_policy_id           int,
                                        @arg_active_prd_start    datetime,
                                        @arg_active_prd_end      datetime
/*
* @arg_policy_id - Old policy ID -  most of the time = 0
* useful when there is a need to update "Active" policy 
* (instead of creating a new policy - updates existing)
*/

as

declare @error     		int,
        @message        varchar(255),
        @agreement_desc varchar(50),
        @policy_id      int,
        @agreement_id   int,
        @agreement_start datetime,
        @agreement_end   datetime,
        @ll_ret         int,
		@csr_1_open			char(1),
		@csr_2_open			char(1)


select 		@csr_1_open = 'N'
select 		@csr_2_open = 'N'


select 		@ll_ret = 0
select 		@message = ''

select 		@agreement_start = agreement_start,
       		@agreement_end = close_date
from   		cinema_agreement
where  		cinema_agreement_id = @arg_cinema_agreement_id

if @@error != 0
begin
    raiserror ('p_cag_validate_policy_dates: SELECT error', 16, 1)
    select @ll_ret = 0
    GOTO PROC_END
end

select 		@agreement_end = IsNull(@agreement_end, convert(datetime,'2100-01-01'))

/*
* Check if there is any date overlap with policies within the same agreement
* if it is a policy modification process then the 'source' policy status has been already changed to 'Dead' (uncommited)
*/
declare 	cur_find_overlap_in_the_agr cursor static for                               
select  	ca.cinema_agreement_id, policy_id, agreement_desc
from    	cinema_agreement_policy policy, cinema_agreement ca
where   	policy.cinema_agreement_id = ca.cinema_agreement_id
and			policy.cinema_agreement_id = @arg_cinema_agreement_id
and			policy.policy_id <> @arg_policy_id
and			policy.policy_status_code in ('A', 'N') 
and			policy.complex_id = @arg_complex_id 
and			policy.revenue_source = @arg_revenue_source 
and			((isnull(@arg_start_date, convert(datetime, '1980-01-01')) between isnull(policy.rent_inclusion_start, convert(datetime, '1980-01-01')) and isNull(policy.rent_inclusion_end, convert(datetime,'2100-01-01')) 
or			isNull(@arg_end_date, convert(datetime,'2100-01-01')) between isnull(policy.rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(policy.rent_inclusion_end, convert(datetime,'2100-01-01')))
OR			(isnull(policy.rent_inclusion_start, convert(datetime, '1980-01-01')) between isnull(@arg_start_date, convert(datetime, '1980-01-01')) and IsNull(@arg_end_date, convert(datetime,'2100-01-01')) 
or			isNull(policy.rent_inclusion_end,   convert(datetime,'2100-01-01'))  between isnull(@arg_start_date, convert(datetime, '1980-01-01')) and IsNull(@arg_end_date, convert(datetime,'2100-01-01'))))
AND			(( @arg_active_prd_start between policy.processing_start_date and IsNull(policy.processing_end_date, convert(datetime,'2100-01-01')) 
or			isNull(@arg_active_prd_end, @arg_active_prd_start) between policy.processing_start_date and IsNull(policy.processing_end_date, convert(datetime,'2100-01-01')) )
OR			(processing_start_date between @arg_active_prd_start and IsNull(@arg_active_prd_end, convert(datetime,'2100-01-01')) 
or			isNull(processing_end_date, processing_start_date) between @arg_active_prd_start and IsNull(@arg_active_prd_end, convert(datetime,'2100-01-01'))))
for 		read only

/*
* Check if there is any date overlap with policies within the same agreement
*/

open cur_find_overlap_in_the_agr
if @@error != 0
begin
    raiserror ('p_cag_validate_policy_dates: OPEN CURSOR error', 16, 1)
    select @ll_ret = -100
    GOTO PROC_END
end
select @csr_1_open = 'Y'
fetch cur_find_overlap_in_the_agr into @agreement_id, @policy_id, @agreement_desc
if @@fetch_status = 0
begin   
    select @error = -1, 
           @message = 'Policy ACTIVE PERIODS OVERLAP with complex Policy ' 
                      + convert(varchar(4), @policy_id) +  ' dates IN THE SAME AGREEMENT ' + convert(varchar(5),@agreement_id) + ' (' + @agreement_desc + ')'
    GOTO PROC_END                          
end
else
begin
    select @error = 0, @message = ' ' 
end

/*
* Check if there is any date overlap with policies from the other agreements
* if it is a policy modification process then the 'source' policy status has been already changed to 'Dead' (uncommited)
*/
declare 	cur_find_overlap cursor static for                               
select  	ca.cinema_agreement_id, policy_id, agreement_desc
from    	cinema_agreement_policy policy, cinema_agreement ca
where   	policy.cinema_agreement_id = ca.cinema_agreement_id 
and			policy.policy_status_code in ('A', 'N') 
and			policy.cinema_agreement_id <> @arg_cinema_agreement_id  
and			policy.complex_id = @arg_complex_id 
and			policy.revenue_source = @arg_revenue_source 
and			((isnull(@arg_start_date, convert(datetime, '1980-01-01')) between isnull(policy.rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(policy.rent_inclusion_end, convert(datetime,'2100-01-01')) 
or			isNull(@arg_end_date, convert(datetime,'2100-01-01')) between isnull(policy.rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(policy.rent_inclusion_end, convert(datetime,'2100-01-01')))
OR			(isnull(policy.rent_inclusion_start, convert(datetime, '1980-01-01')) between isnull(@arg_start_date, convert(datetime, '1980-01-01')) and IsNull(@arg_end_date, convert(datetime,'2100-01-01')) 
or			isNull(policy.rent_inclusion_end,   convert(datetime,'2100-01-01'))  between isnull(@arg_start_date, convert(datetime, '1980-01-01')) and IsNull(@arg_end_date, convert(datetime,'2100-01-01')) ))
AND			(( @arg_active_prd_start between policy.processing_start_date and IsNull(policy.processing_end_date, convert(datetime,'2100-01-01')) 
or			isNull(@arg_active_prd_end, @arg_active_prd_start) between policy.processing_start_date and IsNull(policy.processing_end_date, convert(datetime,'2100-01-01'))) 
OR			( processing_start_date between @arg_active_prd_start and IsNull(@arg_active_prd_end, convert(datetime,'2100-01-01')) 
or			isNull(processing_end_date, processing_start_date) between @arg_active_prd_start and IsNull(@arg_active_prd_end, convert(datetime,'2100-01-01')) ))
for 		read only

/*
* Check if there is any date overlap with policies from the other agreements
*/
open cur_find_overlap
if @@error != 0
begin
    raiserror ('p_cag_validate_policy_dates: OPEN CURSOR error', 16, 1)
    select @ll_ret = -100
    GOTO PROC_END
end
select @csr_2_open = 'Y'
fetch cur_find_overlap into @agreement_id, @policy_id, @agreement_desc
if @@fetch_status = 0
begin   
    select @error = 1, 
           @message = 'Policy ACTIVE PERIODS OVERLAP with complex Policy ' 
                      + convert(varchar(4), @policy_id) +  ' dates in agreement ' + convert(varchar(5),@agreement_id) + ' (' + @agreement_desc + '). '
end
else
begin
    select @error = 0, @message = ' ' 
end

PROC_END:
if @csr_1_open = 'Y'
	deallocate cur_find_overlap_in_the_agr    
if @csr_2_open = 'Y'
	deallocate cur_find_overlap    

select @error, @message

return @ll_ret
GO
