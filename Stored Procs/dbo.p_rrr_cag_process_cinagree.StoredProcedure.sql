/****** Object:  StoredProcedure [dbo].[p_rrr_cag_process_cinagree]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rrr_cag_process_cinagree]
GO
/****** Object:  StoredProcedure [dbo].[p_rrr_cag_process_cinagree]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_rrr_cag_process_cinagree]      @mode char(1),
                                        @cinema_agreement_id  int,
                                        @accounting_period    datetime
--with recompile 
as
/* Proc name:   p_rrr_cag_process_cinagree
 * Author:      Grant Carlson
 * Date:        24/9/2003
 * Description: Main proc for EOM processing of each Cinema Agreement
 *
 * Changes:     28/1/2004 GC, Added Mode. E=Entitlements, P=Payments
 *                                        S=Statements, T=Payments and Statements, A=All
*/ 

declare @proc_name varchar(30)
select @proc_name = 'p_rrr_cag_process_cinagree'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @row_count                  int,
        @calendar_month_start       datetime,
        @calendar_month_end         datetime,
        @csr_origin_period          datetime,
        @process_period             datetime,
        @policy_id                  integer,
        @complex_id                 integer,
        @revenue_source             char(1),
        @rent_mode                  char(1),
        @agreement_type             char(1),
        @cag_currency_code          char(3),
        @suppress_advance_payments       char(1),
        @next_standard_payment_due  datetime,
        @advance_payment_acp_from_date datetime,
        @advance_payment_acp_to_date datetime,
        @cinagree_payment_type_code char(1),
        @standard_payment_cycle     smallint,
        @payment_cycle_months       smallint,
        @rent_inclusion_start       datetime, 
        @rent_inclusion_end         datetime,
        @percentage_entitlement     numeric(6,4),
        @cinema_fixed               money,
        @contribute_to_rent         char(1),
        @policy_cutoff_date         datetime,
        @agreement_split_percentage numeric(6,4),
        @entitlement_adjustment     money,
        @tmp_id                     int,
		@payment_count				int
        

exec p_audit_proc @proc_name,'start'

select  @error = 0



begin transaction

    select  @suppress_advance_payments = 'N',
            @policy_cutoff_date = null,
            @advance_payment_acp_from_date = @accounting_period,
            @advance_payment_acp_to_date = @accounting_period

    select  @policy_cutoff_date = convert(datetime,parameter_string)
    from    system_parameters
    where   parameter_name = 'cag_policy_cutoff'
    
    select  @error = @@error, @row_count = @@rowcount
    if @error != 0
        goto rollbackerror
        
    if @row_count = 0 or @policy_cutoff_date is null
    begin
 	    select @err_msg = 'Could not find cag_policy_cutoff in system parameters table.'
        select @error = 50000
		goto rollbackerror
    end

    select  @agreement_type = agreement_type,
            @cag_currency_code = currency_code,
            @cinagree_payment_type_code = payment_type_code,
            @next_standard_payment_due = isnull(next_standard_payment_due,@accounting_period),
            @standard_payment_cycle = standard_payment_cycle
    from    cinema_agreement
    where   cinema_agreement_id = @cinema_agreement_id


    if @mode in ('E','A')
    begin

            if @cinagree_payment_type_code = 'A'  --advance
                if @next_standard_payment_due = @accounting_period
                begin
                    select  @payment_cycle_months = isnull(payment_months,0) - 1
                    from    cinema_agreement_payment_cycle
                    where   payment_cycle_code = @standard_payment_cycle
                    /* Advance Payment always pays from next accounting period */
                    exec @error = p_get_next_accounting_period @accounting_period, 1, @advance_payment_acp_from_date OUTPUT
                    if @error = -1
                        goto rollbackerror
        
                    exec @error = p_get_next_accounting_period @advance_payment_acp_from_date, @payment_cycle_months, @advance_payment_acp_to_date OUTPUT
              if @error = -1
                        goto rollbackerror
                end
                else
                begin
                    select  @advance_payment_acp_from_date = @accounting_period,
                            @advance_payment_acp_to_date = @accounting_period,
                            @suppress_advance_payments = 'Y'
                end


		declare process_accounting_period_csr cursor static for
		    select  distinct end_date 'process_period' -- For Normal Policies
		    from    accounting_period
		    where   end_date >= @advance_payment_acp_from_date
		    and     end_date <= @advance_payment_acp_to_date
		    and     start_date > @policy_cutoff_date
		    UNION
		    select  ap.end_date -- For Processing New Policies (support for backdating)
		    from    cinema_agreement_policy cap, accounting_period ap, cinema_agreement ca
		    where   cap.policy_created_period = @accounting_period
		    and     cap.cinema_agreement_id = @cinema_agreement_id
		    and     cap.cinema_agreement_id = ca.cinema_agreement_id
		    and     ap.start_date <= isnull(cap.processing_end_date,'1-jan-2050')
		    and     ap.start_date > @policy_cutoff_date
		    and     ap.end_date <= @accounting_period
		    and     ap.end_date >= cap.processing_start_date
		    and     cap.policy_status_code = 'A'
		    and     cap.suspend_contribution = 'N'
		    and     ca.agreement_status ='A'
		    order by process_period
		for read only



            open process_accounting_period_csr
            fetch  process_accounting_period_csr into @process_period
            while @@fetch_status = 0
            begin

				declare revenue_origin_period_csr cursor static for
			    select  distinct cr.origin_period 'csr_origin_period' -- All Min G/variable Policies
			    from    cinema_revenue cr, cinema_agreement_policy cap, accounting_period ap, cinema_agreement ca
			    where   cr.accounting_period = @process_period
			    and     cap.cinema_agreement_id = @cinema_agreement_id
			    and     cap.cinema_agreement_id = ca.cinema_agreement_id
			    and     cr.origin_period = ap.end_date
			    and     isnull(cap.rent_inclusion_start,'1-jan-1900') <= ap.end_date
			    and     isnull(cap.rent_inclusion_end,'1-jan-2050') >= ap.start_date
			    and     cap.policy_status_code = 'A'
                and     cr.complex_id = 217
			    and     cap.suspend_contribution = 'N'
			    and     ca.agreement_status ='A'
			    and     cap.complex_id = cr.complex_id
			    and     cap.revenue_source = cr.revenue_source
				and		cap.rent_mode in ('C','B')
			    UNION
			    select  distinct cr.accounting_period 'csr_origin_period' -- All Min G/variable Policies
			    from    cinema_revenue_creation cr, cinema_agreement_policy cap, accounting_period ap, cinema_agreement ca
			    where   cr.accounting_period = @process_period
			    and     cap.cinema_agreement_id = @cinema_agreement_id
			    and     cap.cinema_agreement_id = ca.cinema_agreement_id
			    and     cr.accounting_period = ap.end_date
			    and     isnull(cap.rent_inclusion_start,'1-jan-1900') <= ap.end_date
			    and     isnull(cap.rent_inclusion_end,'1-jan-2050') >= ap.start_date
			    and     cap.policy_status_code = 'A'
                and     cr.complex_id = 217
			    and     cap.suspend_contribution = 'N'
			    and     ca.agreement_status ='A'
			    and     cap.complex_id = cr.complex_id
			    and     cap.revenue_source = cr.revenue_source
				and		cap.rent_mode in ('I','S')
			    UNION
			    select  ap.end_date -- Special handling for Fixed to bring over variable data
			    from    cinema_agreement_policy cap, accounting_period ap, cinema_agreement ca
			    where   cap.cinema_agreement_id = @cinema_agreement_id
			    and     cap.cinema_agreement_id = ca.cinema_agreement_id
			    and     ap.end_date = @process_period
			    and     isnull(cap.rent_inclusion_start,'1-jan-1900') <= ap.end_date
			    and     isnull(cap.rent_inclusion_end,'1-jan-2050') >= ap.start_date
			    and     cap.policy_status_code = 'A'
			    and     cap.suspend_contribution = 'N'
                and     cap.complex_id = 217
			    and     ca.agreement_status ='A'
			    and     cap.revenue_source = 'P'
	   		 	order by csr_origin_period
				for read only

   
                open revenue_origin_period_csr
                fetch revenue_origin_period_csr into @csr_origin_period
                while @@fetch_status = 0
                begin
                    exec @error = p_cnvt_acct_period_to_calendar @csr_origin_period, @calendar_month_start OUTPUT, @calendar_month_end OUTPUT
                    if @error = -1
                        goto rollbackerror
    
					declare cinagree_policy_current_csr cursor static for
				    select  ap.policy_id, -- Standard policies
				            ap.complex_id,
				            ap.revenue_source,
				            ap.rent_mode,
				            isnull(ap.rent_inclusion_start,'1-jan-1900'),
				            isnull(ap.rent_inclusion_end,'1-jan-2050'),
				            ap.percentage_entitlement,
				            ap.fixed_amount,
				            'Y',
				            isnull(ap.agreement_split_percentage,1.0),
				            isnull(ap.entitlement_adjustment,0)
				    from    cinema_agreement_policy ap, cinema_agreement ca
				    where   ap.cinema_agreement_id = @cinema_agreement_id
				    and     ap.cinema_agreement_id = ca.cinema_agreement_id
                    and     ap.complex_id = 217
				    and     ap.policy_status_code = 'A'
				    and     ap.active_flag = 'Y'
				    and     ap.suspend_contribution = 'N'
				    and     ca.agreement_status ='A'
				    and     isnull(ap.rent_inclusion_start,'1-jan-1900') <= @calendar_month_end
				    and     isnull(ap.rent_inclusion_end,'1-jan-2050') >= @calendar_month_start
                    and     @process_period = @accounting_period -- this condition ensures that backdating works properly
                    UNION
				    select  ap.policy_id, -- Policies requiring backdated adjustment processing
				            ap.complex_id,
				            ap.revenue_source,
				            ap.rent_mode,
				            isnull(ap.rent_inclusion_start,'1-jan-1900'),
				            isnull(ap.rent_inclusion_end,'1-jan-2050'),
				            ap.percentage_entitlement,
				            ap.fixed_amount,
				            'Y',
				            isnull(ap.agreement_split_percentage,1.0),
				            isnull(ap.entitlement_adjustment,0)
				    from    cinema_agreement_policy ap, cinema_agreement ca
				    where   ap.cinema_agreement_id = @cinema_agreement_id
				    and     ap.cinema_agreement_id = ca.cinema_agreement_id
				    and     ap.policy_status_code = 'A'
				    and     ap.active_flag = 'Y'
				    and     ap.suspend_contribution = 'N'
                    and     ap.complex_id = 217
				    and     ca.agreement_status ='A'
				    and     isnull(ap.rent_inclusion_start,'1-jan-1900') <= @calendar_month_end
				    and     isnull(ap.rent_inclusion_end,'1-jan-2050') >= @calendar_month_start
                    and     @process_period < @accounting_period -- this condition ensures that backdating works properly
                    and     (ap.policy_created_period = @accounting_period and ap.previous_policy > 0) -- special condition for backdated adjustment logic
				    UNION
				    select  ap.policy_id,  -- Special handling for Fixed to bring over variable data
				            ap.complex_id,
				            cam.revenue_source,
				            cam.rent_mode,
				            isnull(ap.rent_inclusion_start,'1-jan-1900'),
				            isnull(ap.rent_inclusion_end,'1-jan-2050'),
				            cam.percentage_entitlement,
				            0,
				            'N',
				            1.0,
				            0
				    from    cinema_agreement_policy ap, cinema_agreement ca, cinema_agreement_module cam
				    where   ap.cinema_agreement_id = @cinema_agreement_id
				    and     ap.cinema_agreement_id = ca.cinema_agreement_id
				    and     ap.cinema_agreement_id = cam.cinema_agreement_id
				    and     ap.policy_status_code = 'A'
				    and     ap.active_flag = 'Y'
				    and     ap.suspend_contribution = 'N'
				    and     ca.agreement_status ='A'
				    and     ca.agreement_type = 'F'
                    and     ap.complex_id = 217
				    and     cam.revenue_source <> 'P'
				    and     isnull(ap.rent_inclusion_start,'1-jan-1900') <= @calendar_month_end
				    and     isnull(ap.rent_inclusion_end,'1-jan-2050') >= @calendar_month_start
				    order by complex_id, revenue_source
					for read only 

                    open cinagree_policy_current_csr
                    fetch cinagree_policy_current_csr into  @policy_id, 
                                                            @complex_id, 
                                                            @revenue_source,
                                                            @rent_mode, 
                                                            @rent_inclusion_start, 
                                                            @rent_inclusion_end,
                                                            @percentage_entitlement,
                               								@cinema_fixed,
                                                            @contribute_to_rent,
                                                            @agreement_split_percentage,
                                                            @entitlement_adjustment
                    while @@fetch_status = 0
                    begin
                                                                   
                        exec @error = p_cag_create_cinagree_revenue    @cinema_agreement_id,
                                                                    @complex_id,
                                                                    @revenue_source,
                                                                    @rent_mode,
                                                                    @cag_currency_code,
                                                                    @policy_id,
                                                                    @accounting_period,
                                                                    @process_period,
                                                                    @csr_origin_period,
                                                                    @agreement_type,
                                                                    @calendar_month_start,
                                                                    @calendar_month_end,
                                                                    @rent_inclusion_start, 
                                                                    @rent_inclusion_end,
                                                                    @percentage_entitlement,
                                                                    @cinema_fixed,
                                                                    @suppress_advance_payments,
                                                                    @agreement_split_percentage
                        if @error = -1
                            goto rollbackerror

                        if @contribute_to_rent = 'Y'
                        begin            
                            exec @error = p_cag_create_entitlement @cinema_agreement_id,
                                                                @complex_id,
                                                                @revenue_source,
                                                                @policy_id,
                                                                @accounting_period,
                                                                @csr_origin_period,
                                                                @agreement_type,
                                                                @rent_mode,
                                                                @cag_currency_code,
                                                                @entitlement_adjustment
                            if @error = -1
                                goto rollbackerror
                        end
                        fetch cinagree_policy_current_csr into  @policy_id, 
                                                                @complex_id, 
                                                                @revenue_source,
                                                                @rent_mode, 
                                                                @rent_inclusion_start, 
                                                                @rent_inclusion_end,
                                                                @percentage_entitlement,
                                                                @cinema_fixed,
                                                                @contribute_to_rent,
                                                                @agreement_split_percentage,
                             @entitlement_adjustment


                    end -- while
                    deallocate cinagree_policy_current_csr
                    fetch revenue_origin_period_csr into @csr_origin_period
                end --while
                deallocate revenue_origin_period_csr
            fetch  process_accounting_period_csr into @process_period
            end --while    
            
            
    end --@mode in ('E','A')
commit transaction

deallocate process_accounting_period_csr

exec p_audit_proc @proc_name,'end'

return 0

rollbackerror:
    rollback transaction
error:
    deallocate process_accounting_period_csr
    deallocate cinagree_policy_current_csr
    deallocate revenue_origin_period_csr

    if @error >= 50000
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end

    return -1
GO
