/****** Object:  StoredProcedure [dbo].[p_schedule_cover_page]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_cover_page]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_cover_page]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

Create  PROC [dbo].[p_schedule_cover_page] @campaign_no	int
as

set nocount on 

/*
 * Declare Variables
 */

declare		@errorode							integer,
			@spot_weeks							integer,
			@schedule_cost						money,
			@schedule_value						money,
			@first_spot							datetime,
			@last_spot							datetime,
			@campaign_cost						money,
			@campaign_value						money,
			@pr_schedule_cost					money,
			@pr_schedule_value					money,
			@pr_campaign_cost					money,
			@pr_campaign_value					money,
			@extra_value						money,
			@extra_cost							money,
			@extra_bundle_value					money,
			@extra_bundle_cost					money,
			@standby_cost 						money,
			@pr_extra_value						money,
			@pr_extra_cost						money,
			@pr_extra_bundle_value				money,
			@pr_extra_bundle_cost				money,
			@pr_standby_cost 					money,
			@cl_first_spot						datetime,
			@cl_last_spot						datetime,
			@cl_spot_weeks						integer,
			@cl_campaign_cost					money,
			@cl_campaign_value					money,
			@pr_cl_campaign_cost				money,
			@pr_cl_campaign_value				money,
			@cm_first_spot						datetime,
			@cm_last_spot						datetime,
			@cm_spot_weeks						integer,
			@cm_campaign_cost					money,
			@cm_campaign_value					money,
			@pr_cm_campaign_cost				money,
			@pr_cm_campaign_value				money,
			@gift_prod_value					money,
			@gift_prod_cost						money,
			@paid_prod_value					money,
			@paid_prod_cost						money,
			@gift_other_value					money,
			@gift_other_cost					money,
			@pr_gift_prod_value					money,
			@pr_gift_prod_cost					money,
			@pr_paid_prod_value					money,
			@pr_paid_prod_cost					money,
			@pr_gift_other_value				money,
			@pr_gift_other_cost					money,
			@inclusion_count					integer,
			@op_first_spot						datetime,
			@op_last_spot						datetime,
			@op_wall_first_spot					datetime, 
			@op_wall_last_spot					datetime, 
			@op_spot_weeks						integer,
			@op_campaign_cost					money,
			@op_campaign_value					money,
			@pr_op_campaign_cost				money,
			@pr_op_campaign_value				money,
			@inclusion_bundle_count				integer

/*
 * Get First & Last Spot Screening for On Screen
 */

select 	@first_spot = min(screening_date),
		@last_spot = max(screening_date)	
from 	campaign_spot
where 	campaign_no = @campaign_no 
and		spot_status <> 'D' 
and		spot_status <> 'C' 
and		spot_status <> 'H' 
and		screening_date is not null

select	@cm_first_spot = min(screening_date),
		@cm_last_spot = max(screening_date)	
from    inclusion_spot,
		inclusion
where   inclusion_spot.campaign_no = @campaign_no and
        spot_status <> 'D' and
        spot_status <> 'C' and
        spot_status <> 'H' and
        screening_date is not null and
		inclusion.inclusion_id = inclusion_spot.inclusion_id and		
		(inclusion_type in (11,12,24,29, 30, 31, 32) or
		inclusion_type between 34 and 65)


if @first_spot is null or @first_spot > @cm_first_spot
	select @first_spot = @cm_first_spot

if @last_spot is null or @last_spot < @cm_last_spot
	select @last_spot = @cm_last_spot

/*
 * Get Weeks of Activity & No of Locations for On Screen
 */

select 	@spot_weeks = count(distinct screening_date)
from 	campaign_spot spot
where 	campaign_no = @campaign_no and
		spot_type <> 'M' and
		screening_date is not null

select 	@cm_spot_weeks = count(distinct screening_date)
from 	inclusion_spot spot,
		inclusion
where 	spot.campaign_no = @campaign_no and
		spot_type <> 'M' and
		screening_date is not null and
		spot.inclusion_id = inclusion.inclusion_id and
		(inclusion_type in (11,12,24,29, 30, 31, 32) or
		inclusion_type between 34 and 65)

if @spot_weeks is null or @spot_weeks < @cm_spot_weeks
	select @spot_weeks = @cm_spot_weeks


/*
 * Get campaign value for onscreen
 */

select 	@campaign_value = sum(rate),
		@campaign_cost = sum(charge_rate)
from 	campaign_spot 
where 	campaign_no = @campaign_no
and 	spot_status <> 'P'

select 	@cm_campaign_value = sum(rate),
		@cm_campaign_cost = sum(charge_rate)
from 	inclusion_spot ,
		inclusion
where 	inclusion_spot.campaign_no = @campaign_no
and		inclusion.inclusion_id = inclusion_spot.inclusion_id
and		(inclusion_type in  (11, 12, 24, 29, 30, 31, 32)
or		inclusion_type between 34 and 65)
and 	spot_status <> 'P'

select 	@campaign_value = isnull(@campaign_value,0) + isnull(@cm_campaign_value,0),
		@campaign_cost = isnull(@campaign_cost,0) + isnull(@cm_campaign_cost,0)

/*
 * Get campaign value for onscreen
 */

select 	@pr_campaign_value = sum(rate),
		@pr_campaign_cost = sum(charge_rate)
from 	campaign_spot 
where 	campaign_no = @campaign_no
and 	spot_status = 'P'

select 	@pr_cm_campaign_value = sum(rate),
		@pr_cm_campaign_cost = sum(charge_rate)
from 	inclusion_spot ,
		inclusion
where 	inclusion_spot.campaign_no = @campaign_no
and		inclusion.inclusion_id = inclusion_spot.inclusion_id
and		(inclusion_type in  (11, 12, 24, 29, 30, 31, 32)
or		inclusion_type between 34 and 65)
and 	spot_status = 'P'

select 	@pr_campaign_value = isnull(@pr_campaign_value,0) + isnull(@pr_cm_campaign_value,0),
		@pr_campaign_cost = isnull(@pr_campaign_cost,0) + isnull(@pr_cm_campaign_cost,0)


/*
 * Get First & Last Spot Screening for Off Screen
 */

select  @cl_first_spot = min(screening_date),
	    @cl_last_spot = max(screening_date)	
from    cinelight_spot
where   campaign_no = @campaign_no and
        spot_status <> 'D' and
        spot_status <> 'C' and
        spot_status <> 'H' and
        screening_date is not null

select  @cm_first_spot = min(screening_date),
	    @cm_last_spot = max(screening_date)	
from    inclusion_spot,
		inclusion
where   inclusion_spot.campaign_no = @campaign_no and
        spot_status <> 'D' and
        spot_status <> 'C' and
        spot_status <> 'H' and
        screening_date is not null and
		inclusion.inclusion_id = inclusion_spot.inclusion_id and
		inclusion_type not in  (11, 12, 24, 29, 30, 31, 32) and
		inclusion_type between 34 and 65


if @cl_first_spot is null or @cl_first_spot > @cm_first_spot
	select @cl_first_spot = @cm_first_spot

if @cl_last_spot is null or @cl_last_spot < @cm_last_spot
	select @cl_last_spot = @cm_last_spot

if @first_spot is null or @first_spot > @cl_first_spot
	select @first_spot = @cl_first_spot

if @last_spot is null or @last_spot < @cl_last_spot
	select @last_spot = @cl_last_spot

/*
 * Get Weeks of Activity & No of Locations for Off Screen
 */

select 	@cl_spot_weeks = count(distinct screening_date)
from 	cinelight_spot spot
where 	campaign_no = @campaign_no and
		spot_type <> 'M' and
		screening_date is not null

select 	@cm_spot_weeks = count(distinct screening_date)
from 	inclusion_spot spot,
		inclusion
where 	spot.campaign_no = @campaign_no and
		spot_type <> 'M' and
		screening_date is not null and
		inclusion.inclusion_id = spot.inclusion_id and
		inclusion_type not in  (11, 12, 24, 29, 30, 31, 32) and
		inclusion_type between 34 and 65

if @cl_spot_weeks is null or @cl_spot_weeks < @cm_spot_weeks
	select @cl_spot_weeks = @cm_spot_weeks

if @spot_weeks is null or @spot_weeks < @cl_spot_weeks
	select @spot_weeks = @cl_spot_weeks


/*
 * Get campaign value for off screen
 */

select 	@cl_campaign_value = sum(rate),
		@cl_campaign_cost = sum(charge_rate) 
from 	cinelight_spot 
where 	campaign_no = @campaign_no
and		spot_status <> 'P'

select 	@cm_campaign_value = sum(rate),
		@cm_campaign_cost = sum(charge_rate)
from 	inclusion_spot,
		inclusion
where 	inclusion_spot.campaign_no = @campaign_no
and		inclusion.inclusion_id = inclusion_spot.inclusion_id
and		(inclusion_type = 5
or		inclusion_type = 13
or		inclusion_type = 14)
and		spot_status <> 'P'

select		@cm_campaign_value = isnull(@cm_campaign_value,0) + isnull(sum(inclusion_spot_liability.spot_amount),0)   ,
				@cm_campaign_cost = isnull(@cm_campaign_cost,0) + isnull(sum(inclusion_spot_liability.spot_amount),0)   
from	 		inclusion_spot with (nolock),
				inclusion_spot_liability with (nolock)
where		inclusion_spot.campaign_no = @campaign_no
AND 			inclusion_spot.spot_status != 'P'
AND			inclusion_spot_liability.liability_type in (10,16)
AND			inclusion_spot.spot_id  = inclusion_spot_liability.spot_id

select 	@cl_campaign_value = isnull(@cl_campaign_value,0) + isnull(@cm_campaign_value,0),
		@cl_campaign_cost = isnull(@cl_campaign_cost,0) + isnull(@cm_campaign_cost,0)

/*
 * Get campaign value for off screen
 */

select 	@pr_cl_campaign_value = sum(rate),
		@pr_cl_campaign_cost = sum(charge_rate) 
from 	cinelight_spot 
where 	campaign_no = @campaign_no
and		spot_status = 'P'

select 	@pr_cm_campaign_value = sum(rate),
		@pr_cm_campaign_cost = sum(charge_rate)
from 	inclusion_spot,
		inclusion
where 	inclusion_spot.campaign_no = @campaign_no
and		inclusion.inclusion_id = inclusion_spot.inclusion_id
and		(inclusion_type = 5
or		inclusion_type = 13
or		inclusion_type = 14)
and		spot_status = 'P'

select 	@pr_cl_campaign_value = isnull(@pr_cl_campaign_value,0) + isnull(@pr_cm_campaign_value,0),
		@pr_cl_campaign_cost = isnull(@pr_cl_campaign_cost,0) + isnull(@pr_cm_campaign_cost,0)

/*
 * Get existence of inclusions
 */

select 	@inclusion_count = count(inclusion_id)
from 	inclusion,
		inclusion_type
where 	campaign_no = @campaign_no and
		include_schedule = 'Y' and
		inclusion_format = 'S' and
		inclusion_category = 'S' and
		inclusion.inclusion_type = inclusion_type.inclusion_type AND
		inclusion.inclusion_type <> 18 and --MR
		inclusion.inclusion_type <> 26 and
		inclusion_type.default_format = 'S'
		
		
/*
 * Get existence of inclusions
 */

select 	@inclusion_bundle_count = count(inclusion_id)
from 	inclusion,
		inclusion_type
where 	campaign_no = @campaign_no and
		include_schedule = 'Y' and
		inclusion_format = 'S' and
		inclusion_category = 'M' and
		inclusion.inclusion_type = inclusion_type.inclusion_type AND
		inclusion.inclusion_type <> 18  and --MR
		inclusion.inclusion_type <> 26 and
		inclusion_type.default_format = 'S'
		
/*
 * Value Inclusions
 */

select 	@extra_value = sum(inclusion_qty * inclusion_value),
		@extra_cost = sum(inclusion_qty * inclusion_charge)
from 	inclusion,
		inclusion_type
where 	campaign_no = @campaign_no and
		include_schedule = 'Y' and
		inclusion_format = 'S' and
		inclusion_category = 'S' and
		inclusion.inclusion_type = inclusion_type.inclusion_type and
		inclusion.inclusion_status <> 'P' AND
		inclusion.inclusion_type <> 18 and --MR
		inclusion.inclusion_type <> 26 and
		inclusion_type.default_format = 'S'

select 	@extra_value = isnull(@extra_value, 0)
select 	@extra_cost = isnull(@extra_cost, 0)

/*
 * Value  Proposed Inclusions
 */

select 	@pr_extra_value = sum(inclusion_qty * inclusion_value),
		@pr_extra_cost = sum(inclusion_qty * inclusion_charge)
from 	inclusion,
		inclusion_type
where 	campaign_no = @campaign_no and
		include_schedule = 'Y' and
		inclusion_format = 'S' and
		inclusion_category = 'S' and
		inclusion.inclusion_type = inclusion_type.inclusion_type and
		inclusion.inclusion_status = 'P' AND
		inclusion.inclusion_type <> 18 and
		inclusion.inclusion_type <> 26 and
		inclusion_type.default_format = 'S'

select 	@pr_extra_value = isnull(@pr_extra_value, 0)
select 	@pr_extra_cost = isnull(@pr_extra_cost, 0)


/*
 * Value Inclusions
 */

select 	@extra_bundle_value = sum(inclusion_qty * inclusion_value),
		@extra_bundle_cost = sum(inclusion_qty * inclusion_charge)
from 	inclusion,
		inclusion_type
where 	campaign_no = @campaign_no and
		include_schedule = 'Y' and
		inclusion_format = 'S' and
		inclusion_category = 'M' and
		inclusion.inclusion_type = inclusion_type.inclusion_type and
		inclusion.inclusion_status <> 'P' AND
		inclusion.inclusion_type <> 18 and --MR
		inclusion.inclusion_type <> 26 and
		inclusion_type.default_format = 'S'

select 	@extra_bundle_value = isnull(@extra_bundle_value, 0)
select 	@extra_bundle_cost = isnull(@extra_bundle_cost, 0)

/*
 * Value  Proposed Inclusions
 */

select 	@pr_extra_bundle_value = sum(inclusion_qty * inclusion_value),
		@pr_extra_bundle_cost = sum(inclusion_qty * inclusion_charge)
from 	inclusion,
		inclusion_type
where 	campaign_no = @campaign_no and
		include_schedule = 'Y' and
		inclusion_format = 'S' and
		inclusion_category = 'M' and
		inclusion.inclusion_type = inclusion_type.inclusion_type and
		inclusion.inclusion_status = 'P' AND
		inclusion.inclusion_type <> 18 and --MR
		inclusion.inclusion_type <> 26 and
		inclusion_type.default_format = 'S'

select 	@pr_extra_bundle_value = isnull(@pr_extra_bundle_value, 0)
select 	@pr_extra_bundle_cost = isnull(@pr_extra_bundle_cost, 0)

/*
 * Get Takeout amounts - add to value only on inclusion
 */

select 	@gift_other_value = sum(inclusion_spot.takeout_rate)
from	inclusion_spot
,		inclusion 	--GB 27/11
where	inclusion_spot.spot_status <> 'P'
and		inclusion_spot.campaign_no = @campaign_no
and	inclusion.include_revenue = 'Y'  and --GB 
inclusion_spot.inclusion_id = inclusion.inclusion_id 	 --GB
and inclusion.inclusion_type <> 22  --MR
		
select @extra_value =  isnull(@extra_value, 0) +  isnull(@gift_other_value, 0)

/*
 * Get Takeout amounts - add to value only on inclusion
 */

select 	@pr_gift_other_value = sum(inclusion_spot.takeout_rate)
from	inclusion_spot
,		inclusion 	--GB 27/11
where	inclusion_spot.spot_status = 'P'
and		inclusion_spot.campaign_no = @campaign_no
and	inclusion.include_revenue = 'Y'  and --GB 
inclusion_spot.inclusion_id = inclusion.inclusion_id 	 --GB
and 		inclusion.inclusion_type <> 22  --MR

select 	@pr_extra_value =  isnull(@pr_extra_value, 0) +  isnull(@pr_gift_other_value, 0)

/* 
 * Retail
 */

select  @op_first_spot = min(screening_date),
	    @op_last_spot = max(screening_date)	
from    outpost_spot
where   campaign_no = @campaign_no and
        spot_status <> 'D' and
        spot_status <> 'C' and
        spot_status <> 'H' and
        screening_date is not null

/*select 	@op_spot_weeks = count(distinct screening_date)
from 	outpost_spot spot
where 	campaign_no = @campaign_no and
		spot_type <> 'M' and
		screening_date is not null*/

select  @op_wall_first_spot = min(op_screening_date),
	    @op_wall_last_spot = max(op_screening_date)	
from    inclusion_spot,
		inclusion
where 	inclusion.campaign_no = @campaign_no
and		spot_status <> 'P'
and		inclusion_spot.inclusion_id = inclusion.inclusion_id
and		inclusion_type in (18, 26)
and     spot_status <> 'D' 
and     spot_status <> 'C' 
and     spot_status <> 'H' 
and     op_screening_date is not null


select @op_first_spot = isnull(@op_first_spot, @op_wall_first_spot)

select @op_last_spot = isnull(@op_last_spot, @op_wall_last_spot)

if (@op_wall_first_spot < @op_first_spot) 
	select @op_first_spot = @op_wall_first_spot

if (@op_wall_last_spot > @op_last_spot) 
	select @op_last_spot = @op_wall_last_spot

select 	@op_spot_weeks = count(distinct screening_date)
from	(select 	distinct screening_date
		from 	outpost_spot spot
		where 	campaign_no = @campaign_no and
				spot_type <> 'M' and
				screening_date is not null
		union	
		select 	distinct op_screening_date
		from 	inclusion_spot,
				inclusion
		where 	inclusion.campaign_no = @campaign_no 
		and		inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_type in (18, 26)
		and		spot_type <> 'M' 
		and		op_screening_date is not null) as temp_table


/*
 * Get campaign value for retail
 */

select 	@op_campaign_value = isnull(sum(rate),0),
		@op_campaign_cost = isnull(sum(charge_rate),0)
from 	outpost_spot 
where 	campaign_no = @campaign_no
and		spot_status <> 'P'


select 	@pr_op_campaign_value = isnull(sum(rate),0),
		@pr_op_campaign_cost = isnull(sum(charge_rate),0)
from 	outpost_spot 
where 	campaign_no = @campaign_no
and		spot_status = 'P'


--MR
select 	@op_campaign_value = @op_campaign_value + isnull(sum(rate),0),
		@op_campaign_cost = @op_campaign_cost + isnull(sum(charge_rate),0)
from 	inclusion_spot,
		inclusion
where 	inclusion.campaign_no = @campaign_no
and		spot_status <> 'P'
and		inclusion_spot.inclusion_id = inclusion.inclusion_id
and		inclusion_type in (18, 26)

select 	@pr_op_campaign_value = @pr_op_campaign_value + isnull(sum(rate),0),
		@pr_op_campaign_cost = @pr_op_campaign_cost + isnull(sum(charge_rate),0)
from 	inclusion_spot,
		inclusion
where 	inclusion.campaign_no = @campaign_no
and		spot_status = 'P'
and		inclusion_spot.inclusion_id = inclusion.inclusion_id
and		inclusion_type in (18, 26)

if @extra_value > 0 or @pr_extra_value > 0
	select @inclusion_count = 1
	
	
if @inclusion_count > 1
	select @inclusion_count = 1
	
if @inclusion_bundle_count > 1
	select @inclusion_bundle_count = 1
	


/*
 * Select the Details from the Film Campaign
 */

select 		fc.campaign_no as campaign_no,
			fc.product_desc as product_desc,
			fc.revision_no as revision_no,
			fc.campaign_status as campaign_status,
			fc.branch_code as branch_code,
			@campaign_cost as campaign_cost, 
			@campaign_value as campaign_value, 
			@spot_weeks as spot_weeks,
			@extra_cost as extra_cost,
			@extra_value as extra_value,
			@first_spot as first_spot,
			@last_spot as last_spot,
			agency.agency_name as booking_agency,
			agb.agency_name as billing_agency,
			client.client_name as client_name,
			country.gst_rate as gst_rate,
			@cl_first_spot as cl_first_spot,
			@cl_last_spot as cl_last_spot,
			@cl_spot_weeks as cl_spot_weeks,
			@cl_campaign_cost as cl_campaign_cost,
			@cl_campaign_value as cl_campaign_value,
			client_product.client_product_desc,
			@pr_campaign_cost as pr_campaign_cost, 
			@pr_campaign_value as pr_campaign_value, 
			@pr_cl_campaign_cost as pr_cl_campaign_cost,
			@pr_cl_campaign_value as pr_cl_campaign_value,
			@pr_extra_cost as pr_extra_cost,
			@pr_extra_value as pr_extra_value,
			@inclusion_count as inclusion_count,
			@op_first_spot as op_first_spot,
			@op_last_spot as op_last_spot,
			@op_spot_weeks as op_spot_weeks,
			@op_campaign_cost as op_campaign_cost,
			@op_campaign_value as op_campaign_value,
			@pr_op_campaign_cost as op_cl_campaign_cost,
			@pr_op_campaign_value as op_cl_campaign_value,
			@inclusion_bundle_count as inclusion_bundle_count,
			@extra_bundle_cost as extra_bundle_cost,
			@extra_bundle_value as extra_bundle_value,
			@pr_extra_bundle_cost as pr_extra_bundle_cost,
			@pr_extra_bundle_value as pr_extra_bundle_value,
					fc.commission
from 			film_campaign fc,
					agency,
					agency agb,
					client,
					branch,
					country,
					client_product
where 		fc.campaign_no = @campaign_no and
					fc.client_id = client.client_id and
					fc.agency_id = agency.agency_id and
					fc.billing_agency = agb.agency_id and
					fc.branch_code = branch.branch_code and
					branch.country_code = country.country_code and
					client_product.client_product_id = fc.client_product_id

return 0
GO
