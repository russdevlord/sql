/****** Object:  StoredProcedure [dbo].[p_accpac_present_rent_payments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_accpac_present_rent_payments]
GO
/****** Object:  StoredProcedure [dbo].[p_accpac_present_rent_payments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_accpac_present_rent_payments]
--with recompile 
as

/* Proc name:   p_accpac_present_rent_payments
 * Author:      Victoria Tyshchenko
 * Date:        18/11/2004
 * Description: Synchronises Cinvendo rent payment presented statuses with AccPac
 *
 * Changes:
*/                              
BEGIN
set nocount on

declare @proc_name              varchar(30),
        @error                  int,
        @err_msg                varchar(150),
        --@error                     int,
        @status_awaiting        char(1),
        @status_failed          char(1),
        @interface_status_new   char(1)

       
select  @status_awaiting = 'A',
        @status_failed = 'F',
        @interface_status_new = 'N'


select @proc_name = 'p_accpac_present_rent_payments'

--exec @error = p_dw_start_process @proc_name
--if @error != 0
--	goto error



begin transaction

    UPDATE  cinema_rent_payment
    SET     payment_presented = 'Y', 
            presented_date = accpac_integration..v_accpac_banking_details.date_cleared
    FROM    accpac_integration..v_accpac_banking_details 
    WHERE   accpac_integration..v_accpac_banking_details.tran_id =  cinema_rent_payment.tran_id
    AND     cinema_rent_payment.payment_presented = 'N'
    AND     accpac_integration..v_accpac_banking_details.cleared = 1

    if @@error != 0
            goto error


    UPDATE  cinema_rent_payment
    SET     payment_presented = 'N', 
            presented_date = Null
    FROM    accpac_integration..v_accpac_banking_details 
    WHERE   accpac_integration..v_accpac_banking_details.tran_id =  cinema_rent_payment.tran_id
    AND     cinema_rent_payment.payment_presented = 'Y'
    AND     accpac_integration..v_accpac_banking_details.cleared = 0

    if @@error != 0
            goto error

commit transaction


--exec @error = p_dw_exit_process @proc_name

return 0

error:
    rollback transaction
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

--    exec @error = p_dw_exit_process @proc_name,  @status_failed


    return -1

END
GO
