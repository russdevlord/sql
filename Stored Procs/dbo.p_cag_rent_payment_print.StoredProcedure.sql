/****** Object:  StoredProcedure [dbo].[p_cag_rent_payment_print]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_payment_print]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_payment_print]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_rent_payment_print]   @rent_payment_id             int

as
                              

declare @error        				int,
        @err_msg                    varchar(150),
       -- @error                         int,
        @cinema_agreement_id        int,
        @statement_no               int,
        @payment_date               datetime,
        @payment_no                 int,
        @nett_amount                money,
        @gst_amount                 money,
        @gst_rate                   decimal(6,4),
        @gross_amount               money,
        @print_address_1            varchar(60),
        @print_address_2            varchar(60),
        @print_address_3            varchar(60),
        @payment_desc               varchar(255),
        @agreement_desc             varchar(50),
        @agreement_abn_no           varchar(20),
        @payment_status_code        char,
        @payment_type_code          char,
        @tran_id                    int,
        @payee                      varchar(50)


  SELECT @cinema_agreement_id = cinema_agreement.cinema_agreement_id,   
         @payment_date = cinema_rent_payment.payment_date,   
         @payment_no = cinema_rent_payment.payment_no,   
         @nett_amount = cinema_agreement_transaction.nett_amount,   
         @gst_amount = cinema_agreement_transaction.gst_amount,   
         @gst_rate = cinema_agreement_transaction.gst_rate,   
         @gross_amount = cinema_agreement_transaction.gross_amount,   
         @payee = cinema_rent_payment.payee,   
         @payment_desc = cinema_rent_payment.payment_desc,   
         @agreement_desc = cinema_agreement.agreement_desc,   
         @agreement_abn_no = cinema_agreement.abn_no,
		 @payment_status_code =	cinema_rent_payment.payment_status_code,
         @payment_type_code = cinema_rent_payment.payment_type_code,
         @tran_id = cinema_agreement_transaction.tran_id
    FROM cinema_agreement_transaction,
		cinema_rent_payment,
        cinema_agreement
   WHERE cinema_agreement_transaction.tran_id =  cinema_rent_payment.tran_id and
         cinema_agreement_transaction.cinema_agreement_id = cinema_agreement.cinema_agreement_id and  
		 cinema_rent_payment.rent_payment_id = @rent_payment_id 

select @error = @@error
if (@error !=0)
      goto error
         
    select @print_address_1 = ''
    select @print_address_2 = ''
    select @print_address_3 = ''


    select  @statement_no = statement_no
    from    cinema_agreement_transaction
    where   tran_id = @tran_id
    
    if @statement_no is null
    begin
        select  @print_address_1 = address.print_address_1,   
                @print_address_2 = address.print_address_2,   
                @print_address_3 = address.print_address_3
        from    address,
                address_xref
        where   address_xref.address_owner_pk_int = @cinema_agreement_id and
                address_xref.address_type_code = 'CAG' and -- Cinema Agreements address
                address_xref.address_category_code = 'AAP' and -- cheque mailing address
		        address_xref.address_id = address.address_id
    end
    else
    begin
        select @print_address_1 = address.print_address_1,   
               @print_address_2 = address.print_address_2,   
               @print_address_3 = address.print_address_3
        from address,
             cinema_agreement_statement,
             cinema_agreement_transaction,
             address_xref
        where   cinema_agreement_statement.statement_no = @statement_no and
                cinema_agreement_statement.cinema_agreement_id = @cinema_agreement_id and
                address_xref.address_xref_id = cinema_agreement_statement.address_xref_id and  
		        address_xref.address_id = address.address_id
    end
             


select	@rent_payment_id,
    @cinema_agreement_id,
    @payee,
    @payment_date,
    @payment_no,
    @nett_amount,
    @gst_amount,
    @gst_rate,
    @gross_amount,
    @print_address_1,
    @print_address_2,
    @print_address_3,
    @payment_desc,
    @agreement_desc,
    @agreement_abn_no,
    @payment_status_code,
    @payment_type_code,
    @tran_id


return 0

error:

    if @error >= 50000
        raiserror (@err_msg, 16, 1)
        
    return -1
GO
