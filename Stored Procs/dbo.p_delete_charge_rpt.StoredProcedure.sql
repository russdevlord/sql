/****** Object:  StoredProcedure [dbo].[p_delete_charge_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_charge_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_charge_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_charge_rpt]  
as

/*
 * Declare Variables
 */

declare @error								int,
        @errorode								int,
        @campaign_no						int,
	    @product_desc						varchar(100),
        @start_date							datetime,
        @end_date							datetime,
        @first_name							varchar(30),
        @last_name							varchar(30),
		@branch_name						varchar(50),
		@campaign_type					    varchar(30),
		@dandc_amount						money,
		@dandc_confirmed_amount		    	money,
   		@dandc_unconfirmed_amount		    money,
		@dandc_unallocated_amount		    money,
        @nett_contract_value                money,
        @business_unit_id                   int,
        @business_unit_desc                 varchar(30),
        @media_product_id                   int,
        @media_product_desc                 varchar(30)

/*
 * Create Temporary Table
 */

create table #delete_charge
(
	campaign_no						int,
	product_desc					varchar(100),
    start_date						datetime,
    end_date						datetime,
    first_name						varchar(30),
    last_name						varchar(30),
	branch_name						varchar(50),
	campaign_type    				varchar(30),
	dandc_amount					money,
	dandc_confirmed_amount		    money,
	dandc_unconfirmed_amount		money,
    dandc_unallocated_amount		money,
    nett_contract                   money,
    business_unit_id                int,
    business_unit_desc              varchar(30),
    media_product_id                int,
    media_product_desc              varchar(30)
)

/*
 * Create Campaign Cursor
 */

 declare campaign_csr cursor static for
  select fc.campaign_no,
         fc.product_desc,
         fc.start_date,
         fc.end_date,
         sr.first_name,
         sr.last_name,
		 br.branch_name,
		 ct.campaign_type_desc,
         fc.confirmed_cost,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from film_campaign fc,
         sales_rep sr,
		 campaign_type ct,
		 branch br,
		 campaign_spot cs,
         campaign_package cp,
         business_unit bu,
         media_product mp
   where fc.rep_id = sr.rep_id and
		 fc.branch_code = sr.branch_code and
		 sr.branch_code = br.branch_code and
		 fc.campaign_type = ct.campaign_type_code and
		 fc.campaign_no = cs.campaign_no and
		 cs.dandc = 'Y' and
         cp.campaign_no = cs.campaign_no and
         cp.package_id = cs.package_id and
         fc.campaign_no = cp.campaign_no and
         bu.business_unit_id = fc.business_unit_id and
         cp.media_product_id = mp.media_product_id
group by fc.campaign_no,
         fc.product_desc,
         fc.start_date,
         fc.end_date,
         sr.first_name,
         sr.last_name,
		 br.branch_name,
		 ct.campaign_type_desc,
         fc.confirmed_cost,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
order by fc.campaign_no
    for read only


/*
 * Loop Cursor
 */

open campaign_csr
fetch campaign_csr into @campaign_no,
                        @product_desc,
                        @start_date, 
                        @end_date, 
                        @first_name, 
                        @last_name, 
                        @branch_name, 
                        @campaign_type, 
                        @nett_contract_value, 
                        @business_unit_id,
                        @business_unit_desc,
                        @media_product_id,
                        @media_product_desc
while( @@fetch_status = 0)
begin

    /*
	 * Get the value of DandC spots
	 */ 
	
	select @dandc_amount = isnull(sum(campaign_spot.charge_rate),0)
	  from campaign_spot,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
		   spot_status = 'C' and
		   dandc = 'Y' and
           spot_type <> 'D' and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
           
           
	select @dandc_amount = @dandc_amount + isnull(sum(makegood_rate),0)
	  from campaign_spot,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
		   spot_status = 'C' and
		   dandc = 'Y' and
           spot_type = 'D' and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
	
	/*
	 * Get confirmed allocated dandc spots
	 */
	
	select @dandc_confirmed_amount = isnull(sum(campaign_spot.charge_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
		   spot_status = 'C' and
           spot_type <> 'D' and
		   dandc = 'Y' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'Y' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id  and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
             
	select @dandc_confirmed_amount = @dandc_confirmed_amount + isnull(sum(makegood_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
		   spot_status = 'C' and
           spot_type = 'D' and
		   dandc = 'Y' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'Y' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id  and
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
		   spot_status = 'C' and
           spot_type <> 'D' and
		   dandc = 'Y' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'N' and 
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id  and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id
             
	select @dandc_unconfirmed_amount = @dandc_unconfirmed_amount + isnull(sum(makegood_rate),0)
	  from campaign_spot,
		   delete_charge_spots,
           delete_charge,
           campaign_package
	 where campaign_spot.campaign_no = @campaign_no and
		   spot_status = 'C' and
           spot_type = 'D' and
		   dandc = 'Y' and
		   delete_charge_spots.spot_id = campaign_spot.spot_id and
		   delete_charge_spots.source_dest = 'S' and
           delete_charge.confirmed = 'N' and
           delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id  and
           campaign_spot.campaign_no = campaign_package.campaign_no and
           campaign_spot.package_id = campaign_package.package_id and
           campaign_package.media_product_id = @media_product_id

    /*
     * Calculate Unallocated Portion
     */             
	
	select @dandc_unallocated_amount = @dandc_amount - @dandc_confirmed_amount - @dandc_unconfirmed_amount


  /*
   * Insert values into temp table
   */
	
	if ( @dandc_unallocated_amount <> 0 ) or  ( @dandc_unconfirmed_amount <> 0 ) 

	begin
		insert into #delete_charge (
								campaign_no, 
								product_desc, 
								start_date, 
  								end_date, 
								first_name, 
								last_name, 
								branch_name, 
								campaign_type,												
								dandc_amount,
								dandc_confirmed_amount,
                                dandc_unconfirmed_amount,
								dandc_unallocated_amount,
                                nett_contract,
                                business_unit_id,
                                business_unit_desc,
                                media_product_id,
                                media_product_desc) values ( 
								@campaign_no, 
								@product_desc, 
								@start_date, 
  								@end_date, 
								@first_name, 
								@last_name, 
								@branch_name, 
								@campaign_type,												
								@dandc_amount,
                                @dandc_confirmed_amount,
                                @dandc_unconfirmed_amount,
								@dandc_unallocated_amount,
                                @nett_contract_value,
                                @business_unit_id,
                                @business_unit_desc,
                                @media_product_id,
                                @media_product_desc)
	end

   /*
    * fetch Next Row
    */

	    fetch campaign_csr into @campaign_no,
                            @product_desc,
                            @start_date, 
                            @end_date, 
                            @first_name, 
                            @last_name, 
                            @branch_name, 
                            @campaign_type, 
                            @nett_contract_value, 
                            @business_unit_id,
                            @business_unit_desc,
                            @media_product_id,
                            @media_product_desc


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
