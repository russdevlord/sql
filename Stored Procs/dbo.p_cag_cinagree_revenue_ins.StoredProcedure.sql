/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_revenue_ins]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_cinagree_revenue_ins]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_revenue_ins]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_cinagree_revenue_ins]      @cinema_agreement_id  int      ,
                                            @complex_id           int      ,
                                            @accounting_period    datetime ,
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
                                            @reverse_record       char(1)
as
/* Proc name:   p_cag_cinagree_revenue_ins
 * Author:      Grant Carlson
 * Date:        24/9/2003
 * Description: Create new cinema_agreement_revenue record.
 * Changes:
*/ 
declare @proc_name varchar(30)
select @proc_name = 'p_cag_cinagree_revenue_ins'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @new_revenue_id            int

exec p_audit_proc @proc_name,'start'

exec @error = p_get_sequence_number 'cinema_agreement_revenue',5,@new_revenue_id OUTPUT
if @error != 0
begin
    select @err_msg = 'Error executing p_get_sequence_number for cinema_agreement_revenue'
    raiserror (@err_msg, 16, 1)
    return -1
end

begin transaction
    insert cinema_agreement_revenue(   
                revenue_id,
                cinema_agreement_id,
                complex_id,
                accounting_period,
                origin_period,
                release_period,
                revenue_source,
                business_unit_id,
                liability_type_id,
                policy_id,
                currency_code,
                cag_entitlement_id,
                cinema_amount,
                percentage_entitlement,
                agreement_days,
                period_days,
                excess_status,
                cancelled)
    values     (@new_revenue_id,
                @cinema_agreement_id,
                @complex_id,
                @accounting_period,
                @origin_period,
                @release_period,
                @revenue_source,
                @business_unit_id,
                @liability_type_id,
                @policy_id,
                @currency_code,
                case when @reverse_record = 'Y' then null else @tran_id end,
                case when @reverse_record = 'Y' then -1.0 * @cinema_amount else @cinema_amount end,
                @percentage_entitlement,
                @agreement_days,
                @period_days,
                @excess_status,
                case when (@reverse_record = 'N') then 'N'
                     when (@reverse_record = 'Y' and @tran_id is null) then 'Y' 
                     when (@reverse_record = 'Y' and @tran_id is not null) then 'Y'end)
                                
    if @@error != 0
    begin
        rollback transaction
        return -1
    end
    
commit transaction

exec p_audit_proc @proc_name,'end'

return 0
GO
