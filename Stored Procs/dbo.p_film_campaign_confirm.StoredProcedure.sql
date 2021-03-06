/****** Object:  StoredProcedure [dbo].[p_film_campaign_confirm]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_confirm]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_confirm]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_film_campaign_confirm] @campaign_no		int
as

/*
 * Declare Variables
 */

declare  @error   						int,
         @errorode							int,
         @count							int,
         @onscreen_count				int,
		 @standby_count					int,
		 @cinelight_count				int,
		 @inclusion_count				int,
		 @outpost_count					int,
         @rowcount						int,
         @campaign_status				char(1),
         @billing_start					datetime,
         @screening_start				datetime,
         @current_screening		   		datetime,
		 @current_outpost_screening		datetime,
         @last_accounting_period		datetime,
		 @source_dandc_amount			money,
		 @dest_dandc_amount			    money,
         @source_campaign               int,
		 @cinelight_status				char(1),
		 @inclusion_status				char(1),
		 @outpost_status				char(1),
		 @business_unit_id				int
 
/*
 * Get Campaign Information
 */

select 	@campaign_status = campaign_status,
		@cinelight_status = cinelight_status,
		@inclusion_status = inclusion_status,
		@outpost_status = outpost_status,
       	@billing_start = billing_start_date,
       	@screening_start = start_date,
		@business_unit_id = business_unit_id
  from 	film_campaign
 where 	campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0 or @rowcount != 1)
begin
	raiserror ('Film Confirmation - Failure to retrieve campaign information.', 16, 1)
   return -1
end

/*
 * Get Current Screening Date
 */

select @current_screening = screening_date
  from film_screening_dates
 where screening_date_status = 'C'

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0 or @rowcount != 1)
begin
	raiserror ('Film Confirmation - Failure to retrieve current screening date.', 16, 1)
   return -1
end

/*
 * Get Current Outpost Screening Date
 */

select @current_outpost_screening = screening_date
  from outpost_screening_dates
 where screening_date_status = 'C'

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0 or @rowcount != 1)
begin
	raiserror ('Film Confirmation - Failure to retrieve current outpost screening date.', 16, 1)
   return -1
end

/*
 * Get Last Closed Accounting Period
 */

select @last_accounting_period = max(end_date)
  from accounting_period
 where status = 'X'

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0 or @rowcount != 1)
begin
	raiserror ('Film Confirmation - Failure to retrieve last accounting period.', 16, 1)
   return -1
end

/*
 * Ensure Campaign is Proposed
 */

if @campaign_status <> 'P' or @cinelight_status <> 'P' or @inclusion_status <> 'P' or @outpost_status <> 'P'
begin
	raiserror ('Film Confirmation - Campaign must have all statuses as "Proposed" before it can be confirmed.', 16, 1)
	return -1
end

/*
 * Ensure Campaign Has Screenings
 */

select 	@onscreen_count = count(spot_id)
  from 	campaign_spot
 where 	campaign_no = @campaign_no

select 	@cinelight_count = count(spot_id)
  from 	cinelight_spot
 where 	campaign_no = @campaign_no

select 	@inclusion_count = count(inclusion_id)
  from 	inclusion
 where 	campaign_no = @campaign_no

select 	@outpost_count = count(spot_id)
  from 	outpost_spot
 where 	campaign_no = @campaign_no

select 	@standby_count = count(complex_id)
  from 	film_plan_complex,
	    film_plan_dates, 
		film_plan
 where 	film_plan.film_plan_id = film_plan_dates.film_plan_id and
	    film_plan.film_plan_id = film_plan_complex.film_plan_id and
		film_plan.campaign_no = @campaign_no 

select 	@count = @onscreen_count + @standby_count + @cinelight_count + @inclusion_count + @outpost_count

if(@count < 1 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Campaign has no screenings.  Confirmation Denied', 16, 1)
	return -1
end

/*
 * Ensure all Campaign Screenings are Valid
 */

select 	@count = count(spot_id)
  from 	campaign_spot
 where 	screening_date < @current_screening and
		campaign_no = @campaign_no

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has screenings for dates which are now closed. Confirmation Denied.', 16, 1)
   return -1
end

/*
 * Ensure all Cinelight Screenings are Valid
 */

select @count = count(spot_id)
  from cinelight_spot
 where screening_date < @current_screening and
		 campaign_no = @campaign_no

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has Cinelight screenings for dates which are now closed. Confirmation Denied.', 16, 1)
   return -1
end

/*
 * Ensure all Inclusion Screenings are Valid
 */

select @count = count(spot_id)
  from inclusion_spot
 where screening_date < @current_screening and
		 campaign_no = @campaign_no and
		screening_date is not null

if(@count > 0)
begin
	raiserror ('Film Confirmation - Schedule has Cinemarketing or Proxy screenings for dates which are now closed. Confirmation Denied.', 16, 1)
   return -1
end

/*
 * Ensure all Retail Screenings are Valid
 */

select @count = count(spot_id)
  from outpost_spot
 where screening_date < @current_outpost_screening and
		 campaign_no = @campaign_no

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has Retail screenings for dates which are now closed. Confirmation Denied.', 16, 1)
	return -1
end

/*
 * Ensure all Billing Periods are Valid
 */

select @count = count(spot_id)
  from campaign_spot
 where billing_period <= @last_accounting_period and
		 campaign_no = @campaign_no

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has Screenings with billing periods for accounting periods which are now closed. Confirmation Denied.', 16, 1)
   return -1
end

/*
 * Ensure all Cinelight Billing Periods are Valid
 */

select @count = count(spot_id)
  from cinelight_spot
 where billing_period <= @last_accounting_period and
		 campaign_no = @campaign_no

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has Cinelight Screenings with billing periods for accounting periods which are now closed. Confirmation Denied.', 16, 1)
   return -1
end

/*
 * Ensure all Retail Billing Periods are Valid
 */

--select @count = count(spot_id)
--  from outpost_spot
-- where billing_period <= @last_accounting_period and
--		 campaign_no = @campaign_no

--if(@count > 0)
--begin
--	raiserror ('Film Confirmation - Schedule has Screenings with billing periods for accounting periods which are now closed. Confirmation Denied.', 16, 1)
--   return -1
--end

/*
 * Ensure all Inclusion Billing Periods are Valid
 */

select @count = count(spot_id)
  from inclusion_spot
 where billing_period <= @last_accounting_period and
		 campaign_no = @campaign_no

if(@count > 0 )
begin
	raiserror ('Film Confirmation - Schedule has Cinelight Screenings with billing periods for accounting periods which are now closed. Confirmation Denied.', 16, 1)
   return -1
end

/*
 * Ensure no Bonus Spots at complexes which do not allow bonus spots
 */

select @count = count(spot_id)
  from campaign_spot
 where spot_type = 'B' and
		 campaign_no = @campaign_no and

		 complex_id in (select complex_id from complex where bonus_allowed = 'N')

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has bonus screenings for complexes which do not allow bonus screenings. Confirmation Denied.', 16, 1)
    return -1
end


/*
 * Ensure no Cinelight Bonus Spots at complexes which do not allow bonus spots
 */

select 	@count = count(spot_id)
from 	cinelight_spot,
		cinelight
where 	spot_type = 'B' and
		campaign_no = @campaign_no and
		cinelight_spot.cinelight_id = cinelight.cinelight_id and
		complex_id in (select complex_id from complex where bonus_allowed = 'N')

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has Cinelight bonus screenings for complexes which do not allow bonus screenings. Confirmation Denied.', 16, 1)
    return -1
end

/*
 * Ensure no Retail Bonus Spots at venues which do not allow bonus spots
 */

select 	@count = count(spot_id)
from 	outpost_spot,
		outpost_panel
where 	spot_type = 'B' and
		campaign_no = @campaign_no and
		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id and
		outpost_venue_id in (select outpost_venue_id from outpost_venue where bonus_allowed = 'N')

if(@count > 0 and @business_unit_id<>9)
begin
	raiserror ('Film Confirmation - Schedule has Retail bonus screenings for venues which do not allow bonus screenings. Confirmation Denied.', 16, 1)
    return -1
end

/*
 * Ensure no Bonus Spots at complexes which do not allow bonus spots
 */

select @count = count(spot_id)
  from inclusion_spot
 where spot_type = 'B' and
		 campaign_no = @campaign_no and
		 complex_id in (select complex_id from complex where bonus_allowed = 'N')

if(@count > 0 )
begin
	raiserror ('Film Confirmation - Schedule has bonus screenings for complexes which do not allow bonus screenings. Confirmation Denied.', 16, 1)
    return -1
end


/*
 * Check Spot Redirect on Source Spots
 */
 
select @count = count(campaign_spot.spot_id)
  from campaign_spot,
	   delete_charge,
	   delete_charge_spots 
 where campaign_spot.spot_id = delete_charge_spots.spot_id
   and delete_charge_spots.source_dest = 'S'
   and delete_charge.destination_campaign = @campaign_no
   and delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id
   and campaign_spot.spot_redirect is not null

if(@count > 0)
begin
	raiserror ('Film Confirmation - Souce Spots with Spot redirect Set. Confirmation Denied.', 16, 1)
    return -1
end
 
/*
 * Declare Cursor
 */

 declare source_csr cursor static for
  select source_campaign
    from delete_charge
   where destination_campaign = @campaign_no
order by source_campaign
     for read only 

/*
 * Check D & C amounts match on a campaign by campaign basis
 */

open source_csr
fetch source_csr into @source_campaign   
while(@@fetch_status=0)
begin

    select @source_dandc_amount = round(isnull(sum(avg_rate),0),0)
      from campaign_spot,
	       delete_charge,
	       delete_charge_spots,
		   statrev_spot_rates	
     where campaign_spot.spot_id = delete_charge_spots.spot_id
       and delete_charge_spots.source_dest = 'S'
       and delete_charge.destination_campaign = @campaign_no
       and delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id
       and campaign_spot.spot_type <> 'D'
	   and campaign_spot.spot_id = statrev_spot_rates.spot_id
	   and statrev_spot_rates.revenue_group <= 3 
	   


    select @dest_dandc_amount = isnull(sum(makegood_rate),0)
      from campaign_spot,
	       delete_charge_spots
     where campaign_spot.spot_id = delete_charge_spots.spot_id
       and delete_charge_spots.source_dest = 'D'
       and campaign_spot.campaign_no = @campaign_no

    select @source_dandc_amount = isnull(@source_dandc_amount, 0) + round(isnull(sum(avg_rate),0),0)
      from cinelight_spot,
	       delete_charge,
	       delete_charge_cinelight_spots ,
		   statrev_spot_rates	
     where cinelight_spot.spot_id = delete_charge_cinelight_spots.spot_id
       and delete_charge_cinelight_spots.source_dest = 'S'
       and delete_charge.destination_campaign = @campaign_no
       and delete_charge.delete_charge_id = delete_charge_cinelight_spots.delete_charge_id
       and cinelight_spot.spot_type <> 'D'
	   and cinelight_spot.spot_id = statrev_spot_rates.spot_id
	   and statrev_spot_rates.revenue_group = 4 

    select @source_dandc_amount = isnull(@source_dandc_amount, 0) + isnull(sum(makegood_rate),0)
      from cinelight_spot,
	       delete_charge,
	       delete_charge_cinelight_spots 
     where cinelight_spot.spot_id = delete_charge_cinelight_spots.spot_id
       and delete_charge_cinelight_spots.source_dest = 'S'
       and delete_charge.destination_campaign = @campaign_no
       and delete_charge.delete_charge_id = delete_charge_cinelight_spots.delete_charge_id
       and cinelight_spot.spot_type = 'D'

    select @dest_dandc_amount = isnull(@dest_dandc_amount,0) + isnull(sum(makegood_rate),0)
      from cinelight_spot,
	       delete_charge_cinelight_spots
     where cinelight_spot.spot_id = delete_charge_cinelight_spots.spot_id
       and delete_charge_cinelight_spots.source_dest = 'D'
       and cinelight_spot.campaign_no = @campaign_no
       
       print @source_dandc_amount
       print @dest_dandc_amount
	
    if round(@source_dandc_amount,0) <> round(@dest_dandc_amount,0) or (round(@source_dandc_amount,0) <> round(@dest_dandc_amount,0) and round(@dest_dandc_amount,0) = 0)
    begin
	    raiserror ('Film Confirmation - Schedule has incorrect allocation for Delete and Charge Spots.  Please open the Delete and Charge Allocation window and ensure that all allocated amounts are equal. Confirmation Denied.', 16, 1)
        close source_csr
        deallocate source_csr
        return -1
    end
    

		   
    fetch source_csr into @source_campaign
end

close source_csr
deallocate source_csr

/*
 * Return Success
 */

return 0
GO
