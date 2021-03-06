/****** Object:  StoredProcedure [dbo].[p_get_prior_accounting_period]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_prior_accounting_period]
GO
/****** Object:  StoredProcedure [dbo].[p_get_prior_accounting_period]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_prior_accounting_period]    @accounting_period      datetime,
                                            @num_months             tinyint,
                                            @prior_accounting_period datetime OUTPUT

as

set nocount on                               

declare @error        		 int,
        @err_msg             varchar(150)


select @prior_accounting_period = @accounting_period

if @num_months <= 0 
    return 0

declare period_csr cursor static for
select  ac.end_date
from    accounting_period ac
where   ac.end_date < @accounting_period
order by ac.end_date DESC
for read only

open period_csr
while (@num_months > 0)
begin
    fetch period_csr into @prior_accounting_period
    if(@@fetch_status <> 0)				
    begin
	    select @err_msg =  'p_get_prior_accounting_period: Error Fetching Previouse Prd ' + convert(varchar, @accounting_period, 105)
        select @error = 50000
		goto error
    end
    select @num_months = @num_months - 1
end 

deallocate period_csr
return 0

error:
    deallocate period_csr
    if @error >= 50000
        raiserror (@err_msg, 16, 1)
    return -1
GO
