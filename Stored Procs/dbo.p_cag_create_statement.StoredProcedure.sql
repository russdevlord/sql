/****** Object:  StoredProcedure [dbo].[p_cag_create_statement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_statement]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_statement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_statement]   @cinema_agreement_id    int,
                                      @accounting_period      datetime

--with recompile 
as
/* Proc name:   p_cag_create_statement
 * Author:      Grant Carlson
 * Date:        18/11/2003
 * Description: Creates statement for selected accounting period
 *
 * Changes:
*/                              

declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_statement'

declare @error        		 int,
        @err_msg             varchar(150),
        --@error                  int,
        @last_statement_no   int,
        @next_statement_no   int,
        @opening_balance     money,
        @payments            money,
        @entitlements        money,
        @closing_balance     money,
        @address_xref_id     int,
        @tran_status_processed  char(1),
        @tran_status_pending  char(1),
        @tran_status_cancelled char(1)
        
        
exec p_audit_proc @proc_name,'start'

select  @error = 0,
        @tran_status_processed = 'P',
        @tran_status_pending = 'D',
        @tran_status_cancelled = 'X'
        


begin transaction


    select  @last_statement_no = statement_no,
            @opening_balance = closing_balance
    from    cinema_agreement_statement
    where   cinema_agreement_id = @cinema_agreement_id
    and     statement_no = (select max(statement_no) from cinema_agreement_statement where cinema_agreement_id = @cinema_agreement_id)
    if @@rowcount = 0 or @last_statement_no = null -- presume this is the first statement
    begin
        select  @last_statement_no = 0,
                @opening_balance = 0.0
    end

    select  @entitlements = isnull(sum(cat.nett_amount),0)
    from    cinema_agreement_transaction cat, transaction_type tt
    where   cat.cinema_agreement_id = @cinema_agreement_id
    and     cat.statement_no is null
    and     cat.show_on_statement = 'Y'
    and     ((cat.transaction_status_code = @tran_status_processed OR cat.transaction_status_code = @tran_status_pending))
    and     cat.process_period = @accounting_period
    and     cat.trantype_id = tt.trantype_id
    and     tt.tran_category_code = 'E'

    select  @payments = isnull(sum(cat.nett_amount),0)
    from    cinema_agreement_transaction cat, transaction_type tt
    where   cat.cinema_agreement_id = @cinema_agreement_id
    and     cat.statement_no is null
    and     cat.show_on_statement = 'Y'
    and     cat.transaction_status_code = @tran_status_processed
    and     cat.process_period = @accounting_period
    and     cat.trantype_id = tt.trantype_id
    and     tt.tran_category_code = 'P'

    select  @closing_balance = @opening_balance + @entitlements + @payments
    select  @next_statement_no = @last_statement_no + 1

    select  @address_xref_id = address_xref.address_xref_id
    from    address_xref, address
    where   address_xref.address_owner_pk_int = @cinema_agreement_id
    and     address_xref.address_category_code = 'AAP' -- cheque mailing address
    and     address_xref.address_type_code = 'CAG' -- cinema agreement
    and     address_xref.address_id = address.address_id
    and     address_xref.version_no = address.version_no
    and     address.active = 'Y'
    if @@rowcount = 0 or @address_xref_id is null
    begin
        select @err_msg = 'Failed to get valid address_xref_id'
        goto rollbackerror
    end


    insert dbo.cinema_agreement_statement 
            (cinema_agreement_id,
             statement_no,
             accounting_period,
             opening_balance,
             payments,
             entitlements,
             closing_balance,
             address_xref_id)
    values ( @cinema_agreement_id,
             @next_statement_no,
             @accounting_period,
             @opening_balance,
             @payments,
             @entitlements,
             @closing_balance,
             @address_xref_id)
    select @error = @@error
    if @error != 0
        goto rollbackerror

    update  cinema_agreement_transaction
    set     statement_no = @next_statement_no
    where   cinema_agreement_id = @cinema_agreement_id
    and     statement_no is null
    and     process_period = @accounting_period
    and     show_on_statement = 'Y'
    and     ((transaction_status_code = @tran_status_processed) OR (transaction_status_code = @tran_status_pending))
    and     trantype_id in (select trantype_id from transaction_type where tran_category_code = 'E')
    select @error = @@error
    if @error != 0
        goto rollbackerror

    update  cinema_agreement_transaction
    set     statement_no = @next_statement_no
    where   cinema_agreement_id = @cinema_agreement_id
    and     statement_no is null
    and     process_period = @accounting_period
    and     show_on_statement = 'Y'
    and     transaction_status_code = @tran_status_processed
    and     trantype_id in (select trantype_id from transaction_type where tran_category_code = 'P')
    select @error = @@error
    if @error != 0
        goto rollbackerror

    /* Still want to show Excess rent details when there has been no payment and they have been cancelled */
    /* Only Excess rent transactions shoud have a cancelled status with the show_on_statement flag Y */
    update  cinema_agreement_transaction
    set     statement_no = @next_statement_no
    where   cinema_agreement_id = @cinema_agreement_id
    and     statement_no is null
    and     process_period = @accounting_period
    and     show_on_statement = 'Y'
    and     transaction_status_code = @tran_status_cancelled
    and     trantype_id in (select trantype_id from transaction_type where tran_category_code in ('E','P'))
    select @error = @@error
    if @error != 0
        goto rollbackerror



commit transaction

exec p_audit_proc @proc_name,'end'

return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end

    return -1
GO
