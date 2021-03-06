/****** Object:  StoredProcedure [dbo].[p_projected_bill_calc_bu]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_bill_calc_bu]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_bill_calc_bu]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_projected_bill_calc_bu
 * --------------------------
 * This procedure generated data for the Projected Billing report for accounting
 *
 * Args:    1. Billing period (Acct cut off date)
 *		    2. Branch code
 *			3. Product Type - 1=campaign_format=Standard, 2=campaign_format=Designer
 *
 * Created/Modified
 * GC, 13/4/2002, Created.
 */

CREATE PROC [dbo].[p_projected_bill_calc_bu]    @billing_period	            datetime,
                                            @branch_code                char(1),
                                            @business_unit_id           int,
                                            @media_product_id           int,
                                            @billing_amount             money OUTPUT
with recompile                                            
as

/*
 * Declare Variables
 */

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


/* use local cut_off date as this may be modified and original billing_period may be required */
select @cut_off_date = @billing_period

/* Get prev billing date */
select @prev_bill_date = max(benchmark_end)
  from accounting_period
 where benchmark_end < @cut_off_date
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
select @leading_bill_portion = (6 - datediff(day, @leading_bill_date, @prev_bill_date))
if (@leading_bill_portion > 7) or (@leading_bill_portion < 1) select @leading_bill_portion = 0
/* trailing portion is datediff inclusive, which is sybase datediff + 1 */
select @trailing_bill_portion = (datediff(day, @trailing_bill_date, @cut_off_date) + 1)
if (@trailing_bill_portion > 7) or (@trailing_bill_portion < 1) select @trailing_bill_portion = 0

select     @leading_bill_amt = 0, @trailing_bill_amt = 0, @intra_bill_amt = 0

select     @leading_bill_amt = isnull(sum(spot.charge_rate) * @leading_bill_portion / 7 , 0)
	 from  campaign_spot spot,
		   film_campaign fc,
           campaign_package cp
   where   spot.billing_date = @leading_bill_date and
           spot.spot_status != 'P' and
		   fc.branch_code = @branch_code and
           fc.campaign_no = cp.campaign_no and
           cp.package_id = spot.package_id 
and        business_unit_id = @business_unit_id
and        cp.media_product_id = @media_product_id


select     @trailing_bill_amt = isnull(sum(spot.charge_rate) * @trailing_bill_portion / 7 , 0)
	 from  campaign_spot spot,
		   film_campaign fc,
           campaign_package cp
   where   spot.billing_date = @trailing_bill_date and
            spot.spot_status != 'P' and
		   fc.branch_code = @branch_code and
           fc.campaign_no = cp.campaign_no and
           cp.package_id = spot.package_id 
and        business_unit_id = @business_unit_id
and        cp.media_product_id = @media_product_id

select     @intra_bill_amt = isnull(sum(spot.charge_rate) , 0)
	 from  campaign_spot spot,
		   film_campaign fc,
           campaign_package cp
   where   spot.billing_date > @leading_bill_date and
           spot.billing_date < @trailing_bill_date and
            spot.spot_status != 'P' and
		   fc.branch_code = @branch_code and
           fc.campaign_no = cp.campaign_no and
           cp.package_id = spot.package_id 
and        business_unit_id = @business_unit_id
and        cp.media_product_id = @media_product_id

select @total_amt = @leading_bill_amt + @trailing_bill_amt + @intra_bill_amt

select @billing_amount = @total_amt

return 0
GO
