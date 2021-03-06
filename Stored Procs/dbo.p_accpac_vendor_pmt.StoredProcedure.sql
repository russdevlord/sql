/****** Object:  StoredProcedure [dbo].[p_accpac_vendor_pmt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_accpac_vendor_pmt]
GO
/****** Object:  StoredProcedure [dbo].[p_accpac_vendor_pmt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_accpac_vendor_pmt] @country_code char(1), @release_period datetime as

begin
    declare @cinema_agreement_id    int,
            @agreement_desc         varchar(50),
            @tran_id                int,
            @payment_date           datetime,
            @pmt_nett_amount        money,
            @pmt_gross_amount       money,
            @payment_desc           varchar(255),
            @gl_nett_amount         money,
            @gl_account             varchar(20),
            @complex_id             int,
            @business_unit_id       int,
            @trantype_id            int,
           -- @error                  int,
            @errmsg                 varchar(255),
            @sp_name                varchar(255),
            @error                     int,
            @status_awaiting        char(1),
            @status_failed          char(1),
            @run_status             char(1),
            @vendor_payments_id     int,
			@payment_type			char(1),
			@revenue_source			char(1),
			@media_product_id		int,
			@prefix					varchar(4),
			@payment_no				int



    select  @status_awaiting = 'A',
            @status_failed = 'F',
            @run_status = 'A'

    select @sp_name = 'p_accpac_vendor_pmt'
    exec @error = p_dw_start_process @sp_name
            
    begin transaction

    /* temp table to retrieve existing tran_id from accpac */
    create table #transfered_tran
    (
	    tran_id			int		null
    )

    insert into #transfered_tran
    select  tran_id
    from    accpac_integration.dbo.vendor_payments

    declare tran_csr cursor static for
    select  convert(varchar, t.cinema_agreement_id),
            a.agreement_desc,
            p.tran_id,   
            p.payment_date,   
            -(t.nett_amount),
			-(t.gross_amount),
            p.payment_desc,
			p.payment_method_code,
			p.payment_no
    from    cinema_rent_payment p,   
            cinema_agreement_transaction t,
            cinema_agreement a,
            country c
    where   ( t.tran_id = p.tran_id ) 
            and a.currency_code = c.currency_code
            and c.country_code = @country_code
            and p.payment_status_code = 'P'            
            and a.cinema_agreement_id = t.cinema_agreement_id
            and t.process_period = @release_period
            and p.tran_id not in (select tran_id from #transfered_tran)
      
    open tran_csr
    fetch tran_csr into @cinema_agreement_id, @agreement_desc, @tran_id, @payment_date, @pmt_nett_amount, @pmt_gross_amount, @payment_desc, @payment_type, @payment_no
    while(@@fetch_status = 0)
        begin
        
            insert into accpac_integration.dbo.vendor_payments
            (cag_ref, cag_desc, tran_id, date, amount, description, status, country_code, payment_type, presented, gross_amount, payment_no)
            values (convert(varchar, @cinema_agreement_id), @agreement_desc, @tran_id, @payment_date, @pmt_nett_amount, 
					@payment_desc, 'N', @country_code, @payment_type, 'N', @pmt_gross_amount, @payment_no)
        
            select @error = @@error
            If @@error <> 0 
            begin 
                select @run_status = @status_failed
                goto error
            end
            
            select @vendor_payments_id = IDENT_CURRENT('accpac_integration.dbo.vendor_payments')

            declare pmt_distribution_csr cursor static for
            select  e.complex_id,
                    e.business_unit_id,
                    t.trantype_id,
                    e.nett_amount,
					e.revenue_source
            from    cinema_rent_payment_allocation pa,
                    cinema_agreement_entitlement e,
                    cinema_rent_payment p,
                    cinema_agreement_transaction t
            where   pa.payment_tran_id = p.tran_id
            and     pa.entitlement_tran_id = e.tran_id
            and     pa.entitlement_tran_id = t.tran_id                   
            and     p.tran_id = @tran_id
        
            open pmt_distribution_csr
            fetch pmt_distribution_csr into @complex_id, @business_unit_id, @trantype_id, @gl_nett_amount,  @revenue_source
            while(@@fetch_status = 0)
                begin
			        select @prefix = (case @revenue_source
				            when 'F' then '2100'
	        			    when 'D' then '2200'
				            when 'S' then '2300'
							when 'C' then '2500'
							when 'W' then '2600'
				            when 'P' then '2400'        
				            when 'A' then '9999'
				            else '9999' end)

                    select @gl_account = dbo.f_gl_account(0, @prefix, @business_unit_id, @complex_id, default)
--                    select @gl_account = dbo.f_gl_account(@trantype_id, 0, @business_unit_id, @complex_id, default)
                    if isnull(@gl_account,'') = ''
						select @gl_account = '????'
--                        select @gl_account = 'FAILED TO DETERMINE'
--                        begin
--                            select @error = 50500
--                            select @errmsg = 'Failed to determine GL Account for trantype_id:' + convert(varchar, @trantype_id) + 
--                                                ', business_unit:' + convert(varchar, @business_unit_id) + 
--                                                ', complex_id:' + convert(varchar, @complex_id)
--                            goto error
--                         end
                    
                    insert into accpac_integration.dbo.vendor_payment_distribution
                        (vendor_payments_id, gl_account, date, amount, status, country_code)
                    values(@vendor_payments_id, @gl_account, @payment_date, @gl_nett_amount, 'N', @country_code)
                    
                    select @error = @@error
                    If @@error <> 0 
                    begin 
                        select @run_status = @status_failed
                        goto error
                    end
                    
                    fetch pmt_distribution_csr into @complex_id, @business_unit_id, @trantype_id, @gl_nett_amount, @revenue_source
                end
                
                deallocate pmt_distribution_csr
            
                fetch tran_csr into @cinema_agreement_id, @agreement_desc, @tran_id, @payment_date, @pmt_nett_amount, @pmt_gross_amount, @payment_desc, @payment_type, @payment_no
        end
    
    deallocate tran_csr    

   exec @error = p_dw_exit_process @sp_name, @run_status
   if @error = -1
       begin 
           select @run_status = @status_failed
           goto error
       end
        
    commit transaction		
    
return 0

error:
    
    rollback transaction

   exec p_dw_exit_process @sp_name, @run_status
    
    if @error >= 50000
        select @errmsg = 'p_accpac_vendor_pmt: ' + isnull(@errmsg, 'Error occured.')
        raiserror ( @errmsg, 16, 1)
        
    return -1
    
end
GO
