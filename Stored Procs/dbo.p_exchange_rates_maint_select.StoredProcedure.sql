/****** Object:  StoredProcedure [dbo].[p_exchange_rates_maint_select]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_exchange_rates_maint_select]
GO
/****** Object:  StoredProcedure [dbo].[p_exchange_rates_maint_select]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_exchange_rates_maint_select]     @accounting_period      datetime
as
                              
set nocount on 

if not exists (select 1 from exchange_rates where accounting_period = @accounting_period)
begin 
    begin transaction
        insert into exchange_rates
        select  accounting_period.end_date  'accounting_period',
                c1.currency_code      'currency_code_from',
                c2.currency_code      'currency_code_to',
                case when c1.currency_code = c2.currency_code then 1 else 0 end 'conversion_rate'
        from    currency c1, currency c2, accounting_period
        where   accounting_period.end_date = @accounting_period
    
        if @@error <> 0
        begin
            rollback transaction
            raiserror ('Error creating new exchange rate records', 16, 1)
            return -1
        end
    commit transaction       
end

select  accounting_period 'accounting_period',
        currency_code_from 'currency_code_from',
        currency_code_to 'currency_code_to',
        conversion_rate 'conversion_rate',
        case when currency_code_from = currency_code_to then 1 else 0 end 'curr_same'
from    exchange_rates
where   accounting_period = @accounting_period        

return 0
GO
