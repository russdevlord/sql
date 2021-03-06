/****** Object:  StoredProcedure [dbo].[p_proj_bill_period_ag_buying]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_bill_period_ag_buying]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_bill_period_ag_buying]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * dbo.p_projected_bill_period_buy_agency
 * ---------------------------------------
 * This procedure generated data for variouse Agency Buying Group Analysis reports
 *
 * Args:    1. Billing period (Acct cut off date - Banchmark End Date)
 *		    2. Agency Buying Group
            3. Campaign No ( 0 - for ALL campaigns)
 *			4. Film Campaign Format = S (standart) ; D (motion graphics)
            5. Returns the Calculated Amount by reference
 *
 * Created/Modified
 * GC, 13/4/2002, Created.
 *
 * ReUsed/Modified
 * VT,  22/08/2003
 */

CREATE PROC [dbo].[p_proj_bill_period_ag_buying]    @arg_billing_period_from        datetime,
                                            @arg_billing_period_to          datetime,
                                            @arg_agency_buying_group        int,
                                            @arg_campaign_no                int,
                                            @business_unit_id               int,
                                            @media_product_id               int,
                                            @agency_deal                    char(1),
                                            @arg_country_code               char(1),
                                            @arg_billing_amount             money OUTPUT
--with recompile 
as

/*
 * Declare Variables
 */

declare     @error_num                  int,
            @row_count                  int,
            @cut_off_date               datetime,
            @leading_bill_date          datetime,
            @leading_bill_amt           money,
            @leading_bill_portion       int,
            @trailing_bill_date         datetime,
            @trailing_bill_amt          money,
            @trailing_bill_portion      int,
            @prev_bill_date             datetime,
            @prev_bill_amt              money,
            @intra_bill_amt             money,
            @total_amt                  money,
            @cnt                        int,
            @tempp                      varchar(100),
            @report_header              varchar(50)

/* in case if benchmark end date  <> end of accounting period date */
select @arg_billing_period_from = benchmark_end
from accounting_period
where end_date = @arg_billing_period_from

select @arg_billing_period_to = benchmark_end
from accounting_period
where end_date = @arg_billing_period_to

/* use local cut_off date as this may be modified and original billing_period may be required */
select @cut_off_date = @arg_billing_period_to

/* Get prev billing date */
select @prev_bill_date = max(benchmark_end)
  from accounting_period
 where benchmark_end < @arg_billing_period_from
if @prev_bill_date is null return -1

/* Adjust cutoff dates for june/december period */
if datepart(mm,@cut_off_date) in (6,12) /* june, december */
begin
    select @cut_off_date = DATEADD(dd,-1,DATEADD(mm,1,DATEADD(day,-(DATEPART(dd,@cut_off_date) - 1), CONVERT(VARCHAR,@cut_off_date,101))))
end

if datepart(mm,@prev_bill_date) in (6,12) /* june, december */
begin
    select @prev_bill_date = DATEADD(dd,-1,DATEADD(mm,1,DATEADD(day,-(DATEPART(dd,@prev_bill_date) - 1), CONVERT(VARCHAR,@prev_bill_date,101))))
end
if @cut_off_date is null return -1
if @prev_bill_date is null return -1


/* Get leading billing date (FILM) */
select @leading_bill_date = max(billing_date)
  from campaign_spot
 where billing_date <= @prev_bill_date
if @leading_bill_date is null return -1

/* Get trailing billing date (FILM) */
select @trailing_bill_date = max(billing_date)
  from campaign_spot
 where billing_date <= @cut_off_date
if @trailing_bill_date is null return -1

/* get leading and trailing billing portions */
/* leading portion is 7 minus datediff inclusive, essentially 6 - sybase datediff */
/*select @leading_bill_portion = (6 - datediff(day, @leading_bill_date, @prev_bill_date))
if (@leading_bill_portion > 7) or (@leading_bill_portion < 1) select @leading_bill_portion = 0*/
/* trailing portion is datediff inclusive, which is sybase datediff + 1 */
/*select @trailing_bill_portion = (datediff(day, @trailing_bill_date, @cut_off_date) + 1)
if (@trailing_bill_portion > 7) or (@trailing_bill_portion < 1) select @trailing_bill_portion = 0
*/
select      @total_amt = 0, @leading_bill_amt = 0, @trailing_bill_amt = 0, @intra_bill_amt = 0

/*if @business_unit_id is null
begin
    select      @total_amt = isnull(sum(charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0)
    from        campaign_spot,
                film_campaign,
                agency,
                agency_groups,
                agency_buying_groups,
                branch,
                campaign_package,
                film_screening_date_xref x
    where       campaign_spot.billing_date = x.screening_date
    and         x.benchmark_end >= @arg_billing_period_from
    and         x.benchmark_end <= @arg_billing_period_to
    and         campaign_spot.spot_status != 'P' 
    and         campaign_spot.campaign_no = film_campaign.campaign_no
    and         campaign_spot.campaign_no = campaign_package.campaign_no
    and         campaign_spot.package_id = campaign_package.package_id
    and         film_campaign.campaign_no = campaign_package.campaign_no
    and         film_campaign.agency_deal = @agency_deal
    and         campaign_package.media_product_id = @media_product_id
    and         ( film_campaign.campaign_no = @arg_campaign_no 
    or          @arg_campaign_no = 0 )
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
    and         film_campaign.branch_code = branch.branch_code 
    and         branch.country_code = @arg_country_code
end
else if @media_product_id is null
begin
    select      @total_amt = isnull(sum(charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0)
    from        campaign_spot,
                film_campaign,
                agency,
                agency_groups,
                agency_buying_groups,
                branch,
                campaign_package,
                film_screening_date_xref x
    where       campaign_spot.billing_date = x.screening_date
    and         x.benchmark_end >= @arg_billing_period_from
    and         x.benchmark_end <= @arg_billing_period_to
    and         campaign_spot.spot_status != 'P' 
    and         campaign_spot.campaign_no = film_campaign.campaign_no
    and         campaign_spot.campaign_no = campaign_package.campaign_no
    and         campaign_spot.package_id = campaign_package.package_id
    and         film_campaign.campaign_no = campaign_package.campaign_no
    and         film_campaign.business_unit_id = @business_unit_id
    and         film_campaign.agency_deal = @agency_deal
    and         ( film_campaign.campaign_no = @arg_campaign_no 
    or          @arg_campaign_no = 0 )
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
    and         film_campaign.branch_code = branch.branch_code 
    and         branch.country_code = @arg_country_code
end
else if @agency_deal is null
begin
    select      @total_amt = isnull(sum(charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0)
    from        campaign_spot,
                film_campaign,
                agency,
                agency_groups,
                agency_buying_groups,
                branch,
                campaign_package,
                film_screening_date_xref x
    where       campaign_spot.billing_date = x.screening_date
    and         x.benchmark_end >= @arg_billing_period_from
    and         x.benchmark_end <= @arg_billing_period_to
    and         campaign_spot.spot_status != 'P' 
    and         campaign_spot.campaign_no = film_campaign.campaign_no
    and         campaign_spot.campaign_no = campaign_package.campaign_no
    and         campaign_spot.package_id = campaign_package.package_id
    and         film_campaign.campaign_no = campaign_package.campaign_no
    and         film_campaign.business_unit_id = @business_unit_id
    and         campaign_package.media_product_id = @media_product_id
    and         ( film_campaign.campaign_no = @arg_campaign_no 
    or          @arg_campaign_no = 0 )
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
    and         film_campaign.branch_code = branch.branch_code 
    and         branch.country_code = @arg_country_code
end*/

select      @leading_bill_amt = isnull(sum(campaign_spot.charge_rate) * @leading_bill_portion / 7 , 0)
from        campaign_spot,
            film_campaign,
            agency,
            agency_groups,
            agency_buying_groups,
            branch,
            campaign_package
where       campaign_spot.billing_date = @leading_bill_date 
and         campaign_spot.spot_status <> 'P' 
and         campaign_spot.campaign_no = film_campaign.campaign_no
and         campaign_spot.campaign_no = campaign_package.campaign_no
and         campaign_spot.package_id = campaign_package.package_id
and         film_campaign.campaign_no = campaign_package.campaign_no
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         campaign_package.media_product_id = @media_product_id
and         ( film_campaign.campaign_no = @arg_campaign_no 
or          @arg_campaign_no = 0 )
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
and         film_campaign.branch_code = branch.branch_code 
and         branch.country_code = @arg_country_code

select      @leading_bill_amt = @leading_bill_amt + isnull(sum(cinelight_spot.charge_rate) * @leading_bill_portion / 7 , 0)
from        cinelight_spot,
            film_campaign,
            agency,
            agency_groups,
            agency_buying_groups,
            branch,
            cinelight_package
where       cinelight_spot.billing_date = @leading_bill_date 
and         cinelight_spot.spot_status <> 'P' 
and         cinelight_spot.campaign_no = film_campaign.campaign_no
and         cinelight_spot.campaign_no = cinelight_package.campaign_no
and         cinelight_spot.package_id = cinelight_package.package_id
and         film_campaign.campaign_no = cinelight_package.campaign_no
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         cinelight_package.media_product_id = @media_product_id
and         ( film_campaign.campaign_no = @arg_campaign_no 
or          @arg_campaign_no = 0 )
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
and         film_campaign.branch_code = branch.branch_code 
and         branch.country_code = @arg_country_code

select      @trailing_bill_amt = isnull(sum(campaign_spot.charge_rate) * @trailing_bill_portion / 7 , 0)
from        campaign_spot,
            film_campaign,
            agency,
            agency_groups,
            agency_buying_groups,
            branch,
            campaign_package
where       campaign_spot.billing_date = @trailing_bill_date 
and         campaign_spot.spot_status <> 'P' 
and         campaign_spot.campaign_no = film_campaign.campaign_no
and         campaign_spot.campaign_no = campaign_package.campaign_no
and         campaign_spot.package_id = campaign_package.package_id
and         film_campaign.campaign_no = campaign_package.campaign_no
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         campaign_package.media_product_id = @media_product_id
and         ( film_campaign.campaign_no = @arg_campaign_no 
or          @arg_campaign_no = 0 )
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
and         film_campaign.branch_code = branch.branch_code 
and         branch.country_code = @arg_country_code

select      @trailing_bill_amt = @trailing_bill_amt + isnull(sum(cinelight_spot.charge_rate) * @trailing_bill_portion / 7 , 0)
from        cinelight_spot,
            film_campaign,
            agency,
            agency_groups,
            agency_buying_groups,
            branch,
            cinelight_package
where       cinelight_spot.billing_date = @trailing_bill_date 
and         cinelight_spot.spot_status <> 'P' 
and         cinelight_spot.campaign_no = film_campaign.campaign_no
and         cinelight_spot.campaign_no = cinelight_package.campaign_no
and         cinelight_spot.package_id = cinelight_package.package_id
and         film_campaign.campaign_no = cinelight_package.campaign_no
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         cinelight_package.media_product_id = @media_product_id
and         ( film_campaign.campaign_no = @arg_campaign_no 
or          @arg_campaign_no = 0 )
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
and         film_campaign.branch_code = branch.branch_code 
and         branch.country_code = @arg_country_code

select      @intra_bill_amt = isnull(sum(campaign_spot.charge_rate) , 0)
from        campaign_spot,
            film_campaign,
            agency,
            agency_groups,
            agency_buying_groups,
            branch,
            campaign_package
where       campaign_spot.billing_date > @leading_bill_date 
and         campaign_spot.billing_date < @trailing_bill_date 
and         campaign_spot.spot_status <> 'P' 
and         campaign_spot.campaign_no = film_campaign.campaign_no
and         campaign_spot.campaign_no = campaign_package.campaign_no
and         campaign_spot.package_id = campaign_package.package_id
and         film_campaign.campaign_no = campaign_package.campaign_no
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         campaign_package.media_product_id = @media_product_id
and         ( film_campaign.campaign_no = @arg_campaign_no 
or          @arg_campaign_no = 0 )
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
and         film_campaign.branch_code = branch.branch_code 
and         branch.country_code = @arg_country_code

select      @intra_bill_amt = @intra_bill_amt + isnull(sum(cinelight_spot.charge_rate) , 0)
from        cinelight_spot,
            film_campaign,
            agency,
            agency_groups,
            agency_buying_groups,
            branch,
            cinelight_package
where       cinelight_spot.billing_date > @leading_bill_date 
and         cinelight_spot.billing_date < @trailing_bill_date 
and         cinelight_spot.spot_status <> 'P' 
and         cinelight_spot.campaign_no = film_campaign.campaign_no
and         cinelight_spot.campaign_no = cinelight_package.campaign_no
and         cinelight_spot.package_id = cinelight_package.package_id
and         film_campaign.campaign_no = cinelight_package.campaign_no
and         (film_campaign.business_unit_id = @business_unit_id
or          @business_unit_id is null)
and         (film_campaign.agency_deal = @agency_deal
or          @agency_deal is null)
and         cinelight_package.media_product_id = @media_product_id
and         ( film_campaign.campaign_no = @arg_campaign_no 
or          @arg_campaign_no = 0 )
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         agency_buying_groups.buying_group_id = @arg_agency_buying_group
and         film_campaign.branch_code = branch.branch_code 
and         branch.country_code = @arg_country_code

select @total_amt = @leading_bill_amt + @trailing_bill_amt + @intra_bill_amt

select @arg_billing_amount = @total_amt

return 0
GO
