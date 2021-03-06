/****** Object:  StoredProcedure [dbo].[p_sfin_rent_liability_reset]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_rent_liability_reset]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_rent_liability_reset]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_rent_liability_reset] @accounting_period		datetime,
                                        @business_unit_id       int,
                                        @media_product_id       int,
                                        @revenue_source         char(1)
                                         
                                        
with recompile as
set nocount on 
/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode						int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Remove any Records where all values are now zero
 */

delete cinema_liability
 where accounting_period = @accounting_period
   and business_unit_id = @business_unit_id
   and media_product_id = @media_product_id
   and revenue_source = @revenue_source


select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
