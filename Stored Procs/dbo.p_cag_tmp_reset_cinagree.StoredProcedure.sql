/****** Object:  StoredProcedure [dbo].[p_cag_tmp_reset_cinagree]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_tmp_reset_cinagree]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_tmp_reset_cinagree]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_tmp_reset_cinagree]   @accounting_period      datetime,
                                        @cinema_agreement_id    int = null,
                                        @delete_revenue char(1) = 'N',
                                        @next_acct_period datetime
                                       
                                   
                                   

as
/* Proc name:   p_cag_tmp_reset_cinagree
 * Author:      Grant Carlson
 * Date:        10/11/2003
 * Description: Creates a payment transaction record and also a cinema_rent_payment record
 *              
 *
 * Changes:
*/                              

declare @error        				int,
        @err_msg                    varchar(150)


begin transaction

    if @delete_revenue = 'Y'
    begin
        delete cinema_agreement_revenue 
        where   (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
        and     (release_period = @accounting_period OR accounting_period = @accounting_period)
        if @@error != 0
        begin
            rollback transaction
            return -1
        end
    end
    else
    begin
        update cinema_agreement_revenue set cag_entitlement_id = null, release_period = null 
        where release_period = @accounting_period
        and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
        if @@error != 0
        begin
            rollback transaction
            return -1
        end
    end

    delete cinema_agreement_entitlement 
    where accounting_period = @accounting_period
    and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
    and revenue_source <> 'A' --manual adjustment
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

    update cinema_agreement_entitlement set tran_id = null where tran_id in
    (select tran_id from cinema_agreement_transaction 
     where process_period = @accounting_period)
    and revenue_source <> 'A' --manual adjustment
    if @@error != 0
    begin
        rollback transaction
        return -1
    end


    delete cinema_rent_payment_allocation 
    where entitlement_tran_id in 
        (select tran_id from cinema_agreement_transaction 
         where process_period = @accounting_period
         and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null))
    and accounting_period < entry_date
    if @@error != 0
    begin
        rollback transaction
        return -1
    end


    delete cinema_rent_payment 
    where tran_id in 
        (select tran_id from cinema_agreement_transaction 
         where process_period = @accounting_period
         and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null))
    and tran_id not in     
        (select tran_id from cinema_agreement_transaction 
         where (accounting_period= @accounting_period and tran_date <> @accounting_period and tran_date < @accounting_period)
         and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null))
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

    delete cinema_agreement_transaction 
    where process_period = @accounting_period
    and tran_id not in     
        (select tran_id from cinema_agreement_transaction 
         where (accounting_period= @accounting_period and tran_date <> @accounting_period and tran_date < @accounting_period)
         and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null))
    and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

    update cinema_agreement 
    set next_standard_payment_due = @accounting_period 
--    where ((cinema_agreement_id = @cinema_agreement_id) OR ((@cinema_agreement_id is null) and (cinema_agreement_id not in (1,158,247))))
    where (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null) and next_standard_payment_due = @next_acct_period
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

    delete cinema_agreement_statement 
    where accounting_period = @accounting_period
    and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

commit transaction
GO
