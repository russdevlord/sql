/****** Object:  StoredProcedure [dbo].[p_film_aged_trial_bal_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_aged_trial_bal_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_film_aged_trial_bal_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_film_aged_trial_bal_rpt] @country_code char(1)
as

/*
 * Declare Variables
 */

declare	@agency_deal		    char(1),
		@campaign_no		    integer,
		@product_desc		    varchar(100),
		@branch_name		    varchar(50),
		@client_name		    varchar(50),
		@commission			    money,
		@balance_credit	        money,
		@balance_120		    money,
		@balance_90			    money,
		@balance_60			    money,
		@balance_30			    money,
		@balance_current	    money,
		@balance_outstnd	    money,
		@country_name 		    varchar(30),
		@address_1			    varchar(50),
		@address_2			    varchar(50),
		@town_suburb		    varchar(30),
		@state_code			    char(3),
		@postcode			    varchar(5),
        @business_unit_desc     varchar(30),
       @rep_name							 varchar(100),
       @campaign_status				char(1)
       
/*
 * Create Temp Table
 */                                      

create table #results
(
    campaign_no						integer				null,   
    product_desc					varchar(100)		null,   
    commission							money					null,   
    balance_credit					money					null,   
    balance_120						money					null,   
    balance_90						money					null,   
    balance_60						money					null,   
    balance_30						money					null,   
    balance_current			    money					null,   
    balance_outstanding		money					null,   
    branch_name						varchar(50)		null,
    client_name						varchar(50)		null,   
    country_name					varchar(30)		null,
	address1								varchar(50)		null,
	address2  							varchar(50)		null,
	town_suburb						varchar(30)		null,
	state_code							char(3)				null,
	postcode								varchar(5)			null,
    business_unit_desc          varchar(30)		null,
    rep_name							varchar(100)		null,
    campaign_status				char(1)				null
)

/*
 * Declare Cursors
 */                           

 declare campaign_csr cursor static for
  select fc.agency_deal,		  
         fc.campaign_no,   
         fc.product_desc,   
         fc.commission,   
         fc.balance_credit,   
         fc.balance_120,   
         fc.balance_90,   
         fc.balance_60,   
         fc.balance_30,   
         fc.balance_current,   
         fc.balance_outstanding,   
		 branch.branch_name,   
         client.client_name,   
         country.country_name,
         bu.business_unit_desc,
         sales_rep.first_name + ' ' + sales_rep.last_name,
         fc.campaign_status
    FROM business_unit bu,
         film_campaign fc,   
         client,   
         branch,   
         country ,
         sales_rep
   WHERE fc.client_id = client.client_id and  
         fc.branch_code = branch.branch_code and  
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and  
         branch.country_code = @country_code and
	   ( fc.campaign_status = 'L' or
	     fc.campaign_status = 'F' ) and
	     fc.rep_id = sales_rep.rep_id and
		 fc.business_unit_id not in (6,7,8, 10)
     for read only

/*
 * Loop over campaigns retriving balance info
 */

open campaign_csr
fetch campaign_csr into @agency_deal, @campaign_no, @product_desc, @commission, @balance_credit, @balance_120, @balance_90, @balance_60, @balance_30, @balance_current, @balance_outstnd, @branch_name, @client_name, @country_name, @business_unit_desc, @rep_name, @campaign_status
while (@@fetch_status = 0)
begin

   /*
    * Get agency or client details
    */                                                                                                                                              

	if(@agency_deal = 'Y')
	begin
		select @address_1 = a.address_1,
        	       @address_2 = a.address_2,
		   @town_suburb = a.town_suburb,
		   @state_code = a.state_code,
		   @postcode = a.postcode
          from film_campaign fc,
		   agency a
         where fc.billing_agency = a.agency_id and
		   fc.campaign_no = @campaign_no

	end
	else
	begin

		select @address_1 = c.address_1,
               @address_2 = c.address_2,
		   @town_suburb = c.town_suburb,
		   @state_code = c.state_code,
		   @postcode = c.postcode
          from film_campaign fc,
	       client c
	  where fc.client_id = c.client_id and
		   fc.campaign_no = @campaign_no

   end
  
    /*
	 * Insert results into temp table
     */

	insert into #results ( 
           campaign_no,   
		   product_desc,   
		   commission,   
		   balance_credit,   
		   balance_120,   
		   balance_90,   
		   balance_60,   
		   balance_30,   
		   balance_current,   
		   balance_outstanding,   
		   branch_name,
		   client_name,   
		   country_name,
		   address1,
		   address2,
           town_suburb,
	       state_code,
	       postcode, 
           business_unit_desc,
           rep_name, 
           campaign_status ) values (
 		   @campaign_no,   
		   @product_desc,   
		   @commission,   
		   @balance_credit,   
		   @balance_120,   
		   @balance_90,   
		   @balance_60,   
		   @balance_30,   
		   @balance_current,   
		   @balance_outstnd,   
		   @branch_name,
		   @client_name,   
		   @country_name,
		   @address_1,
		   @address_2,
           @town_suburb,
	       @state_code,
	       @postcode,
           @business_unit_desc,
           @rep_name, 
           @campaign_status )

    /*
     * Fetch Next
     */

    fetch campaign_csr into @agency_deal, @campaign_no, @product_desc, @commission, @balance_credit, @balance_120, @balance_90, @balance_60, @balance_30, @balance_current, @balance_outstnd, @branch_name, @client_name, @country_name, @business_unit_desc, @rep_name, @campaign_status

end
close campaign_csr
deallocate campaign_csr
                                 
/*
 * Return Results
 */

select * 
  from #results
order by business_unit_desc,
         state_code,
		 campaign_no

/*
 * Return Success
 */
 
return 0
GO
