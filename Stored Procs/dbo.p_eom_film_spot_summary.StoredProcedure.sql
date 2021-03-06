/****** Object:  StoredProcedure [dbo].[p_eom_film_spot_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_spot_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_spot_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_eom_film_spot_summary] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			int,
        @rowcount     			int,
        @errorode				int,
        @errno					int,
        @campaign_no			int,
		@country_code			char(1),
        @complex_id				int,
        @billing_total 			money,
        @commission_total 		money,
        @payment_total 			money,
        @baddebt_total 			money,
        @billing_w_total 		money,
        @commission_w_total 	money,
        @payment_w_total 		money,
        @baddebt_w_total 		money,
        @rent_allocated 		money,
        @rent_released 			money,
        @rent_cancelled 		money,
        @cplx_csr_open			tinyint,
		@product_desc			varchar(100),
        @business_unit_id       int,
        @media_product_id       int,
        @revenue_source         char(1)
        
/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Existing Summary Data
 */

delete film_spot_summary
where accounting_period = @accounting_period

select @errno = @@error
if(@error != 0)
begin
	rollback transaction
	raiserror ('Film Spot Summary: Error inserting summary information.', 16, 1)
	return -1
end

/*
 * Insert Film Spot Summary Data
 */

insert into		film_spot_summary
(
				campaign_no,
				accounting_period,
				complex_id,
				media_product_id,
				business_unit_id,
				billing_total,
				commission_total,
				payment_total,
				bad_debt_total,
				rent_allocated,
				rent_released,
				rent_cancelled,
				country_code,
				revenue_source,
				product_desc,
				weighted_billings,
				weighted_commission,
				weighted_payment,
				weighted_bad_debt
)
select			campaign_no,
				@accounting_period,
				complex_id,
				media_product_id,
				business_unit_id,
				(select			isnull(sum(isnull(v_fssa.billing_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (1, 2, 7) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as billing_total,
				(select			isnull(sum(isnull(v_fssa.billing_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (3) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as commission_total,
				(select			isnull(sum(isnull(v_fssa.billing_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (6) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as payment_total,
				(select			isnull(sum(isnull(v_fssa.billing_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (4) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as bad_debt_total,
				(select			isnull(sum(isnull(v_fssa.cinema_rent_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.cancelled = 0 
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as rent_allocated,
				(select			isnull(sum(isnull(v_fssa.cinema_rent_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.release_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.cancelled = 0 
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as rent_released,
				(select			isnull(sum(isnull(v_fssa.cinema_rent_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.cancelled = 0 
				and				v_fssa.original_liability = 0 
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as rent_cancelled,
				v_fss.country_code,
				v_fss.revenue_source,
				v_fss.product_desc,
				(select			isnull(sum(isnull(v_fssa.billing_w_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (1, 2, 7) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as weighted_billings,
				(select			isnull(sum(isnull(v_fssa.billing_w_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (3) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as weighted_commission,
				(select			isnull(sum(isnull(v_fssa.billing_w_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (6) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as weighted_payment,
				(select			isnull(sum(isnull(v_fssa.billing_w_total,0)),0)
				from			v_film_spot_summary_amounts v_fssa
				where			v_fssa.creation_period = @accounting_period 
				and				v_fssa.campaign_no = v_fss.campaign_no 
				and				v_fssa.complex_id = v_fss.complex_id 
				and				v_fssa.original_liability = 0 
				and				v_fssa.liability_category_id in (4) -- Billings, Billing Credit, Contra Billings
				and				v_fssa.media_product_id = v_fss.media_product_id 
				and				v_fssa.revenue_source = v_fss.revenue_source) as weighted_bad_debt
from			v_film_spot_summary v_fss
where			(release_period = @accounting_period 
or				creation_period = @accounting_period)
group by		campaign_no, 
				product_desc,
				country_code,
				complex_id,
				media_product_id, 
				revenue_source,
				business_unit_id

select			@error = @@error

if(@error != 0)
begin
	rollback transaction
	raiserror ('Film Spot Summary: Error inserting summary information.', 16, 1)
	return -1
end

commit transaction
return 0
GO
