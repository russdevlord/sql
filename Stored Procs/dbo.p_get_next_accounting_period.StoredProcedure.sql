/****** Object:  StoredProcedure [dbo].[p_get_next_accounting_period]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_next_accounting_period]
GO
/****** Object:  StoredProcedure [dbo].[p_get_next_accounting_period]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_next_accounting_period]    @accounting_period      datetime,
                                            @num_months             tinyint,
                                            @next_accounting_period datetime OUTPUT

as

/* Proc name:   p_get_next_accounting_period
 * Author:      Grant Carlson
 * Date:        14/11/2003
 * Description: Returns an accounting period @num_months from  @accounting_period
 *
 * Changes:
*/                              
set nocount on 

declare @error        		 int,
        @err_msg             varchar(150)


select @next_accounting_period = @accounting_period

if @num_months <= 0 
    return 0

declare period_csr cursor static for
select  ac.end_date
from    accounting_period ac
where   ac.end_date > @accounting_period
order by ac.end_date ASC
for read only

open period_csr
while (@num_months > 0)
begin
    fetch period_csr into @next_accounting_period
    if(@@fetch_status <> 0)				
    begin
	    select @err_msg =  'Cinema Rent Pay Generation: Error Retrieving Currrent Period'
        select @error = 50000
    end
    select @num_months = @num_months - 1
end --while

close period_csr
deallocate period_csr
return 0

error:
    deallocate period_csr
    if @error >= 50000
        raiserror (@err_msg, 16, 1)
    return -1
GO
