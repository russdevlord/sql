/****** Object:  StoredProcedure [dbo].[p_slide_campaign_recon_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_recon_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_recon_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_campaign_recon_rpt] @campaign_no		char(7)
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          			integer,
        @rowcount						integer,
        @agency_deal					char(1),
        @client_id					integer,
        @agency_id					integer,
        @client_agency_name		varchar(50),
        @address_1					varchar(50),
        @address_2					varchar(50),
        @town_suburb					varchar(30),
        @state_code					char(3),
        @postcode						char(5),
        @name_on_slide				varchar(50),
        @start_date					datetime,
        @orig_campaign_period		smallint,
        @min_campaign_period		smallint,
        @bonus_period				smallint,
        @nett_contract_value		money

/*
 * Get Campaign Information
 */

select @name_on_slide = name_on_slide,
       @start_date = start_date,
       @orig_campaign_period = orig_campaign_period,
       @min_campaign_period = min_campaign_period,
       @bonus_period	= bonus_period,
       @nett_contract_value = nett_contract_value,
       @agency_deal = agency_deal,
       @client_id = client_id,
       @agency_id = agency_id
  from slide_campaign
 where campaign_no = @campaign_no

/*
 * Get Client or Agency Address
 */

if @agency_deal = 'Y'
begin

	select @client_agency_name = ag.agency_name,
			 @address_1 = ag.address_1,
			 @address_2 = ag.address_2,
			 @town_suburb = ag.town_suburb,
			 @state_code = ag.state_code,
			 @postcode = ag.postcode
	  from agency ag
	 where ag.agency_id = @agency_id

end
else
begin

	select @client_agency_name = cl.client_name,
			 @address_1 = cl.address_1,
			 @address_2 = cl.address_2,
			 @town_suburb = cl.town_suburb,
			 @state_code = cl.state_code,
			 @postcode = cl.postcode
	  from client cl
	 where cl.client_id = @client_id

end

/*
 * Return Dataset
 */

select @campaign_no,
       @name_on_slide,
       @start_date,
       @orig_campaign_period,
       @min_campaign_period,
       @bonus_period,
       @nett_contract_value,
       @client_agency_name,
       @address_1,
       @address_2,
       @town_suburb,
       @state_code,
       @postcode

/*
 * Return
 */

return 0
GO
