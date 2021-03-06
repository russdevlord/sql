/****** Object:  StoredProcedure [dbo].[p_sfin_rent_liability_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_rent_liability_update]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_rent_liability_update]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_rent_liability_update] @accounting_period		datetime,
                                         @country_code			char(1),
                                         @complex_id		    int,
                                         @liability_amount		money,
                                         @business_unit_id		int,
                                         @media_product_id      int,
                                         @revenue_source        char(1),
										 @origin_period			datetime
with recompile as
set nocount on 
/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode					    int,
        @count                      int
/*
 * Begin Transaction
 */

begin transaction

/*
 * Determine if Cinema Rent Record Exists
 */

select 	@count = count(complex_id)
from 	cinema_liability
where 	country_code = @country_code 
and 	accounting_period = @accounting_period 
and 	complex_id = @complex_id
and 	@business_unit_id = business_unit_id
and 	@media_product_id = media_product_id 
and 	@revenue_source = revenue_source
and		@origin_period = origin_period


/*
 * Create or Update Slide Cinema Rent
 */
	
if(@count = 0)
begin
	
	/*
	 * Create Cinema Rent
	 */
		
	insert into cinema_liability(
	complex_id,
	country_code,
	accounting_period,
	liability_amount,
	business_unit_id,
	media_product_id,
	revenue_source,
	origin_period) values (
	@complex_id,
	@country_code,
	@accounting_period,
	@liability_amount,
	@business_unit_id,
	@media_product_id,
	@revenue_source,
	@origin_period)
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		return -1
	end
	
end
else
begin

	update 	cinema_liability
	set 	liability_amount = @liability_amount
	where 	country_code = @country_code 
	and 	accounting_period = @accounting_period 
	and 	complex_id = @complex_id
	and 	@business_unit_id = business_unit_id
	and 	@media_product_id = media_product_id 
	and 	@revenue_source = revenue_source
	and		@origin_period = origin_period

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		return -1
	end
	
end
	
/*
 * Commit and Return
 */

commit transaction
return 0
GO
