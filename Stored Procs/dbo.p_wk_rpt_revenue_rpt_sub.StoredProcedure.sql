/****** Object:  StoredProcedure [dbo].[p_wk_rpt_revenue_rpt_sub]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wk_rpt_revenue_rpt_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_wk_rpt_revenue_rpt_sub]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc [dbo].[p_wk_rpt_revenue_rpt_sub] 	@start_date  							datetime, 
											@end_date  								datetime,
											@prev_start_date						datetime,
											@prev_end_date							datetime,
											@business_unit_id						int,
											@media_product_id						int, 
											@gross_revenue							money output,
											@agency_commission						money output,
											@last_year_gross_revenue				money output,
											@last_year_agency_commission			money output,
											@theatre_rent							money output,
											@last_year_theatre_rent					money output

AS

declare		@error				int


select 	@gross_revenue = sum(isnull(b.billings,0)),
		@agency_commission = sum(isnull(b.agency_commission,0)),
		@theatre_rent = sum(isnull(b.net_billings,0) * isnull(ce.percentage_entitlement,0))
from	#billings b,
		#cag_entitlements ce
where	business_unit_id = @business_unit_id
and		media_product_id = @media_product_id
and		b.complex_id = ce.complex_id
and		b.revenue_source = ce.revenue_source
and		b.billing_date >= @start_date 
and 	b.billing_date <= @end_date


select @error = @@error

if @error != 0 
begin
	raiserror ('Error obtaining revenue figures', 16, 1)
	return -1
end

select 	@last_year_gross_revenue = sum(isnull(b.billings,0)),
		@last_year_agency_commission = sum(isnull(b.agency_commission,0)),
		@last_year_theatre_rent = sum(isnull(b.net_billings,0) * isnull(ce.percentage_entitlement,0))
from	#billings b,
		#cag_entitlements ce
where	business_unit_id = @business_unit_id
and		media_product_id = @media_product_id
and		b.complex_id = ce.complex_id
and		b.revenue_source = ce.revenue_source
and		b.billing_date between @prev_start_date and @prev_end_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error obtaining revenue figures', 16, 1)
	return -1
end

return 0
GO
