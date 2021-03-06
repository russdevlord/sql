/****** Object:  StoredProcedure [dbo].[p_cag_pre_eom_cag_address_chk]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_pre_eom_cag_address_chk]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_pre_eom_cag_address_chk]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Proc name:   p_cag_pre_eom_cag_address_chk
 * Author:      Victoria Tyshchenko
 * Date:        24/02/2004
 * Description: Checks if agreement(s) have cheque e-mailing address attached to it
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Aug 02 2004 16:10:20  $ 
 * $Author:   gcarlson  $ 
 * $Revision:   1.2  $
 * $Workfile:   cag_pre_eom_cag_address_chk.sql  $
 *
*/ 

create PROC [dbo].[p_cag_pre_eom_cag_address_chk]	@mode integer, 
                                            @cinema_agreement_id integer as
/*
 * @mode = 1 - Do all cinema-agreements
 * @mode = 2 - Do only specified Cinema Agreement
 */

declare	@error							integer,
        @err_msg                        char(255),
		@agreement_desc					varchar(50),
        @agreement_status               char(1),
        @last_statement_no              integer,
        @closing_balance                money,
        @message                        varchar(255),
        @termination_date               datetime
        

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_pre_eom_cag_address_chk'

create table #result_set
( cinema_agreement_id           integer         null,
  agreement_desc			    varchar(60)		null,
  message_type                  int              null,
  message                       varchar(255)    null  
 )
           
 declare agreement_addr_check_csr cursor static for
  SELECT cinema_agreement.cinema_agreement_id,   
         cinema_agreement.agreement_desc
    FROM cinema_agreement
   WHERE agreement_status = 'A'
     and ( @mode = 1 or (@mode = 2 and cinema_Agreement_id = @cinema_Agreement_id) )
     AND currency_code != 'NZD' -- ********* TEMP TO BE REMOVED FOR PROCESSING NZ ********
         
/*
* Message_Type : 1 WARNING, -1 ERROR, 0 SUCCESS
*/
  open agreement_addr_check_csr
  fetch agreement_addr_check_csr into @cinema_agreement_id, @agreement_desc

  while(@@fetch_status = 0)  
        begin   
        
           if not exists(select address_xref_id 
                           from address_xref 
                           where address_owner_pk_int = @cinema_agreement_id
                             and address_type_code = 'CAG' 
                             and address_category_code = 'AAP')
                begin
                    select @message = 'Agreement Cheque/Statement Mailing Address is not specified'
                    
                    insert into #result_set ( cinema_agreement_id, agreement_desc, message_type, message )
                    values (@cinema_agreement_id, @agreement_desc, -1, @message) 
                          
                    select @error = @@error
                    if @error != 0
                       goto error 
                end 
 
             fetch agreement_addr_check_csr into @cinema_agreement_id, @agreement_desc
         end
                                   
           
select distinct * from #result_set order by cinema_Agreement_id

deallocate agreement_addr_check_csr
return 0

error:
deallocate agreement_addr_check_csr
if @error <> 0
begin
	select @err_msg = @proc_name + ': ' + @err_msg
	raiserror (@err_msg, 16, 1)
end

return -100
GO
