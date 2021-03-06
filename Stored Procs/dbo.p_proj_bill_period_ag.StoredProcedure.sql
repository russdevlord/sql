/****** Object:  StoredProcedure [dbo].[p_proj_bill_period_ag]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_bill_period_ag]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_bill_period_ag]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_proj_bill_period_ag]  @arg_billing_period_from      		datetime,
                                          @arg_billing_period_to      	datetime,
                                           @arg_agency_id           	integer,
                                           @arg_campaign_no         	integer,
                                            @business_unit_id           integer,
                                            @media_product_id         	integer,
                                            @agency_deal                char(1),
                                           @arg_country_code            char(1),
                                           @arg_billing_amount      	money OUTPUT
with recompile 
as



declare     @error_num               int,
            @row_count               int,
            @cut_off_date            datetime,
            @leading_bill_date       datetime,
            @leading_bill_amt        money,
            @leading_bill_portion    int,
            @trailing_bill_date      datetime,
            @trailing_bill_amt       money,
            @trailing_bill_portion   int,
            @prev_bill_date          datetime,
            @prev_bill_amt           money,
            @intra_bill_amt          money,
            @total_amt               money


select @arg_billing_period_from = benchmark_end
from accounting_period
where end_date = @arg_billing_period_from

select @arg_billing_period_to = benchmark_end
from accounting_period
where end_date = @arg_billing_period_to

select     	@arg_billing_amount = sum(isnull(cs.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)) 
from 		v_spots_non_proposed cs,
			film_screening_date_xref x,
			film_campaign,
			agency,
			branch,
			campaign_package
where   	cs.billing_date = x.screening_date
and			x.benchmark_end >= @arg_billing_period_from
and			x.benchmark_end <= @arg_billing_period_to
and			cs.campaign_no = film_campaign.campaign_no 
and         cs.package_id = campaign_package.package_id
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         campaign_package.media_product_id = @media_product_id
and			( film_campaign.campaign_no = @arg_campaign_no 
or 			@arg_campaign_no = 0 ) 
and			film_campaign.reporting_agency = agency.agency_id 
and			agency.agency_id = @arg_agency_id 
and			film_campaign.branch_code = branch.branch_code 
and			branch.country_code = @arg_country_code

return 0
GO
