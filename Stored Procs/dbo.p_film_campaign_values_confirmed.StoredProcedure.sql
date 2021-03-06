/****** Object:  StoredProcedure [dbo].[p_film_campaign_values_confirmed]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_values_confirmed]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_values_confirmed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create PROC [dbo].[p_film_campaign_values_confirmed] @campaign_no			int

as

/*
 * Declare Variables
 */

declare @errorode						int,
        @error         					int,
        @rowcount						int,
        @campaign_status				char(1),
        @film_plan_id					int,
        @maximum_value					money,
        @maximum_spend					money,
        @maximum_figure_spend			money,
        @current_value					money,
        @current_spend					money,
        @figure_spend					money,
        @plan_status					char(1),
        @scheduled_spot_value			money,
        @scheduled_spot_cost			money,
        @scheduled_spot_figures 		money,
        @standby_spot_value				money,
        @standby_spot_cost				money,
        @standby_spot_figures			money,
        @inclusion_value				money,
        @inclusion_cost					money,
        @inclusion_figures				money,
        @standby_schedule_value			money,
        @standby_schedule_cost			money,
        @standby_schedule_figures		money,
        @standby_remaining_value		money,
        @standby_remaining_cost			money,
        @standby_remaining_figures		money,
        @actual_figures					money,
        @adjustment_cost				money,
        @adjustment_figures				money,
        @cancelled_value				money,
        @dandc_value					money,
        @allocated_dandc_value 			money,
        @unallocated_dandc_value		money,
        @billing_credit					money,
        @figure_exempt					char(1),
        @under_dandc                    money,
        @cinelight_spot_value			money,
        @cinelight_spot_cost			money,
        @cinelight_spot_figures 		money,
        @outpost_spot_value				money,
        @outpost_spot_cost				money,
        @outpost_spot_figures 			money,
		@scheduled_takeout				money,
		@inclusion_takeout				money,
		@cinelight_takeout				money,
		@outpost_takeout				money
		

/*
 * Get Campaign Status
 */

select			@campaign_status = campaign_status,
				@figure_exempt = figure_exempt
from			film_campaign
where			campaign_no = @campaign_no

/*
 * Get the scheduled_spot_value
 */

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@scheduled_spot_value = campaign_value
	from			film_campaign
	where			campaign_no = @campaign_no
end
else
begin
	select			@scheduled_spot_value = sum(rate) 
	from			campaign_spot 
	where			campaign_no = @campaign_no 
	and				spot_type <> 'Y' 
	and				spot_type <> 'M' 
	and				spot_type <> 'V' 
	and				spot_status <> 'P'
end 

/*
 * Get the scheduled_spot_cost
 */

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@scheduled_spot_cost = campaign_cost
	from			film_campaign
	where			campaign_no = @campaign_no
end
else
begin
	select			@scheduled_spot_cost = sum(charge_rate) --+ sum(makegood_rate)
	from			campaign_spot 
	where			campaign_no = @campaign_no 
	and				spot_type <> 'Y' 
	and				spot_type <> 'M' 
	and				spot_type <> 'V' 
	and				spot_status <> 'P'
end

/*
 * Get the cinelight_scheduled_spot_figures
 */

select			@scheduled_spot_figures = @scheduled_spot_cost 

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@cinelight_spot_value = 0.0
end
else
begin
	select			@cinelight_spot_value = sum(rate) 
	from			cinelight_spot 
	where			campaign_no = @campaign_no 
	and				spot_type <> 'Y' 
	and				spot_type <> 'M' 
	and				spot_type <> 'V' 
	and				spot_status <> 'P'
end 

/*
 * Get the cinelight_spot_cost
 */

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@cinelight_spot_cost = 0.0
end
else
begin
	select			@cinelight_spot_cost = sum(charge_rate) --+ sum(makegood_rate)
	from			cinelight_spot 
	where			campaign_no = @campaign_no 
	and				spot_type <> 'Y' 
	and				spot_type <> 'M' 
	and				spot_type <> 'V' 
	and				spot_status <> 'P'
end

/*
 * Get the cinelight_spot_figures
 */

select			@cinelight_spot_figures = @cinelight_spot_cost 

/*
 * Get the outpost_scheduled_spot_figures
 */

select			@scheduled_spot_figures = @scheduled_spot_cost 

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@outpost_spot_value = 0.0
end
else
begin
	select			@outpost_spot_value = sum(rate) 
	from			outpost_spot 
	where			campaign_no = @campaign_no 
	and				spot_type <> 'Y' 
	and				spot_type <> 'M' 
	and				spot_type <> 'V' 
	and				spot_status <> 'P'
end 

/*
 * Get the outpost_spot_cost
 */

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@outpost_spot_cost = 0.0
end
else
begin
	select			@outpost_spot_cost = sum(charge_rate) --+ sum(makegood_rate)
	from			outpost_spot 
	where			campaign_no = @campaign_no 
	and 			spot_type <> 'Y' 
	and				spot_type <> 'M' 
	and				spot_type <> 'V' 
	and				spot_status <> 'P'
end

/*
 * Get the outpost_spot_figures
 */

select			@outpost_spot_figures = @outpost_spot_cost 

/*
 * Get the standby_spot_value
 */

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@standby_spot_value = isnull(sum(current_value), 0)
	from			film_plan
	where			campaign_no = @campaign_no
end
else
begin
	select			@standby_spot_value = sum(rate) 
	from			campaign_spot 
	where			campaign_no = @campaign_no 
	and				spot_type = 'Y' 
	and				spot_status <> 'P'
end

/*
 * Get the standby_spot_cost
 */

if @campaign_status = 'Z' 
begin
	--note for revision project - this will change to be off the revision rather than the campaign
	select			@standby_spot_cost = isnull(sum(current_spend), 0)
	from			film_plan
	where			campaign_no = @campaign_no
end
else
begin
	select			@standby_spot_cost = sum(charge_rate) 
	from			campaign_spot 
	where			campaign_no = @campaign_no 
	and				spot_type = 'Y' 
	and				spot_status <> 'P'
end

/*
 * Get the inclusion_value
 */

select			@inclusion_value = isnull(sum(inclusion_qty * inclusion_value), 0)
from			inclusion
where			campaign_no = @campaign_no 
and				include_schedule = 'Y' 
and				inclusion_id not in (select distinct inclusion_id from inclusion_spot where inclusion_id = inclusion.inclusion_id) 
and				inclusion_status <> 'P'

/*
 * Get the inclusion_cost
 */

select			@inclusion_cost = isnull(sum(inclusion_qty * inclusion_charge), 0)
from			inclusion
where			campaign_no = @campaign_no 
and				include_schedule = 'Y' 
and				inclusion_id not in (select distinct inclusion_id from inclusion_spot where inclusion_id = inclusion.inclusion_id) 
and				inclusion_status <> 'P'

/*
 * Get the inclusion figure amount
 */

select			@inclusion_figures = isnull(sum(inclusion_qty * inclusion_charge), 0)
from			inclusion
where			campaign_no = @campaign_no 
and				include_revenue = 'Y' 
and				inclusion_id not in (select distinct inclusion_id from inclusion_spot where inclusion_id = inclusion.inclusion_id) 
and				inclusion_status <> 'P'

/*
 * Get the inclusion_value
 */

select			@inclusion_value = @inclusion_value + isnull(sum(rate), 0)
from			inclusion_spot
where			campaign_no = @campaign_no 
and				spot_status <> 'P'

/*
 * Get the inclusion_cost
 */

select			@inclusion_cost = @inclusion_cost + isnull(sum(charge_rate), 0)
from			inclusion_spot
where			campaign_no = @campaign_no 
and				spot_status <> 'P'

/*
 * Get the inclusion figure amount
 */

select			@inclusion_figures = @inclusion_figures + isnull(sum(charge_rate), 0)
from			inclusion_spot
where			campaign_no = @campaign_no 
and				spot_status <> 'P'
/*
 * Get the actual figures for this campaign
 */

select			@actual_figures = isnull(sum(nett_amount),0)
from			film_figures
where			campaign_no = @campaign_no

/*
 * Get the adjustment cost
 */

select			@adjustment_cost = isnull(sum(nett_amount),0)
from			campaign_transaction
where			campaign_no = @campaign_no 
and				tran_type = 10      -- authorised credit

select			@billing_credit = isnull(sum(nett_amount),0)
from			campaign_transaction
where			campaign_no = @campaign_no 
and				tran_category = 'B' 
and				nett_amount < 0 
and				tran_type in (7,8,75,83, 172)

select			@adjustment_cost = @adjustment_cost + @billing_credit

/*
 * Get the adjustment figures
 */

select			@adjustment_figures = @adjustment_cost --once again is this the right value??

/*
 * Get the value of cancelled spots
 */

select			@cancelled_value = sum(charge_rate)
from			campaign_spot
where			campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'N' 

/*
 * Get the value of DandC spots
 */ 

select			@dandc_value = sum(charge_rate)
from			campaign_spot
where			campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y'

select			@dandc_value = isnull(@dandc_value, 0.0) + sum(charge_rate)
from			cinelight_spot
where			campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y'
       
/*
 * Get the value of Under DandC spots
 */ 

select			@under_dandc = sum(charge_rate)
from			campaign_spot
where			campaign_no = @campaign_no 
and				(spot_status = 'U' 
or				spot_status = 'N' ) 
and				dandc = 'Y'       

select			@under_dandc = isnull(@under_dandc,0.0) + sum(charge_rate)
from			cinelight_spot
where			campaign_no = @campaign_no 
and				(spot_status = 'U' 
or				spot_status = 'N' ) 
and				dandc = 'Y'       

/*
 * Get allocated dandc spots
 */

select			@allocated_dandc_value = sum(charge_rate)
from			campaign_spot,
				delete_charge_spots
where			campaign_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y' 
and				delete_charge_spots.spot_id = campaign_spot.spot_id 
and				delete_charge_spots.source_dest = 'S'

select			@allocated_dandc_value = isnull(@allocated_dandc_value, 0.0) + sum(charge_rate)
from			cinelight_spot,
				delete_charge_cinelight_spots
where			cinelight_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y' 
and				delete_charge_cinelight_spots.spot_id = cinelight_spot.spot_id 
and				delete_charge_cinelight_spots.source_dest = 'S'

select			@unallocated_dandc_value = isnull(@dandc_value,0) + isnull(@under_dandc, 0) - isnull(@allocated_dandc_value, 0)

if @figure_exempt = 'Y' 
    select			@scheduled_spot_figures = 0, 
					@standby_spot_figures = 0,
					@inclusion_figures  = 0,
					@standby_schedule_figures = 0,
					@standby_remaining_figures = 0 

select			@scheduled_takeout = isnull(sum(takeout_rate),0)
from			inclusion_spot,
				inclusion
where 			inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion.campaign_no = @campaign_no
and				inclusion.inclusion_category in ('A', 'B', 'D', 'E', 'F', 'H', 'J', 'K', 'L', 'N', 'O', 'T') 
and				spot_status <> 'P'

select 			@cinelight_takeout = isnull(sum(takeout_rate),0)
from			inclusion_spot,
				inclusion
where 			inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion.campaign_no = @campaign_no
and				inclusion.inclusion_category = 'C'
and				spot_status <> 'P'

select 			@outpost_takeout = isnull(sum(takeout_rate),0)
from			inclusion_spot,
				inclusion
where 			inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion.campaign_no = @campaign_no
and				inclusion.inclusion_category = 'R'
and				spot_status <> 'P'

select 			@inclusion_takeout = isnull(sum(takeout_rate),0)
from			inclusion_spot,
				inclusion
where 			inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion.campaign_no = @campaign_no
and				inclusion.inclusion_category = 'I'
and				spot_status <> 'P'

select			@scheduled_spot_cost 	= @scheduled_spot_cost - @scheduled_takeout		 
select			@scheduled_spot_figures = @scheduled_spot_figures - @scheduled_takeout		 
select			@inclusion_cost 		= @inclusion_cost - @inclusion_takeout		 
select			@inclusion_figures 		= @inclusion_figures - @inclusion_takeout		 
select			@cinelight_spot_cost 	= @cinelight_spot_cost - @cinelight_takeout		 
select			@cinelight_spot_figures = @cinelight_spot_figures - @cinelight_takeout		 
select			@outpost_spot_cost 		= @outpost_spot_cost - @outpost_takeout		 
select			@outpost_spot_figures 	= @outpost_spot_figures - @outpost_takeout		 

/*
 * Return values
 */ 

select			isnull(@scheduled_spot_value,0) as scheduled_spot_value,
				isnull(@scheduled_spot_cost,0) as scheduled_spot_cost,
				isnull(@scheduled_spot_figures,0) as scheduled_spot_figures,
				isnull(@standby_spot_value,0) as standby_spot_value,
				isnull(@standby_spot_cost,0) as standby_spot_cost,
				isnull(@standby_spot_figures,0) as standby_spot_figures,
				isnull(@inclusion_value,0) as inclusion_value,
				isnull(@inclusion_cost,0) as inclusion_cost,
				isnull(@inclusion_figures,0) as inclusion_figures,
				isnull(@standby_schedule_value,0) as standby_schedule_value,
				isnull(@standby_schedule_cost,0) as standby_schedule_cost,
				isnull(@standby_schedule_figures,0) as standby_schedule_figures,
				isnull(@standby_remaining_value,0) as standby_remaining_value,
				isnull(@standby_remaining_cost,0) as standby_remaining_cost,
				isnull(@standby_remaining_figures,0) as standby_remaining_figures,
				isnull(@actual_figures,0) as actual_figures,
				isnull(@adjustment_cost,0) as adjustment_cost,
				isnull(@adjustment_figures,0) as adjustment_figures,
				isnull(@cancelled_value,0) as cancelled_value,
				isnull(@dandc_value,0) as dandc_value,
				isnull(@allocated_dandc_value,0) as allocated_dandc_value,
				isnull(@unallocated_dandc_value,0) as unallocated_dandc_value,
				isnull(@under_dandc,0) as under_dandc_value,
				isnull(@cinelight_spot_value,0) as cinelight_spot_value,
				isnull(@cinelight_spot_cost,0) as cinelight_spot_cost,
				isnull(@cinelight_spot_figures,0) as cinelight_spot_figures,
				isnull(@outpost_spot_value,0) as outpost_spot_value,
				isnull(@outpost_spot_cost,0) as outpost_spot_cost,
				isnull(@outpost_spot_figures,0) as outpost_spot_figures
       
return 0
GO
