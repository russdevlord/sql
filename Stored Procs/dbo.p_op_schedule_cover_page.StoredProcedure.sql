/****** Object:  StoredProcedure [dbo].[p_op_schedule_cover_page]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_schedule_cover_page]
GO
/****** Object:  StoredProcedure [dbo].[p_op_schedule_cover_page]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_schedule_cover_page] @campaign_no	int
as
set nocount on 
/*
 * Declare Variables
 */

declare @errorode				integer,
        @spot_weeks			integer,
        @schedule_cost		money,
        @schedule_value		money,
        @first_spot			datetime,
        @last_spot			datetime,
        @extra_value		money,
        @extra_cost			money,
		@standby_cost 		money

/*
 * Get First & Last Spot Screening
 */

select  @first_spot = min(screening_date),
	    @last_spot = max(screening_date)	
from    outpost_spot
where   campaign_no = @campaign_no and
        spot_status <> 'D' and
        spot_status <> 'C' and
        spot_status <> 'H' and
        screening_date <> null

/*
 * Get Weeks of Activity & No of Locations
 */

select @spot_weeks = count(distinct screening_date)
  from outpost_spot spot
 where campaign_no = @campaign_no and
       spot_type <> 'M' and
       screening_date <> null

/*
 * Select the Details from the Film Campaign
 */

select fc.campaign_no as campaign_no,
       fc.product_desc as product_desc,
       fc.revision_no as revision_no,
       fc.campaign_status as campaign_status,
       fc.branch_code as branch_code,
       fc.campaign_cost as campaign_cost, -- used to campaign_cost
       fc.campaign_value as campaign_value, -- used to be campaign_value
	   @standby_cost as standby_cost,
       @spot_weeks as spot_weeks,
       @extra_cost as extra_cost,
       @extra_value as extra_value,
       @first_spot as first_spot,
       @last_spot as last_spot,
       agency.agency_name as booking_agency,
       agb.agency_name as billing_agency,
       client.client_name as client_name,
       country.gst_rate as gst_rate
  from film_campaign fc,
       agency,
       agency agb,
       client,
       branch,
       country
 where fc.campaign_no = @campaign_no and
       fc.client_id = client.client_id and
       fc.agency_id = agency.agency_id and
       fc.billing_agency = agb.agency_id and
       fc.branch_code = branch.branch_code and
       branch.country_code = country.country_code 

return 0
GO
