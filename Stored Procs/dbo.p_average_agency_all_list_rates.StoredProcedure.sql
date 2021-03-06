/****** Object:  StoredProcedure [dbo].[p_average_agency_all_list_rates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_average_agency_all_list_rates]
GO
/****** Object:  StoredProcedure [dbo].[p_average_agency_all_list_rates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_average_agency_all_list_rates]	@start_date			    datetime,
        									@end_date			    datetime,
											@country				char(1)
as

/*
 * Declare Variables
 */
 
declare @error					integer,
        @business_unit_id       integer,
        @media_product_id       integer,
        @buying_group_id        integer,
        @buying_group_desc      varchar(50),
        @band_id                integer,
        @band_desc              varchar(50),
        @agency_id              integer,
        @agency_name            varchar(50),
        @store_campaign_no	    integer,
        @campaign_no			integer,
		@product_desc			varchar(100),
		@pack_code				char(1),
		@pack_duration			smallint,
		@pack_prints			smallint,
		@pack_average_rate	    money,
        @pack_spend				money,
		@pack_spot_count		integer,
        @package_id				integer,
		@country_name			varchar(30)



/*
 * Create Results Table
 */

create table #results
(
    business_unit_id        integer             null,
    media_product_id        integer             null,
    duration_band_id        integer             null,
    duration_band_desc      varchar(30)         null,        
    buying_group_id         integer             null,
    buying_group_desc       varchar(50)         null,
	campaign_no			    integer				null,
	product_desc		    varchar(100)		null,
    agency_id               integer             null,
    agency_name             varchar(50)         null,
	pack_code			    char(1)				null,
	pack_duration		    smallint			null,
	pack_prints			    smallint			null,
	average_rate		    money				null,
	spot_count			    integer				null,
    total_spend			    money				null,
	country_name		    varchar(30)			null
)

/*
 * Initalise Variables
 */

select @store_campaign_no = 0

/*
 * Get Country_name
 */
 
select @country_name = c.country_name
  from country c
 where c.country_code = @country

/*
 * Open Cursor
 */
 declare pack_csr cursor static for
  select fc.business_unit_id,
         spot.campaign_no,
		 spot.package_id
    from film_campaign fc,
         campaign_spot spot,
         branch bra
   where fc.campaign_no = spot.campaign_no and
         spot.billing_date >= @start_date and
		 spot.billing_date <= @end_date and
         spot.spot_status <> 'P' and
         fc.branch_code = bra.branch_code and
         bra.country_code = @country
group by fc.business_unit_id,
         spot.campaign_no,
		 spot.package_id
order by spot.campaign_no ASC,
         spot.package_id ASC
     for read only
 
open pack_csr
fetch pack_csr into @business_unit_id, @campaign_no, @package_id
while(@@fetch_status=0)
begin

    /*
     * Store Campaign Information
     */

	if(@store_campaign_no <> @campaign_no)
	begin

	    select @product_desc = fc.product_desc,
               @agency_id = a.agency_id,
               @agency_name = a.agency_name,
               @buying_group_id = abg.buying_group_id,
               @buying_group_desc = abg.buying_group_desc
          from film_campaign fc, 
               agency a, 
               agency_groups ag,
               agency_buying_groups abg
         where fc.campaign_no = @campaign_no and
               fc.billing_agency = a.agency_id and
               a.agency_group_id = ag.agency_group_id and
               ag.buying_group_id = abg.buying_group_id

	end

	select @pack_code = pack.package_code,
		   @pack_duration = pack.duration,
		   @pack_prints = pack.prints,
		   @pack_average_rate = 0,
		   @pack_spot_count = 0,
           @pack_spend = 0,
           @band_id = fdb.band_id,
           @band_desc = fdb.band_desc,
           @media_product_id = pack.media_product_id
	  from campaign_package pack,
           film_duration_bands fdb
	 where pack.package_id = @package_id and
           pack.band_id = fdb.band_id


	select @pack_average_rate = avg(spot.charge_rate),
		   @pack_spot_count = count(spot.charge_rate),
           @pack_spend = sum(spot.charge_rate)
	  from campaign_spot spot
	 where spot.campaign_no = @campaign_no and
		   spot.billing_date >= @start_date and
		   spot.billing_date <= @end_date and
		   spot.package_id = @package_id and
		 ( spot.spot_type = 'S' or
		   spot.spot_type = 'Y' or
           spot.spot_type = 'C' or
		   spot.spot_type = 'B' or
		   spot.spot_type = 'C'  )

	select @pack_average_rate = isnull(@pack_average_rate,0),
		   @pack_spot_count = isnull(@pack_spot_count,0),
		   @pack_spend = isnull(@pack_spend,0)

   
	if(@pack_spot_count > 0)
    begin
    
        /*
         * Insert Results
         */
         
		insert into #results (
               business_unit_id,
               media_product_id,
               duration_band_id,
               duration_band_desc,        
               buying_group_id,
               buying_group_desc,
               campaign_no,
               product_desc,
               agency_id,
               agency_name,
               pack_code,
               pack_duration,
               pack_prints,
               average_rate,
               spot_count,
               total_spend,
               country_name ) values (
               @business_unit_id,
               @media_product_id,
               @band_id,
               @band_desc,
               @buying_group_id,
               @buying_group_desc,
               @campaign_no,
               @product_desc,
               @agency_id,
               @agency_name,
               @pack_code,
               @pack_duration,
               @pack_prints,
               @pack_average_rate,
               @pack_spot_count,
               @pack_spend,
			   @country_name )

    end

    /*
     * Fetch Next
     */

    fetch pack_csr into @business_unit_id, @campaign_no, @package_id

end
close pack_csr

/*
 * Return result Set
 */

select business_unit_id,
       media_product_id,
       duration_band_id,
       duration_band_desc,        
       buying_group_id,
       buying_group_desc,
	   campaign_no,
	   product_desc,
       agency_id,
       agency_name,
	   pack_code,
	   pack_duration,
	   pack_prints,
	   average_rate,
	   spot_count,
       total_spend,
	   country_name
  from #results

/*
 * Return Success
 */

return 0
GO
