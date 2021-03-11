USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_tmp_check_reset]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_tmp_check_reset]   @accounting_period      datetime,
                                        @cinema_agreement_id    int = null,
                                        @delete_revenue char(1) = 'N'
                                       
                                   
                                   

as
/* Proc name:   p_cag_tmp_check_reset
 * Author:      Grant Carlson
 * Date:        10/11/2003
 * Description: 
 *              
 *
 * Changes:
*/                              

declare @error        				int,
        @err_msg                    varchar(150)


begin transaction

    select 'Checking agreement ' + convert(varchar(6),@cinema_agreement_id)

    if @delete_revenue = 'Y'
    begin
        select * from cinema_agreement_revenue 
        where   (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
        and     (release_period = @accounting_period OR accounting_period = @accounting_period)
        if @@error != 0
        begin
            rollback transaction
            return -1
        end
    end

    select * from cinema_agreement_entitlement 
    where accounting_period = @accounting_period
    and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

    select * from cinema_rent_payment_allocation 
    where entitlement_tran_id in 
        (select tran_id from cinema_agreement_transaction 
         where process_period = @accounting_period
         and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null))
    if @@error != 0
    begin
        rollback transaction
        return -1
    end


    select * from cinema_rent_payment 
    where tran_id in 
        (select tran_id from cinema_agreement_transaction 
         where process_period = @accounting_period
         and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null))
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

    select * from cinema_agreement_transaction 
    where process_period = @accounting_period
    and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
    if @@error != 0
    begin
        rollback transaction
        return -1
    end


    select * from cinema_agreement_statement 
    where accounting_period = @accounting_period
    and (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
    if @@error != 0
    begin
        rollback transaction
        return -1
    end

commit transaction
GO
