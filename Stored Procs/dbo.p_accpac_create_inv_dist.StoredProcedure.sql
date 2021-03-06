/****** Object:  StoredProcedure [dbo].[p_accpac_create_inv_dist]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_accpac_create_inv_dist]
GO
/****** Object:  StoredProcedure [dbo].[p_accpac_create_inv_dist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_accpac_create_inv_dist]	@country_code			char(1),
										@accounting_period		datetime

as

set nocount on

declare			@error			            int,
                @err_msg                    varchar(150),
                --@error                         int,
                @proc_name                  varchar(50),
                @status_awaiting            char(1),
                @status_failed              char(1),
                @interface_status_new       char(1)

select  @status_awaiting = @country_code,
        @status_failed = 'F',
        @interface_status_new = 'N'

select  @proc_name = object_name(@@PROCID)

exec @error = p_dw_start_process @proc_name
if @error != 0
	goto error
    
/*
 * Begin Transaction
 */

begin transaction

/*
 * Insert Amounts
 */

INSERT INTO accpac_integration.dbo.invoice_distribution
	    (gl_account,
	    date,
	    amount,
	    status,
        country_code) 
select  dbo.f_gl_account(1, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 2			
and		media_product_id = 1
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(1, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 3			
and		media_product_id = 1
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(1, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 5			
and		media_product_id = 1
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(5, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 2
and		media_product_id = 2			
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(5, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 3			
and		media_product_id = 2
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(5, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 5			
and		media_product_id = 2
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(73, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 2
and		media_product_id = 3
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(73, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 3			
and		media_product_id = 3
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(73, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 5			
and		media_product_id = 3
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(88, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 2
and		media_product_id = 6
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(88, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 3			
and		media_product_id = 6
group by business_unit_id,
        complex_id
union
select  dbo.f_gl_account(88, null,  business_unit_id, complex_id,default),
		@accounting_period,
		sum(weighted_billings) 'total',
		'N',
        @country_code
from    film_spot_summary 
where   accounting_period = @accounting_period
and		country_code = @country_code
and		business_unit_id = 5			
and		media_product_id = 6
group by business_unit_id,
        complex_id
union
select   dbo.f_gl_account(st.tran_type, null,  1, ssp.complex_id, default),
		@accounting_period,
		sum(ssp.total_amount) 'total',
		'N',
        @country_code
from    slide_campaign sc,
        slide_campaign_spot scs,
        slide_transaction st,
        slide_spot_trans_xref xr,
		branch br,
        slide_spot_pool ssp
where   sc.campaign_no = scs.campaign_no
and     sc.campaign_no = st.campaign_no
and     st.tran_category != 'C'
and     scs.spot_id = xr.spot_id
and     xr.billing_tran_id = st.tran_id
and     st.statement_id  in (select statement_id from slide_statement where accounting_period = @accounting_period)
and     sc.branch_code = br.branch_code
and     st.tran_category = ssp.spot_pool_type
and     br.country_code = @country_code
and     ssp.spot_id = scs.spot_id
and     ssp.spot_pool_type = 'B'
group by st.tran_type,
        ssp.complex_id
        
select @error = @@error
if @error != 0
    goto rollbackerror

commit transaction

exec @error = p_dw_exit_process @proc_name

return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    exec @error = p_dw_exit_process @proc_name,@status_failed

    return -1
GO
