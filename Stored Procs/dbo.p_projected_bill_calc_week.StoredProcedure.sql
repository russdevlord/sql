/****** Object:  StoredProcedure [dbo].[p_projected_bill_calc_week]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_bill_calc_week]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_bill_calc_week]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_projected_bill_calc_week]    @billing_date	datetime,
                                          @branch_code char(1),
                                          @business_unit_id int,
                                          @media_product_id int,
                                          @agency_deal  char(1),
                                          @billing_amount money OUTPUT
as




select    @billing_amount = isnull(sum(spot.charge_rate) , 0)
	 from  campaign_spot spot,
		   film_campaign fc,
           campaign_package cp
   where   spot.billing_date = @billing_date and
            spot.spot_status <> 'P' and
		   spot.campaign_no = fc.campaign_no and
		   fc.branch_code = @branch_code and
           fc.campaign_status != 'P' and
           cp.package_id = spot.package_id
and        (business_unit_id = @business_unit_id or @business_unit_id is null)
and        cp.media_product_id = @media_product_id
and        (fc.agency_deal = @agency_deal or @agency_deal is null)

select 	@billing_amount = @billing_amount + isnull(sum(spot.charge_rate) , 0)
	 from  cinelight_spot spot,
		   film_campaign fc,
           cinelight_package cp
   where   spot.billing_date = @billing_date and
            spot.spot_status <> 'P' and
		   spot.campaign_no = fc.campaign_no and
		   fc.branch_code = @branch_code and
           fc.campaign_status != 'P' and
           cp.package_id = spot.package_id
and        (business_unit_id = @business_unit_id or @business_unit_id is null)
and        cp.media_product_id = @media_product_id
and        (fc.agency_deal = @agency_deal or @agency_deal is null)

           
return 0
GO
