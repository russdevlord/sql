/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_trans_ins]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_cinagree_trans_ins]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_trans_ins]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_cinagree_trans_ins]    @cinema_agreement_id    int,
                                        @trantype_id            int,
                                        @accounting_period      datetime,
                                        @process_period         datetime,
                                        @tran_date              datetime,
                                        @show_on_statement      char(1),
                                        @origin_currency_code   char(3),
                                        @nett_amount            money,
                                        @gst_rate            numeric(6,4),
                                        @gst_amount          money,
                                        @gross_amount        money,                                        
                                        @tran_desc              varchar(255),
                                        @tran_sub_desc          varchar(255),
                                        @transaction_status     char(1),
                                        @tran_id                int OUTPUT
                                     

as
/* Proc name:   p_cag_cinagree_trans_ins
 * Author:      Grant Carlson
 * Date:        3/10/2003
 * Description: Creates cinema_agreement_transaction records
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_cinagree_trans_ins'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @tran_category				char(1),
        @gst_exempt					char(1),
        @currency_code				char(3)

                                  
exec p_audit_proc @proc_name,'start'

select  @tran_category = tran_category_code,
        @gst_exempt = gst_exempt
  from  transaction_type
 where  trantype_id = @trantype_id
if (@@error !=0)
begin
	return -1
end	


if @gross_amount is null -- ie: don't use provided values, calculate using GST
begin
    exec @error = p_cag_get_gst_rate @cinema_agreement_id, @process_period, @currency_code OUTPUT, @gst_rate OUTPUT
    if @error = -1 return -1

    if @origin_currency_code <> @currency_code
        select @gst_exempt = 'Y'

    if @gst_exempt = 'Y'
	    select @gst_rate = 0.0
                                

    if @tran_category = 'C' or @tran_category = 'X'                                  
    begin
	    select @gross_amount = @nett_amount
	    select @nett_amount = 0
	    select @gst_amount = 0
    end
    else
    begin
	    select @gst_amount = (round(@nett_amount * @gst_rate,2))
	    select @gross_amount = @nett_amount + @gst_amount
    end
end

execute @error = p_get_sequence_number 'cinema_agreement_transaction', 5, @tran_id OUTPUT
if (@error !=0)
	return -1

begin transaction

    INSERT INTO dbo.cinema_agreement_transaction
	    (tran_id,
	     trantype_id,
	     cinema_agreement_id,
	     accounting_period,
	     process_period,
	     currency_code,
	     statement_no,
	     tran_desc,
	     tran_subdesc,
	     tran_date,
	     nett_amount,
	     gst_rate,
	     gst_amount,
	     gross_amount,
	     show_on_statement,
         transaction_status_code)
    VALUES
	    (@tran_id,
	     @trantype_id,
	     @cinema_agreement_id,
	     @accounting_period,
	     @process_period,
	     @currency_code,
	     null,
	     @tran_desc,
	     @tran_sub_desc,
	     @tran_date,
	     @nett_amount,
	     @gst_rate,
	     @gst_amount,
	     @gross_amount,
	     @show_on_statement,
         @transaction_status)
         
    select @error = @@error
    if (@error !=0)
    begin
        select @err_msg = 'INSERT error: cinema_agreement_transaction'
        goto error
    end        

commit transaction

exec p_audit_proc @proc_name,'end'

return 0

error:

    if @error >= 50000
        raiserror (@err_msg, 16, 1)
        
    rollback transaction
    return -1
GO
