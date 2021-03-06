/****** Object:  StoredProcedure [dbo].[p_film_inv_bills_proj_bra_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_inv_bills_proj_bra_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_film_inv_bills_proj_bra_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_film_inv_bills_proj_bra_rpt] @accounting_period	datetime,
				      @country_code		char(1)
as

/*
 * Select Dataset
 */
      
 select b.country_code as 'Country Code',
         b.branch_code as 'Branch Code',
         pack.media_product_id as 'Media Product',
         spot.billing_period as 'Billing Period',
         sum(spot.charge_rate) as 'Billings',
		 fc.business_unit_id  as 'Business Unit'
    from campaign_spot spot,
	     film_campaign fc,
         campaign_package pack,
         branch b
   where spot.campaign_no = pack.campaign_no and
         spot.package_id = pack.package_id and
         spot.spot_status <> 'P' and
         spot.billing_period >= @accounting_period and
         spot.campaign_no = fc.campaign_no and
         fc.branch_code = b.branch_code and
         b.country_code = @country_code
group by b.country_code,
         b.branch_code,
         pack.media_product_id,
         spot.billing_period,
		 fc.business_unit_id

/*
 * Return Success
 */
 
return 0
GO
