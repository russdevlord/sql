/****** Object:  StoredProcedure [dbo].[p_cag_update_payment]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_update_payment]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_update_payment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_update_payment]   @tran_id             int,
                                   @rent_payment_id     int, 
                                   @cinema_agreement_id int,
                                   @accounting_period   datetime,
                                   @process_period      datetime,
                                   @tran_desc           varchar(255),
                                   @tran_subdesc        varchar(255),
                                   @nett_amount         money,
                                   @gst_rate            decimal(6,4),
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
                                   @payment_presented   char(1),
                                   @presented_date      datetime
as
                              

declare @error        				int,
        @err_msg                    varchar(150)


begin transaction

UPDATE cinema_agreement_transaction
SET 	accounting_period = @accounting_period,
		process_period = @process_period,
		tran_desc = @tran_desc,
		tran_subdesc = @tran_subdesc,
		nett_amount = @nett_amount,
		gst_amount = @nett_amount * @gst_rate,
		gross_amount = @nett_amount + @nett_amount * @gst_rate,
		show_on_statement = @show_on_statement
WHERE   tran_id = @tran_id

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
		payment_presented = @payment_presented,
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
