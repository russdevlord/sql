/****** Object:  StoredProcedure [dbo].[p_cag_pre_eom_pol_overlap_chk]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_pre_eom_pol_overlap_chk]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_pre_eom_pol_overlap_chk]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Proc name:   p_cag_pre_eom_pol_overlap_chk
 * Author:      Victoria Tyshchenko
 * Date:        24/02/2004
 * Description: Checks for policies overlaps. @mode = 1
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Mar 25 2004 11:05:34  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   cag_pre_eom_pol_overlap_chk.sql  $
 *
*/ 

create PROC [dbo].[p_cag_pre_eom_pol_overlap_chk]	@mode integer, @cinema_agreement_id integer as
/*
 * @mode = 1 - Do all cinema-agreements
 * @mode = 2 - Do only specified Cinema Agreement
 */

declare	@error							integer,
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
        @revenue_source                char(1),
        @policy_status_code            char(1),
        @message                       char(255),
        @err_msg                       char(255),
        @revenue_desc                  char(15),
        @processing_start_date         datetime,
        @processing_end_date           datetime
        

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_pre_eom_pol_overlap_chk'
           


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
         cinema_agreement_policy.complex_id,
         processing_start_date,
         processing_end_date
    FROM cinema_agreement,   
         cinema_agreement_policy,
         cinema_revenue_source
   WHERE ( cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id ) 
     and  cinema_agreement_policy.policy_status_code in ('A', 'N')
     and  cinema_agreement_policy.revenue_source = cinema_Revenue_source.revenue_source
     and (( @mode = 1 )
     or  ( cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id and @mode = 2 ))
  order by cinema_agreement.cinema_agreement_id



/*
* Message_Type : 1 WARNING, -1 ERROR, 0 SUCCESS
*/
  open active_policy_csr
  fetch active_policy_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
        @close_date, @policy_id, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end, @revenue_desc, 
        @revenue_source, @complex_id, @processing_start_date, @processing_end_date

  while(@@fetch_status = 0)  
        begin   
             select @complex_name = complex_name from complex where complex_id = @complex_id

 			declare policy_overlap_csr cursor static for
		  	SELECT DISTINCT cinema_agreement.cinema_agreement_id,   
		         cinema_agreement.agreement_desc
		    FROM cinema_agreement,   
		         cinema_agreement_policy  
		   WHERE ( cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id )  
		         and complex_id = @complex_id and revenue_source = @revenue_source and policy_status_code in ( 'A', 'N' )
		         and not (policy_id = @policy_id and revenue_source = @revenue_source and complex_id = @complex_id 
		                  and policy_status_code in ('A', 'N') and cinema_agreement.cinema_agreement_id = @cinema_agreement_id ) and
		            (( isnull(@rent_inclusion_start, convert(datetime, '1980-01-01')) between isnull(rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(rent_inclusion_end, convert(datetime,'2100-01-01')) or
		              isNull(@rent_inclusion_end, convert(datetime,'2100-01-01')) between isnull(rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(rent_inclusion_end, convert(datetime,'2100-01-01')) 
		              )OR
		            ( isnull(rent_inclusion_start, convert(datetime, '1980-01-01')) between isnull(@rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(@rent_inclusion_end, convert(datetime,'2100-01-01')) or
		              isNull(rent_inclusion_end,   convert(datetime,'2100-01-01'))  between isnull(@rent_inclusion_start, convert(datetime, '1980-01-01')) and IsNull(@rent_inclusion_end, convert(datetime,'2100-01-01')) 
		             ))
		             AND
		             (( @processing_start_date between processing_start_date and IsNull(processing_end_date, convert(datetime,'2100-01-01')) or
		              isNull(@processing_end_date, @processing_start_date) between processing_start_date and IsNull(processing_end_date, convert(datetime,'2100-01-01')) 
		              ) OR
		             ( processing_start_date between @processing_start_date and IsNull(@processing_end_date, convert(datetime,'2100-01-01')) or
		              isNull(processing_end_date, processing_start_date) between @processing_start_date and IsNull(@processing_end_date, convert(datetime,'2100-01-01')) 
		             ))
              
             open policy_overlap_csr
             select @error = @@error
                 if @error != 0
                     goto error 
             fetch policy_overlap_csr into @cinema_agreement_id_overlap, @agreement_desc_overlap
              while(@@fetch_status = 0)
                     begin
                         select @message = 'AGREEMENT ' + convert(varchar(5), @cinema_agreement_id) + '::COMPLEX ' + rtrim(@complex_name) + '::REVENUE ' + rtrim(@revenue_desc) + '::POLICY ' 
                                + convert(varchar(3), @policy_id) + '   overlaps with policy in agreement ' 
                                + convert(varchar(6), @cinema_Agreement_id_overlap) + ' ' + rtrim(@Agreement_desc_overlap)
                         insert into #result_set ( cinema_agreement_id, agreement_desc, message_type, message )
                          values (@cinema_agreement_id, @agreement_desc, 1, @message) 
                          
                           select @error = @@error
                           if @error != 0
                               goto error 
 
                                                        
                          fetch policy_overlap_csr into @cinema_agreement_id, @agreement_desc
                                            
                       end
                                    
                 deallocate policy_overlap_csr
                 select @error = @@error
                 if @error != 0
                     goto error 
                               
                 fetch active_policy_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @agreement_start,   
                 @close_date, @policy_id, @policy_status_code, @rent_inclusion_start, @rent_inclusion_end, @revenue_desc, 
                 @revenue_source, @complex_id, @processing_start_date, @processing_end_date
   end                               
           
select distinct * from #result_set order by cinema_Agreement_id


deallocate active_policy_csr
return 0

error:
deallocate policy_overlap_csr
deallocate active_policy_csr
if @error >= 50000 
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end
--else
--    raiserror ( 'Error', 16, 1) 

return -100
GO
