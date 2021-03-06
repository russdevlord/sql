/****** Object:  StoredProcedure [dbo].[p_delete_charge_rpt_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_charge_rpt_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_charge_rpt_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_charge_rpt_sub]     @campaign_no        int,
                                        @media_product_id   int
as

/*
 * Declare Variables
 */

declare @error								int,
        @errorode								int,
	    @product_desc						varchar(100),
		@dandc_amount						money,
		@dandc_confirmed_amount		    	money,
   		@dandc_unconfirmed_amount		    money,
        @nett_contract_value                money,
        @dest_campaign                      int

/*
 * Create Temporary Table
 */

create table #delete_charge
(
	campaign_no						int,
	product_desc					varchar(100),
	dandc_confirmed_amount		    money,
	dandc_unconfirmed_amount		money,
    nett_contract                   money
)

/*
 * Create Campaign Cursor
 */

 declare campaign_csr cursor static for
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost
    from film_campaign fc,
         delete_charge,
         campaign_package
   where delete_charge.source_campaign = @campaign_no and
         delete_charge.destination_campaign = fc.campaign_no and
         fc.campaign_no = campaign_package.campaign_no and
         campaign_package.media_product_id = @media_product_id
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost        
order by fc.campaign_no
    for read only

/*
 * Loop Cursor
 */

open campaign_csr
fetch campaign_csr into @dest_campaign, @product_desc, @nett_contract_value
while( @@fetch_status = 0)
begin

	/*
	 * Get confirmed allocated dandc spots
	 */
	
	select @dandc_confirmed_amount = isnull(sum(campaign_spot.charge_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
           spot_type <> 'D' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'Y' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id and
           delete_charge.destination_campaign = @dest_campaign  and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
             
	select @dandc_confirmed_amount = @dandc_confirmed_amount + isnull(sum(makegood_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
           spot_type = 'D' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'Y' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id and
           delete_charge.destination_campaign = @dest_campaign and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
           
	/*
	 * Get unconfirmed allocated dandc spots
	 */
	
	select @dandc_unconfirmed_amount = isnull(sum(campaign_spot.charge_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
           spot_type <> 'D' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'N' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id and
           delete_charge.destination_campaign = @dest_campaign and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
             
	select @dandc_unconfirmed_amount = @dandc_unconfirmed_amount + isnull(sum(makegood_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
           spot_type = 'D' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'N' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id and
           delete_charge.destination_campaign = @dest_campaign and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id

  /*
   * Insert values into temp table
   */
	

	insert into #delete_charge (
							campaign_no, 
							product_desc, 
							dandc_confirmed_amount,
                            dandc_unconfirmed_amount,
                            nett_contract) values ( 
							@dest_campaign, 
							@product_desc, 
                            @dandc_confirmed_amount,
                            @dandc_unconfirmed_amount,
                            @nett_contract_value )


   /*
    * fetch Next Row
    */

	fetch campaign_csr into @dest_campaign, @product_desc, @nett_contract_value

end
close campaign_csr
deallocate campaign_csr

/*
 * Return Dataset
 */

select * 
  from #delete_charge

/*
 * Return Success
 */

return 0
GO
