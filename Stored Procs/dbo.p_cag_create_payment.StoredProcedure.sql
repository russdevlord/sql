/****** Object:  StoredProcedure [dbo].[p_cag_create_payment]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_payment]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_payment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_payment]   @cinema_agreement_id    int,
                                   @accounting_period      datetime,
                                   @process_period      datetime,
                                   @trantype_id            int,
                                   @currency_code       char(3),
                                   @tran_desc           varchar(255),
                                   @tran_subdesc        varchar(255),
                                   @tran_date           datetime,
                                   @nett_amount         money,
                                   @gst_rate            numeric(6,4),
                                   @gst_amount          money,
                                   @gross_amount        money,
                                   @show_on_statement   char(1),
                                   @payment_type_code   char(1),
                                   @payment_status_code char(1),
                                   @payment_method_code char(1),
                                   @payment_date        datetime,
                                   @payee               varchar(50),
                                   @payment_desc        varchar(255),
                                   @acct_bsb            char(6),
                                   @acct_number         varchar(20),
                                   @acct_ref            varchar(30),
                                   @payment_no          int,
                                   @payment_presented   char(1),
                                   @creation_date       datetime,
                                   @transaction_status  char(1) = 'P',
                                   @rent_payment_id     int = null OUTPUT,
                                   @payment_tran_id     int = null OUTPUT
                                   
                                   

as
/* Proc name:   p_cag_create_payment
 * Author:      Grant Carlson
 * Date:        10/11/2003
 * Description: Creates a payment transaction record and also a cinema_rent_payment record
 *              
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_payment'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @tran_status_cancelled          char(1)
        

exec p_audit_proc @proc_name,'start'

select  @error = 0,
        @tran_status_cancelled = 'X'

if @trantype_id is null -- null if called from PB client for manual payment
    select  @trantype_id = isnull(trantype_id,0)
    from    transaction_type
    where   trantype_code = 'CAGMP' -- manual payment

if @accounting_period is null
    select  @accounting_period = min(end_date)
    from    accounting_period
    where   status = 'O'

begin transaction

    if @nett_amount > 0 -- payments must be -ve, calling procs ensure that -ve payments don't come through here
        select @nett_amount = -1.0 * @nett_amount

    -- Create payment transaction
    exec @error = p_cag_cinagree_trans_ins     @cinema_agreement_id,
                                            @trantype_id,
                                            @accounting_period,
                                            @process_period,
                                            @tran_date,
                                            'Y',
                                            @currency_code,
                                            @nett_amount,
                                            null,
                                            null,
                                            null,
                                            @tran_desc,
                                            @tran_subdesc,
                                            @transaction_status,
                                            @payment_tran_id OUTPUT

    if (@error = -1)
        goto rollbackerror

    if @transaction_status != @tran_status_cancelled
    begin
        execute @error = p_get_sequence_number 'cinema_rent_payment', 5, @rent_payment_id OUTPUT
        if (@error = -1)
            goto rollbackerror

        INSERT INTO dbo.cinema_rent_payment
	        (rent_payment_id,
	         tran_id,
	         payment_type_code,
	         payment_status_code,
	         payment_method_code,
	         payment_date,
	         payee,
	         payment_desc,
	         acct_bsb,
	         acct_number,
	         acct_ref,
	         payment_no,
	         payment_presented,
	         creation_date)
        VALUES
	        (@rent_payment_id,
	         @payment_tran_id,
	         @payment_type_code,
	         @payment_status_code,
	         @payment_method_code,
	         @payment_date,
	         @payee,
	         @payment_desc,
	         @acct_bsb,
	         @acct_number,
	         @acct_ref,
	         @payment_no,
	         @payment_presented,
	         @creation_date)

        select @error = @@error
        if (@error !=0)
            goto rollbackerror
    end

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
