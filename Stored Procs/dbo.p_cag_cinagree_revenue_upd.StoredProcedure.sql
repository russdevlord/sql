/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_revenue_upd]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_cinagree_revenue_upd]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_revenue_upd]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_cinagree_revenue_upd]      @cinema_agreement_id  int      ,
                                            @agreement_type       char(1),
                                            @complex_id           int      ,
                                            @accounting_period    datetime ,
                                            @process_period       datetime,
                                            @origin_period        datetime ,
                                            @release_period         datetime,
                                            @revenue_source       char(1)  ,
                                            @business_unit_id     smallint,
                                            @liability_type_id    tinyint  ,
                                            @policy_id            int      ,
                                            @currency_code        char(3)  ,
                                            @tran_id                int,
                                            @cinema_amount        money     ,
                                            @percentage_entitlement numeric(6,4),
                                            @agreement_days       tinyint     ,
                                            @period_days          tinyint,
                                            @excess_status          tinyint,
                                            @suppress_advance_payments char(1)
as
/* Proc name:   p_cag_cinagree_revenue_upd
 * Author:      Grant Carlson
 * Date:        24/9/2003
 * Description: Create new cinema_agreement_revenue record. If record already exists assume adjustment
 *              required if data/policy not same - create adjustment as well.
 *
 *              This proc also sets excess_status flag if agreement is Minimum Guarantee
 *
 *              Implied PK to determine if data has been calculated previously is:
 *                  - cinema_agreement_id
 *                  - complex_id
 *                  - revenue_source
 *                  - accounting_period
 *                  - liability_type_id
 *
 * Changes:
*/ 
declare @proc_name varchar(30)
select @proc_name = 'p_cag_cinagree_revenue_upd'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @car_csr_open               tinyint,
        @running_same_policy        char(1),
        @previous_policy            int,
        @old_revenue_id             int,
        @old_cinema_agreement_id    int,
        @old_complex_id             int,
        @old_accounting_period      datetime,
        @old_release_period         datetime,
        @old_revenue_source         char(1),
        @old_business_unit_id       smallint,
        @old_liability_type_id      tinyint,
        @old_policy_id              int,
        @old_currency_code          char(3),
        @old_tran_id                int,
        @old_cinema_amount          money,
        @old_percentage_entitlement numeric(6,4),
        @old_agreement_days         tinyint,
        @old_period_days            tinyint,
        @old_excess_status          tinyint,
        @new_revenue_id             int,
        @policy_revenue_source      char(1)

exec p_audit_proc @proc_name,'start'

select  @old_revenue_id = null,
        @car_csr_open = 0,
        @running_same_policy = 'N'


begin transaction

declare car_csr cursor static for
select  revenue_id,
        accounting_period,
        release_period,
        revenue_source,
        business_unit_id,
        policy_id,  
        currency_code,
        cag_entitlement_id,
        cinema_amount,
        percentage_entitlement,
        agreement_days,
        period_days,
        excess_status
from    cinema_agreement_revenue
where   cinema_agreement_id = @cinema_agreement_id
and     complex_id = @complex_id
and     revenue_source = @revenue_source
and     business_unit_id = @business_unit_id
and     currency_code = @currency_code
and     origin_period = @origin_period
and     accounting_period = @process_period
and     liability_type_id = @liability_type_id
and     cancelled = 'N'
for read only

    open car_csr -- first check to see if there are any pre-existing records which may need to be reversed
    select @car_csr_open = 1
    fetch car_csr into  @old_revenue_id,
                        @old_accounting_period,
                        @old_release_period,
                        @old_revenue_source,
                        @old_business_unit_id,
                        @old_policy_id,
                        @old_currency_code,
                        @old_tran_id,
                        @old_cinema_amount,
                        @old_percentage_entitlement,
                        @old_agreement_days,
                        @old_period_days,
                        @old_excess_status
    
    while @@fetch_status = 0 
    begin /* Existing records indicates that the period is being re-processed with possible policy change */
          /* only reverse if the policy id on existing records is the previous policy id of the current policy */
          /* which indicates that the new policy is overriding the old one */

        if @policy_id = @old_policy_id -- if the same data is selected with the same policy then it is a re-run
            select @running_same_policy = 'Y'

        if @agreement_type = 'F' -- have to force revenue source as all revenue created based on Fixed policy
            select @policy_revenue_source = 'P',
                   @suppress_advance_payments = 'N' -- allow backdated policy changes to affect all advance payments
        else
            select @policy_revenue_source = @revenue_source

        select  @previous_policy = previous_policy
        from    cinema_agreement_policy
        where   policy_id = @policy_id
        and     cinema_agreement_id = @cinema_agreement_id
        and     complex_id = @complex_id
        and     revenue_source = @policy_revenue_source

        if @previous_policy =  @old_policy_id -- policy on existing records = prev policy so reverse
        begin -- reverse previous record
            exec @error = p_cag_cinagree_revenue_ins   @cinema_agreement_id,
                                                    @complex_id,
                                                    @old_accounting_period,
                                                    @origin_period,
                                                    @release_period,
                                                    @revenue_source,
                                                    @business_unit_id,
                                                    @liability_type_id,
                                                    @old_policy_id,
                                                    @old_currency_code,
                                                    @old_tran_id,
                                                    @old_cinema_amount,
                                                    @old_percentage_entitlement,
                                                    @old_agreement_days,
                                                    @old_period_days,
                                                    @old_excess_status,
                                                    'Y'
            if @error = -1
            begin
                select @err_msg = 'Error executing p_cag_cinagree_revenue_upd for reversal'
                goto error
            end
            /* Always cancel original record when reversing */
            update  cinema_agreement_revenue
            set     cancelled = 'Y'
            where   revenue_id = @old_revenue_id
            if @@error != 0
            begin
                select @err_msg = 'UPDATE Error: updating cancelled flag on cinema_agreement_revenue'
                goto error
            end    
        end --reverse record

        fetch car_csr into  @old_revenue_id,
                            @old_accounting_period,
                            @old_release_period,
                            @old_revenue_source,
                            @old_business_unit_id,
                            @old_policy_id,
                            @old_currency_code,
                            @old_tran_id,
                            @old_cinema_amount,
                            @old_percentage_entitlement,
                            @old_agreement_days,
                            @old_period_days,
                            @old_excess_status            
    end -- while

    /* Now create new revenue record if required */
    if @running_same_policy = 'N' and @suppress_advance_payments = 'N'
    begin
        exec @error = p_cag_cinagree_revenue_ins   @cinema_agreement_id,
                                                @complex_id,
                                                @process_period,
                                                @origin_period,
                                                @release_period,
                                                @revenue_source,
                                                @business_unit_id,
                                                @liability_type_id,
                                                @policy_id,
                                                @currency_code,
                                                @tran_id,
                                                @cinema_amount,
                                                @percentage_entitlement,
                                                @agreement_days,
                                                @period_days,
                                                @excess_status,
                                                'N'
                        
        if @error = -1
        begin
            select @err_msg = 'INSERT Error: cinema_agreement_revenue'
            goto error
        end      
    end --create new record

commit transaction

exec p_audit_proc @proc_name,'end'

return 0

error:
    raiserror (@err_msg, 16, 1)
    rollback transaction
    return -1
GO
