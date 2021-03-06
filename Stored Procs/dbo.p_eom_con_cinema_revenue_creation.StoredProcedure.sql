/****** Object:  StoredProcedure [dbo].[p_eom_con_cinema_revenue_creation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_con_cinema_revenue_creation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_con_cinema_revenue_creation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_eom_con_cinema_revenue_creation]  @accounting_period      datetime

as

declare     @error                  int,
            @errorode                  int,
            @revenue_id             int

/*
 * Begin Transaction
 */

begin transaction

delete cinema_revenue_creation 
 where accounting_period = @accounting_period


select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Delete Old Cinema Revenue Data.', 16, 1)
    return -100
end
                  

/*
 * Insert Film Rows into Cinema Revenue Table
 */

insert into cinema_revenue_creation
        (complex_id,
         accounting_period,
         revenue_source,
         business_unit_id,
         liability_type_id,
         currency_code,
         cinema_amount)
  select complex_id,
         accounting_period,
         revenue_source,
         business_unit_id,
         liability_type_id,
         currency_code,
         isnull(sum(cinema_amount),0)
    from film_revenue_creation
   where accounting_period = @accounting_period
group by complex_id,
         accounting_period,
         revenue_source,
         business_unit_id,
         liability_type_id,
         currency_code
  having isnull(sum(cinema_amount),0) <> 0
                  
select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Cinema Revenue Table - Film Data.', 16, 1)
    return -100
end
                  
               
/*
 * Commit Transaction And Return
 */

commit transaction
return 0
GO
