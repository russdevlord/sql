/****** Object:  StoredProcedure [dbo].[p_fix_proj_bill]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fix_proj_bill]
GO
/****** Object:  StoredProcedure [dbo].[p_fix_proj_bill]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_fix_proj_bill]
as
declare 	@error					int,
			@report_date			datetime,
			@finyear_end_1			datetime,
			@finyear_end_2			datetime,
			@ftr_amount				money,
			@next_year_amount		money,
			@business_unit_id		int,
			@media_product_id		int,
			@agency_deal			char(1),
			@branch_code			char(1)

set nocount on

declare		proj_bill_csr cursor forward_only static for
select 		distinct report_date,
			business_unit_id,
			media_product_id,
			agency_deal,
			branch_code,
			min(finyear_end),
			max(finyear_end)
from 		projected_billings
group by 	report_date,
			business_unit_id,
			media_product_id,
			agency_deal,
			branch_code
order by 	report_date,
			business_unit_id,
			media_product_id,
			agency_deal,
			branch_code

begin transaction

open proj_bill_csr
fetch proj_bill_csr into @report_date, @business_unit_id, @media_product_id, @agency_deal, @branch_code, @finyear_end_1, @finyear_end_2
while(@@fetch_status=0)
begin

	if @finyear_end_1 != @finyear_end_2
	begin
		select @next_year_amount = sum(	billings_future + 
										billings_month_01 + 
										billings_month_02 + 
										billings_month_03 + 
										billings_month_04 + 	
										billings_month_05 + 
										billings_month_06 + 
										billings_month_07 + 
										billings_month_08 + 
										billings_month_09 + 
										billings_month_10 + 
										billings_month_11 + 
										billings_month_12) 
		from 	projected_billings 
		where 	report_date = @report_date 
		and 	finyear_end = @finyear_end_2 
		and 	business_unit_id = @business_unit_id
		and		media_product_id = @media_product_id
		and		agency_deal = @agency_deal
		and 	branch_code = @branch_code
	
		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('Couldnt select', 16, 1)
			return -1
		end
	
		update 	projected_billings
		set 	billings_future = @next_year_amount
		where	report_date = @report_date 
		and 	business_unit_id = @business_unit_id
		and		media_product_id = @media_product_id
		and		agency_deal = @agency_deal
		and 	branch_code = @branch_code
		and 	finyear_end = @finyear_end_1
	
		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('Couldnt update', 16, 1)
			return -1
		end
	end
	fetch proj_bill_csr into @report_date, @business_unit_id, @media_product_id, @agency_deal, @branch_code, @finyear_end_1, @finyear_end_2
end

commit transaction
return 0
GO
