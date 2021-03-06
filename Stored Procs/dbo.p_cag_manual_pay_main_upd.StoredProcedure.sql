/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_main_upd]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_manual_pay_main_upd]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_main_upd]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_manual_pay_main_upd]  @cinema_agreement_id int,
                                       @accounting_period   datetime,
                                       @payment_tran_id     int,
                                       @rent_payment_id     int,                                    
                                       @process_period      datetime,
                                       @tran_desc           varchar(255),
                                       @tran_subdesc        varchar(255),
                                       @show_on_statement   char(1),
                                       @payment_status_code char(1),
                                       @payment_method_code char(1),
                                       @payment_date        datetime,
                                       @payee               varchar(50),
                                       @payment_desc        varchar(255),
                                       @acct_bsb            char(6),
                                       @acct_number         varchar(20),
                                       @acct_ref            varchar(30),
                                       @payment_no          int,
                                       @presented_date      datetime
as
                              
/* Proc name:   p_cag_manual_pay_main_upd
 * Author:      Grant Carlson
 * Date:        17/3/2004
 * Description: Used for creating manual payments.
 *
 * Part of a 3-phase creation process:
 *
 * p_cag_manual_pay_main_ins:  Creates Entitlement Transaction record,
 *                              passes back entitlement tran_id
 * p_cag_manual_pay_main_upd:  Used to update existing payments
 *               
 * p_cag_manual_pay_alloc_upd: When first called (INS) creates entitlement records adds FK
 *                              using entitlement tran_id from p_cag_manual_pay_main_ins.
 *                              UPD mode updates entitlement records
 *
 * p_cag_manual_pay_alloc_del: Deletes / updates entitlement records and deletes allocation records
 *               
 * p_cag_manual_pay_rent_pay:  Creates rent payment records  
 *
 * Changes:
 *
*/                              

declare @error        				int,
        @err_msg                    varchar(150)


begin transaction

    UPDATE  cinema_agreement_transaction
    SET 	accounting_period = @accounting_period,
		    process_period = @process_period,
		    tran_desc = @tran_desc,
		    tran_subdesc = @tran_subdesc,
		    show_on_statement = @show_on_statement
    WHERE   tran_id = @payment_tran_id
    select @error = @@error
    if (@error !=0)
          goto error

    UPDATE dbo.cinema_rent_payment
    SET 	payment_status_code = @payment_status_code,
		    payment_method_code = @payment_method_code,
		    payment_date = @payment_date,
		    payee = @payee,
		    payment_desc = @payment_desc,
		    acct_bsb = @acct_bsb,
		    acct_number = @acct_number,
		    acct_ref = @acct_ref,
		    payment_no = @payment_no,
		    presented_date = @presented_date
    WHERE   rent_payment_id = @rent_payment_id

    select @error = @@error
    if (@error !=0)
           goto error

commit transaction

return 0

error:

    if @error >= 50000
        raiserror (@err_msg, 16, 1)
        
    rollback transaction
    return -1
GO
