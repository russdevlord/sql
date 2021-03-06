/****** Object:  StoredProcedure [dbo].[p_cag_pre_eom_termn_yet_active]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_pre_eom_termn_yet_active]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_pre_eom_termn_yet_active]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Proc name:   p_cag_pre_eom_termn_yet_active
 * Author:      Victoria Tyshchenko
 * Date:        24/02/2004
 * Description: Checks if there are any Active agreements that were Terminated before accounting_period
 *              and have not 0 outstanding balance
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Mar 25 2004 11:05:22  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.2  $
 * $Workfile:   cag_pre_eom_term_yet_active.sql  $
 *
*/ 

create PROC [dbo].[p_cag_pre_eom_termn_yet_active]	@mode integer, 
                                            @cinema_agreement_id integer,
                                            @accounting_period datetime as
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
        @termination_date               datetime,
        @temp                           varchar (100)

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_pre_eom_termn_yet_active'
           



create table #result_set
( cinema_agreement_id           integer         null,
  agreement_desc			    varchar(60)		null,
  message_type                  int              null,
  message                       varchar(255)    null  
 )


 declare active_terminted_agree_csr cursor static for
  SELECT cinema_agreement.cinema_agreement_id,   
         cinema_agreement.agreement_desc,   
         cinema_agreement.agreement_status,   
         cinema_agreement.termination_date
    FROM cinema_agreement
   WHERE termination_date is not null 
     and termination_date < @accounting_period
     and agreement_status = 'A'
     and ( @mode = 1 or (@mode = 2 and cinema_Agreement_id = @cinema_Agreement_id) )
/*
* Message_Type : 1 WARNING, -1 ERROR, 0 SUCCESS
*/
  open active_terminted_agree_csr
  fetch active_terminted_agree_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @termination_date

  while(@@fetch_status = 0)  
        begin   
        
           select  @last_statement_no = statement_no,
                   @closing_balance = closing_balance
            from   cinema_agreement_statement  
            where  cinema_agreement_id = @cinema_agreement_id
            and    statement_no = (select max(statement_no) from cinema_agreement_statement where cinema_agreement_id = @cinema_agreement_id)

            if @@rowcount = 0 or isnull(@last_statement_no,0) = 0 -- presume this is the first statement
                begin
                    select  @last_statement_no = 0,
                            @closing_balance = 0.0
               end

            if @closing_balance != 0 
                begin
                    select @message = 'Agreement was TERMINATED on ' + convert(varchar(12), @termination_date, 106) 
                            + ' yet has status ACTIVE with outstanding balance of ' + convert(varchar(8), @closing_balance)
                    
                    insert into #result_set ( cinema_agreement_id, agreement_desc, message_type, message )
                    values (@cinema_agreement_id, @agreement_desc, -1, @message) 
                          
                    select @error = @@error
                    if @error != 0
                       goto error 
                end 
 
             fetch active_terminted_agree_csr into @cinema_agreement_id, @agreement_desc, @agreement_status, @termination_date
         end
                                   
           
select distinct * from #result_set order by cinema_Agreement_id

deallocate active_terminted_agree_csr
return 0

error:
deallocate active_terminted_agree_csr
if @error >= 50000 
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end
--else
--    raiserror ( 'Error', 16, 1) 

return -100
GO
