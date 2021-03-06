/****** Object:  StoredProcedure [dbo].[p_cag_create_cinagree_revenue]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_cinagree_revenue]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_cinagree_revenue]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_create_cinagree_revenue]   @cinema_agreement_id    		int,
													@complex_id             		int,
													@revenue_source         		char(1),
													@rent_mode              		char(1),
													@ca_currency_code     			char(3),
													@policy_id              		int,
													@accounting_period				datetime,
													@process_period         		datetime,
													@origin_period          		datetime,
													@agreement_type         		char(1),
													@calendar_month_start   		datetime,
													@calendar_month_end     		datetime,
													@rent_inclusion_start   		datetime, 
													@rent_inclusion_end     		datetime,
													@percentage_entitlement 		numeric(6,4),
													@cinema_fixed           		money,
													@suppress_advance_payments   	char(1),
													@agreement_split_percentage 	numeric(6,4)
                                            
--with recompile 

as

/* Proc name:   p_cag_create_cinagree_revenue
 * Author:      Grant Carlson
 * Date:        24/9/2003
 * Description: Creates all records in cinema_agreement_revenue from cinema_revenue based
 *              on Policy settings and accounting period.
 *              NOTE:   For Fixed Guarantee agreements all modules are used to simulate policies
 *                      so that billing and collection revenue data is recorded.
 *
 * Changes:
*/                              

declare @proc_name varchar(30)
select	@proc_name = 'p_cag_create_cinagree_revenue'


declare @error        					int,
        @err_msg                    	varchar(150),
       -- @error                         	int,
        @rows                       	int,
        @fixed_guarantee_liability  	tinyint,
        @csr_accounting_period        	datetime,
        @liability_type_id    			tinyint,
        @business_unit_id       		smallint,
        @currency_code        			char(3),
        @cinema_amount        			money,
        @agreement_days       			tinyint,
        @period_days          			tinyint,
        @contrib_period_start   		datetime,
        @contrib_period_end     		datetime,
        @excess_status          		tinyint

exec p_audit_proc @proc_name,'start'
  
if  ((@rent_inclusion_start < @calendar_month_start) and (@rent_inclusion_end < @calendar_month_start)
  OR (@rent_inclusion_start > @calendar_month_end) and (@rent_inclusion_end > @calendar_month_end))
  return 0 -- no processing required for this period

select @period_days = datediff(dd,@calendar_month_start, @calendar_month_end) + 1

if (@rent_inclusion_start < @calendar_month_start)
    select @contrib_period_start = @calendar_month_start
else
    select @contrib_period_start = @rent_inclusion_start

if (@rent_inclusion_end > @calendar_month_end)
    select @contrib_period_end = @calendar_month_end
else    
    select @contrib_period_end = @rent_inclusion_end

select @agreement_days = datediff(dd,@contrib_period_start, @contrib_period_end) + 1

begin transaction
  
declare cinema_revenue_csr cursor static for
select  cr.liability_type_id,
        cr.currency_code,
        cr.business_unit_id,
        sum(cr.cinema_amount * @agreement_split_percentage),
        case when @agreement_type = 'M' then 1 else 0 end
from    cinema_revenue cr, 
		liability_type lt, 
		liability_category lc
where   cr.liability_type_id = lt.liability_type_id
and     lt.liability_category_id = lc.liability_category_id
and		lc.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode = 'B' OR rent_mode = 'C')
and		lc.liability_category_id not in (4)
and     cr.complex_id = @complex_id
and     cr.origin_period = @origin_period
and     cr.accounting_period = @process_period
and     cr.revenue_source = @revenue_source
and     @process_period <= @accounting_period --stops processing when advance payment revenue generated
and		(@rent_mode = 'B' or @rent_mode = 'C')
group by cr.liability_type_id,
         cr.currency_code,
         cr.business_unit_id
UNION
select  cr.liability_type_id,
        cr.currency_code,
        cr.business_unit_id,
        sum(cr.cinema_amount * @agreement_split_percentage),
        case when @agreement_type = 'M' then 1 else 0 end
from    cinema_revenue_creation cr, 
		liability_type lt, 
		liability_category lc
where   cr.liability_type_id = lt.liability_type_id
and     lt.liability_category_id = lc.liability_category_id
and		lc.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode = 'I' OR rent_mode = 'S')
and		lc.liability_category_id not in (4)
and     cr.complex_id = @complex_id
and     cr.accounting_period = @process_period
and     cr.revenue_source = @revenue_source
and     @process_period <= @accounting_period --stops processing when advance payment revenue generated
and		(@rent_mode = 'I' or @rent_mode = 'S')
group by cr.liability_type_id,
         cr.currency_code,
         cr.business_unit_id
UNION
select  lt.liability_type_id,
        @ca_currency_code,
        bu.business_unit_id,
        @cinema_fixed,
        0
from    liability_type lt, liability_category lc, business_unit bu, media_product mp
where   lt.liability_category_id = lc.liability_category_id
and     lc.rent_mode = @rent_mode
and     bu.primary_media_product = mp.media_product_id
and     mp.revenue_source = @revenue_source
and     @revenue_source = 'P'
and     @origin_period = @process_period --stops fixed payments from being created with old collections
order by cr.liability_type_id
for read only


    open cinema_revenue_csr
    fetch cinema_revenue_csr into @liability_type_id,
                                  @currency_code,
                                  @business_unit_id,
                                  @cinema_amount,
                                  @excess_status

    while @@fetch_status = 0 
    begin

        exec @error = p_cag_cinagree_revenue_upd   @cinema_agreement_id,
                                                @agreement_type,
                                                @complex_id,
                                                @accounting_period,
                                                @process_period,
                                                @origin_period,
                                                null,
                                                @revenue_source,
                                                @business_unit_id,
                                                @liability_type_id,
                                                @policy_id,
                                                @currency_code,
                                                null,
                                                @cinema_amount,
                                                @percentage_entitlement,
                                                @agreement_days,
                                                @period_days,
                                                @excess_status,
                                                @suppress_advance_payments

        if @error = -1
        begin
            select @err_msg = 'Error executing p_cag_cinagree_revenue_upd'
            goto rollbackerror
        end

        fetch cinema_revenue_csr into @liability_type_id,
                                      @currency_code,
                                      @business_unit_id,
                                      @cinema_amount,
                                      @excess_status
                                      
    end --while
commit transaction

exec p_audit_proc @proc_name,'end'

return 0

rollbackerror:
    rollback transaction

error:
    deallocate cinema_revenue_csr

    if @error >= 50000
        raiserror (@err_msg, 16, 1)
    return -1
GO
