/****** Object:  StoredProcedure [dbo].[p_check_proj_bill]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_proj_bill]
GO
/****** Object:  StoredProcedure [dbo].[p_check_proj_bill]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_check_proj_bill]
as
declare @error		int,
			@report_date	datetime,
			@finyear_end_1	datetime,
			@finyear_end_2	datetime,
			@ftr_amount		money,
			@next_year_amount	money

set nocount on

create table #results
(
report_date			datetime			null,
ftr_amount			money				null,
next_year_amount	money				null
)

declare	proj_bill_csr cursor forward_only static for
select distinct report_date
from projected_billings
order by report_date


open proj_bill_csr
fetch proj_bill_csr into @report_date
while(@@fetch_status=0)
begin

	select @finyear_end_1 = min(finyear_end) from projected_billings where report_date = @report_date
	select @finyear_end_2 = max(finyear_end) from projected_billings where report_date = @report_date

	select @ftr_amount = sum(billings_future) from projected_billings where report_date = @report_date and finyear_end = @finyear_end_1

	select @next_year_amount = sum(billings_future + billings_month_01 + billings_month_02 + billings_month_03 + billings_month_04 + billings_month_05 + billings_month_06 + billings_month_07 + billings_month_08 + billings_month_09 + billings_month_10 + billings_month_11 + billings_month_12) from projected_billings where report_date = @report_date and finyear_end = @finyear_end_2

	insert into 	#results values (@report_date, @ftr_amount, @next_year_amount)

	fetch proj_bill_csr into @report_date
end


select * from #results order by report_date
return 0
GO
