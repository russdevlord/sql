/****** Object:  StoredProcedure [dbo].[p_pre_eom_policies_overlap_chk]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pre_eom_policies_overlap_chk]
GO
/****** Object:  StoredProcedure [dbo].[p_pre_eom_policies_overlap_chk]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_pre_eom_policies_overlap_chk]	@mode integer, @cinema_agreement_id integer as

set nocount on 
declare	@error								integer,
		@complex_id						integer,
		@cinema_agreement_id_overlap	integer,
		@rent_inclusion_start			datetime,
		@rent_inclusion_end				datetime,
		@complex_name					varchar(50),
		@agreement_desc					varchar(50),
		@agreement_desc_OVERLAP			varchar(50),
		@agreement_start				datetime,
		@agreement_end					datetime,
        @close_date                     datetime,
		@agreement_status    		   char(1),
		@branch_code					char(2),
		@exhibitor_id				   integer,
		@exhibitor_name		    	   varchar(50),
        @complex_closing_date          datetime,
        @policy_id                     integer,
        @policy_id_overlap             integer,
        @complex_status                char(1),
        @cnt                           integer,
        @policy_expires_date           datetime,
        @revenue_source                char(1),
        @policy_status_code            char(1),
        @message                       char(255),
        @err_msg                       char(255),
        @revenue_desc                 char(30)

declare @proc_name varchar(30)
select  @proc_name = 'p_pre_eom_policies_overlap_chk'
           

create table #result_set
( cinema_agreement_id           integer         null,
  complex_id                    integer         null,
  revenue_source                char(1)         null,
  policy_id                     char(1)         null,
  agreement_desc			    varchar(60)		null,
  message_type                  int              null,
  message                       varchar(255)    null  
 )


 declare active_policy_csr cursor static for
  SELECT DISTINCT cinema_agreement.cinema_agreement_id,   
         cinema_agreement.agreement_desc,   
         cinema_agreement.agreement_status,   
         cinema_agreement.agreement_start,   
         cinema_agreement.close_date,   
         cinema_agreement_policy.policy_id,   
         cinema_agreement_policy.policy_status_code,   
         cinema_agreement_policy.rent_inclusion_start,   
         cinema_agreement_policy.rent_inclusion_end,
         cinema_revenue_source.revenue_desc,
         cinema_revenue_source.revenue_source,         
         cinema_agreement_policy.complex_id
    FROM cinema_agreement,   
         cinema_agreement_policy,
         cinema_revenue_source
   WHERE ( cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id ) 
     and  cinema_agreement_policy.policy_status_code = 'A'
     and  cinema_agreement_policy.revenue_source = cinema_Revenue_source.revenue_source
     and (( @mode = 1 )
     or  ( cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id and @mode = 2 ))
 -- order by cinema_agreement_policy.cinema_agreement_id

  open active_policy_csr
  fetch active_policy_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
        @close_date, @policy_id, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end, @revenue_desc, @revenue_source, @complex_id

  while(@@fetch_status = 0)  
        begin    
			declare policy_overlap_csr cursor static for
			  SELECT DISTINCT cinema_agreement.cinema_agreement_id,   
			         cinema_agreement.agreement_desc,   
			         cinema_agreement.agreement_status,   
			         cinema_agreement.agreement_start,   
			         cinema_agreement.close_date,   
			         cinema_agreement_policy.policy_id,   
			         cinema_agreement_policy.policy_status_code,   
			         cinema_agreement_policy.rent_inclusion_start,   
			         cinema_agreement_policy.rent_inclusion_end  
			    FROM cinema_agreement,   
			         cinema_agreement_policy  
			   WHERE ( cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id )  
			         and complex_id = @complex_id and revenue_source = @revenue_source and policy_status_code = 'A' 
			         and not (policy_id = @policy_id and revenue_source = @revenue_source and complex_id = @complex_id 
			                  and policy_status_code = 'A' and cinema_agreement.cinema_agreement_id = @cinema_agreement_id )
			         and ( rent_inclusion_start between @rent_inclusion_start and IsNull(@rent_inclusion_end, convert(datetime,'2200-01-01')) 
			              or isNull(rent_inclusion_end, convert(datetime,'2200-01-01')) between @rent_inclusion_start and IsNull(@rent_inclusion_end, convert(datetime,'2200-01-01')) )
         
             open policy_overlap_csr
             fetch policy_overlap_csr into @cinema_agreement_id_overlap, @agreement_desc_overlap, @agreement_status, @agreement_start,   
                   @close_date, @policy_id_overlap, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end  
              while(@@fetch_status = 0)
                     begin
                         select @message = 'COMPLEX ' + @complex_name + ' REVENUE ' + @revenue_desc + ' POLICY ' 
                                + convert(varchar(3), @policy_id) + ' overlaps with policy in agreement ' 
                                + convert(varchar(6), @cinema_Agreement_id_overlap) + ' ' + @Agreement_desc_overlap
                         insert into #result_set ( cinema_agreement_id, agreement_desc, message_type, message )
                          values (@cinema_agreement_id, @agreement_desc, 1, @message) 
                          
                           select @error = @@error
                           if @error != 0
                               goto error 
 
                                                        
                          fetch policy_overlap_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
                                @close_date, @policy_id_overlap, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end  
                                            
                       end
                                    
                 close policy_overlap_csr
                 deallocate policy_overlap_csr
                 select @error = @@error
                 if @error != 0
                     goto error 
                               
                 fetch active_policy_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
                 @close_date, @policy_id, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end, @revenue_desc, @revenue_source, @complex_id  
   end                               
           


select distinct #result_set.cinema_agreement_id, #result_set.complex_id, #result_set.revenue_source, #result_set.policy_id, #result_set.agreement_desc, #result_set.message_type, #result_set.message from #result_set order by cinema_Agreement_id

return 0
close active_policy_csr
deallocate active_policy_csr


error:
close active_policy_csr
deallocate active_policy_csr

if @error >= 50000 
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end
GO
