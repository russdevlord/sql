/****** Object:  StoredProcedure [dbo].[p_PCA_Mediaspend_values]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_PCA_Mediaspend_values]
GO
/****** Object:  StoredProcedure [dbo].[p_PCA_Mediaspend_values]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  PROC [dbo].[p_PCA_Mediaspend_values] @campaign_no			int

as

/*
 * Declare Variables
 */

declare		@error        		 															int,
				@onscreen_std_con_cost									money,
				@onscreen_std_con_adjustments						money,
				@onscreen_pxy_con_cost									money,
				@cinelights_std_con_cost									money,
				@cinelights_std_con_adjustments						money,
				@cinelights_pxy_con_cost									money,
				@onscreen_con_mkgood_cost							money,
					@cinelights_con_mkgood_cost							money


set nocount on


create table #values
(
onscreen_std_con_cost										money			not null,
onscreen_std_con_adjustments						money			not null,
onscreen_pxy_con_cost									money			not null,
	cinelights_std_con_cost										money			not null,
	cinelights_std_con_adjustments						money			not null,
	cinelights_pxy_con_cost									money			not null,
	onscreen_con_mkgood_cost							money			not null,
	cinelights_con_mkgood_cost							money			not null
)

select 		
					@onscreen_std_con_cost = sum(charge_rate)	
from 			campaign_spot with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'


select 		
					@onscreen_std_con_cost = isnull(@onscreen_std_con_cost,0) + isnull(sum(charge_rate),0)
from 			inclusion_spot with (nolock),
					inclusion
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion_type = 24

select 		--@onscreen_con_mkgood_value	= sum(rate),
					@onscreen_con_mkgood_cost	= sum(charge_rate)--,
				--	@onscreen_con_mkgood_mkgd 	= sum(makegood_rate)	
from 			campaign_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status <> 'P'

/*select 		@onscreen_std_con_takeouts = sum(takeout_rate)
from			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				(inclusion_category = 'F'
or				inclusion_category = 'D')
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'   
and				include_revenue = 'Y'  --GB 25/11/09
*/

select 		@onscreen_std_con_adjustments = isnull(sum(nett_amount * -1),0)
from 			campaign_transaction  with (nolock)
where 		campaign_no = @campaign_no
and				tran_category = 'B'
and				nett_amount < 0 
and				tran_type in (7,8)

select		@onscreen_std_con_adjustments = @onscreen_std_con_adjustments + isnull(sum(spot_liability.spot_amount * -1),0)   
FROM 		campaign_spot  with (nolock),
					spot_liability  with (nolock)
WHERE	campaign_spot.campaign_no = @campaign_no
AND 			campaign_spot.spot_status != 'P'
AND 			spot_liability.liability_type = 10
AND 			campaign_spot.spot_id  = spot_liability.spot_id

/*select 		@onscreen_std_prp_units	= count(spot_id),
					@onscreen_std_prp_value	= sum(rate),
					@onscreen_std_prp_cost = sum(charge_rate)		
from 			campaign_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'

select 		@onscreen_prp_mkgood_value	= sum(rate),
					@onscreen_prp_mkgood_cost	= sum(charge_rate),
					@onscreen_prp_mkgood_mkgd 	= sum(makegood_rate)	
from 			campaign_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status = 'P'

select 		@onscreen_std_prp_takeouts = sum(takeout_rate)
from			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				(inclusion_category = 'F'
or				inclusion_category = 'D')
and				inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'

select 		@onscreen_pxy_con_units	= count(spot_id),
					@onscreen_pxy_con_value	= sum(rate),	
					@onscreen_pxy_con_cost = sum(charge_rate)		
from 			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				(inclusion.inclusion_type = 11
or				inclusion.inclusion_type = 12)


select 		@onscreen_pxy_prp_units	= count(spot_id),
					@onscreen_pxy_prp_value	= sum(rate),
					@onscreen_pxy_prp_cost = sum(charge_rate)		
from 			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				(inclusion.inclusion_type = 11
or				inclusion.inclusion_type = 12)
*/
select 		/*@cinelights_std_con_units = count(spot_id),
					@cinelights_std_con_value = sum(rate),*/
					@cinelights_std_con_cost = sum(charge_rate)	
from			cinelight_spot  with (nolock)
where		campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'

/*select 		@cinelights_con_mkgood_value = sum(rate),
					@cinelights_con_mkgood_cost	= sum(charge_rate),
					@cinelights_con_mkgood_mkgd 	= sum(makegood_rate)	
from 			cinelight_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status <> 'P'

select 		@cinelights_std_con_takeouts = sum(takeout_rate)
from			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion_category = 'C'
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
*/

select 		@cinelights_std_con_adjustments = isnull(sum(nett_amount * -1),0)
from			campaign_transaction  with (nolock)
where 		campaign_no = @campaign_no
and				tran_category = 'B'
and				nett_amount < 0 
and				tran_type in (75)

select		@cinelights_std_con_adjustments = @cinelights_std_con_adjustments + isnull(sum(cinelight_spot_liability.spot_amount * -1),0)   
from	 		cinelight_spot  with (nolock),
					cinelight_spot_liability  with (nolock)
where		cinelight_spot.campaign_no = @campaign_no
AND 			cinelight_spot.spot_status != 'P'
AND 			cinelight_spot_liability.liability_type = 10
AND 			cinelight_spot.spot_id  = cinelight_spot_liability.spot_id

/*select 		@cinelights_std_prp_units = count(spot_id),
					@cinelights_std_prp_value = sum(rate),
					@cinelights_std_prp_cost = sum(charge_rate)	
from 			cinelight_spot   with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'

select 		@cinelights_prp_mkgood_value = sum(rate),
					@cinelights_prp_mkgood_cost	= sum(charge_rate),
					@cinelights_prp_mkgood_mkgd	= sum(makegood_rate)	
from 			cinelight_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status = 'P'

select 		@cinelights_std_prp_takeouts = sum(takeout_rate)
from			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion_category = 'C'
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'
*/

select 		--@cinelights_pxy_con_units = count(spot_id),
			--		@cinelights_pxy_con_value = sum(rate),
					@cinelights_pxy_con_cost = sum(charge_rate)	
from 			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_type = 13

/*select 		@cinelights_pxy_prp_units = count(spot_id),
					@cinelights_pxy_prp_value = sum(rate),
					@cinelights_pxy_prp_cost = sum(charge_rate)	
from 			inclusion_spot  with (nolock),
					inclusion  with (nolock)
where		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_type = 13

select 		@cinemarketing_std_con_units = count(spot_id),
					@cinemarketing_std_con_value = sum(rate),
					@cinemarketing_std_con_cost = sum(charge_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				(inclusion.inclusion_type = 5
or				inclusion.inclusion_type = 18)


select 		@cinemarketing_con_mkgood_value = sum(rate),
					@cinemarketing_con_mkgood_cost	= sum(charge_rate),
					@cinemarketing_con_mkgood_mkgd	= sum(makegood_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				(inclusion.inclusion_type = 5
or				inclusion.inclusion_type = 18)

select 		@cinemarketing_std_con_takeouts = sum(takeout_rate)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				(inclusion_category = 'I'
or				inclusion_category = 'M')
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'


select 		@cinemarketing_std_con_adjustments = isnull(sum(nett_amount * -1),0)
from 			campaign_transaction with (nolock)
where 		campaign_no = @campaign_no
and				tran_category = 'B'
and				nett_amount < 0 
and				tran_type in (90)

select		@cinemarketing_std_con_adjustments = @cinemarketing_std_con_adjustments + isnull(sum(inclusion_spot_liability.spot_amount * -1),0)   
from	 		inclusion_spot with (nolock),
					inclusion_spot_liability with (nolock)
where		inclusion_spot.campaign_no = @campaign_no
AND 			inclusion_spot.spot_status != 'P'
AND			inclusion_spot_liability.liability_type = 10
AND			inclusion_spot.spot_id  = inclusion_spot_liability.spot_id

select 		@cinemarketing_std_prp_units = count(spot_id),
					@cinemarketing_std_prp_value = sum(rate),
					@cinemarketing_std_prp_cost = sum(charge_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				(inclusion.inclusion_type = 5
or				inclusion.inclusion_type = 18)

select 		@cinemarketing_prp_mkgood_value = sum(rate),
					@cinemarketing_prp_mkgood_cost	= sum(charge_rate),
					@cinemarketing_prp_mkgood_mkgd	= sum(makegood_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status = 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				(inclusion.inclusion_type = 5
or				inclusion.inclusion_type = 18)


select 		@cinemarketing_std_prp_takeouts = sum(takeout_rate)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				(inclusion_category = 'I'
or				inclusion_category = 'M')
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'

select 		@cinemarketing_pxy_con_units = count(spot_id),
					@cinemarketing_pxy_con_value = sum(rate),
					@cinemarketing_pxy_con_cost = sum(charge_rate)	
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_type = 14

select		@cinemarketing_pxy_prp_units = count(spot_id),
					@cinemarketing_pxy_prp_value = sum(rate),
					@cinemarketing_pxy_prp_cost = sum(charge_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_type = 14

select		@inclusion_std_con_units = sum(inclusion_qty),
					@inclusion_std_con_value = sum(inclusion_qty * inclusion_value),
					@inclusion_std_con_cost = sum(inclusion_qty * inclusion_charge)
from			inclusion with (nolock)
where		campaign_no = @campaign_no
and				inclusion_format = 'S'
and				inclusion_category = 'S'
and				include_schedule = 'Y'
and				inclusion_status <> 'P'

select		@inclusion_std_con_revenue = sum(inclusion_qty * inclusion_charge)
from			inclusion with (nolock)
where		campaign_no = @campaign_no
and				inclusion_format = 'S'
and				inclusion_category = 'S'
and				include_revenue = 'Y'
and				inclusion_status <> 'P'

select 		@inclusion_std_con_adjustments = isnull(sum(nett_amount),0)
from 			campaign_transaction with (nolock)
where		campaign_no = @campaign_no
and				tran_category = 'B'
and				nett_amount < 0 
and				tran_type in (91)

select		@inclusion_std_prp_units = sum(inclusion_qty),
					@inclusion_std_prp_value = sum(inclusion_qty * inclusion_value),
					@inclusion_std_prp_cost = sum(inclusion_qty * inclusion_charge)	
from			inclusion with (nolock)
where		campaign_no = @campaign_no
and				inclusion_format = 'S'
and				inclusion_category = 'S'
and				include_schedule = 'Y'
and				inclusion_status = 'P'

select		@inclusion_std_prp_revenue = sum(inclusion_qty * inclusion_charge)
from			inclusion with (nolock)
where		campaign_no = @campaign_no
and				inclusion_format = 'S'
and				inclusion_category = 'S'
and				include_revenue = 'Y'
and				inclusion_status = 'P'

select		@actual_figures = sum(nett_amount)
from			booking_figures  with (nolock)
where		campaign_no = @campaign_no

select		@booking_adjustments = sum(nett_amount)
from			booking_figures  with (nolock)
where		campaign_no = @campaign_no
and				figure_type = 'A'
and				figure_comment <> 'Migration Adjustment'

select	 	@onscreen_revisions = sum(cost)
from			revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type with (nolock)
where		revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 1

select 		@cinelights_revisions = sum(cost)
from			revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type  with (nolock)
where		revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 2

select 		@cinemarketing_revisions = sum(cost)
from			revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type with (nolock)
where		revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 3

select 		@cinemarketing_revisions = isnull(@cinemarketing_revisions, 0) + isnull(sum(cost),0)
from			outpost_revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type with (nolock)
where		outpost_revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				outpost_revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 51

select 		@inclusion_revisions = sum(cost)
from			revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type with (nolock)
where		revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 4

/*
 * Get the value of cancelled spots
 */

select		@cancelled_value = isnull(sum(charge_rate),0)
from			campaign_spot with (nolock)
where		campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'N'

select		@cancelled_value = isnull(@cancelled_value, 0) +  isnull(sum(charge_rate),0)
from			cinelight_spot with (nolock)
where		campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'N'

select		@cancelled_value = isnull(@cancelled_value, 0) +  isnull(sum(charge_rate),0)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'N' 
and				inclusion.inclusion_id  = inclusion_spot.inclusion_id 
and				inclusion_type = 5

/*
 * Get the value of DandC spots
 */ 

select		@dandc_value = isnull(sum(charge_rate),0)
from			campaign_spot with (nolock)
where		campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y'

select		@dandc_value = isnull(@dandc_value, 0.0) + isnull(sum(charge_rate), 0)
from			cinelight_spot with (nolock)
where		campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y'

select		@dandc_value = isnull(@dandc_value, 0.0) + isnull(sum(charge_rate), 0)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y' 
and				inclusion.inclusion_id  = inclusion_spot.inclusion_id 
and				inclusion_type = 5
       
/*
 * Get the value of Under DandC spots
 */ 

select		@under_dandc = isnull(sum(charge_rate),0)
from			campaign_spot with (nolock)
where		campaign_no = @campaign_no 
and				(spot_status = 'U' 
or				spot_status = 'N' ) 
and				dandc = 'Y'       

select		@under_dandc = isnull(@under_dandc,0.0) + isnull(sum(charge_rate),0)
from			cinelight_spot with (nolock)
where		campaign_no = @campaign_no 
and				(spot_status = 'U' 
or				spot_status = 'N' ) 
and				dandc = 'Y'       

select		@under_dandc = isnull(@under_dandc,0.0) + isnull(sum(charge_rate),0)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.campaign_no = @campaign_no 
and				(spot_status = 'U' 
or				spot_status = 'N' ) 
and				dandc = 'Y' 
and				inclusion.inclusion_id  = inclusion_spot.inclusion_id 
and				inclusion_type = 5       

/*
 * Get allocated dandc spots
 */

select		@allocated_dandc_value = isnull(sum(charge_rate), 0)
from			campaign_spot with (nolock),
					delete_charge_spots with (nolock)
where		campaign_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y' 
and				delete_charge_spots.spot_id = campaign_spot.spot_id 
and				delete_charge_spots.source_dest = 'S'

select		@allocated_dandc_value = isnull(@allocated_dandc_value, 0.0) + isnull(sum(charge_rate),0)
from			cinelight_spot with (nolock),
					delete_charge_cinelight_spots with (nolock)
where		cinelight_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y' 
and				delete_charge_cinelight_spots.spot_id = cinelight_spot.spot_id 
and				delete_charge_cinelight_spots.source_dest = 'S'

select		@allocated_dandc_value = isnull(@allocated_dandc_value, 0.0) + isnull(sum(charge_rate),0)
from			inclusion_spot with (nolock),
					inclusion with (nolock),
					delete_charge_inclusion_spots with (nolock)
where		inclusion_spot.campaign_no = @campaign_no 
and				spot_status = 'C' 
and				dandc = 'Y' 
and				delete_charge_inclusion_spots.spot_id = inclusion_spot.spot_id 
and				delete_charge_inclusion_spots.source_dest = 'S' 
and				inclusion.inclusion_id  = inclusion_spot.inclusion_id 
and				inclusion_type = 5   

select		@unallocated_dandc_value = isnull(@dandc_value,0) + isnull(@under_dandc, 0) - isnull(@allocated_dandc_value, 0)

select 		@outpost_std_con_units = count(spot_id),
					@outpost_std_con_value = sum(rate),
					@outpost_std_con_cost = sum(charge_rate)	
from 			outpost_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'

select 		@outpost_con_mkgood_value = sum(rate),
					@outpost_con_mkgood_cost	= sum(charge_rate),
					@outpost_con_mkgood_mkgd 	= sum(makegood_rate)	
from 			outpost_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status <> 'P'

select 		@outpost_std_con_takeouts = sum(takeout_rate)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion_category = 'R'
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'

select 		@outpost_std_con_adjustments = isnull(sum(nett_amount * -1),0)
from 			campaign_transaction with (nolock)
where 		campaign_no = @campaign_no
and				tran_category = 'B'
and				nett_amount < 0 
and				tran_type in (103)

select		@outpost_std_con_adjustments = @outpost_std_con_adjustments + isnull(sum(outpost_spot_liability.spot_amount * -1),0)   
from			outpost_spot with (nolock),
					outpost_spot_liability with (nolock)
where		outpost_spot.campaign_no = @campaign_no
AND 			outpost_spot.spot_status != 'P'
AND 			outpost_spot_liability.liability_type = 10
AND 			outpost_spot.spot_id  = outpost_spot_liability.spot_id

select 		@outpost_std_prp_units = count(spot_id),
					@outpost_std_prp_value = sum(rate),
					@outpost_std_prp_cost = sum(charge_rate)	
from 			outpost_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'

select 		@outpost_prp_mkgood_value = sum(rate),
					@outpost_prp_mkgood_cost	= sum(charge_rate),
					@outpost_prp_mkgood_mkgd	= sum(makegood_rate)	
from 			outpost_spot  with (nolock)
where 		campaign_no = @campaign_no  
and				spot_type = 'D'
and				spot_status = 'P'

select 		@outpost_std_prp_takeouts = sum(takeout_rate)
from			inclusion_spot with (nolock),
					inclusion with (nolock)
where		inclusion_spot.inclusion_id = inclusion.inclusion_id
and				inclusion_category = 'R'
and 			inclusion_spot.campaign_no = @campaign_no
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'


select 		@outpost_pxy_con_units = count(spot_id),
					@outpost_pxy_con_value = sum(rate),
					@outpost_pxy_con_cost = sum(charge_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status <> 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_type = 20

select		@outpost_pxy_prp_units = count(spot_id),
					@outpost_pxy_prp_value = sum(rate),
					@outpost_pxy_prp_cost = sum(charge_rate)	
from 			inclusion_spot with (nolock),
					inclusion with (nolock)
where 		inclusion_spot.campaign_no = @campaign_no  
and				spot_type <> 'Y' 
and				spot_type <> 'M' 
and				spot_type <> 'V'
and				spot_type <> 'D'
and				spot_status = 'P'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_type = 20

select 		@outpost_revisions = sum(cost)
from			outpost_revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type with (nolock)
where		outpost_revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				outpost_revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 50


select 		@outpost_revisions_super_wall = sum(cost)
from			outpost_revision_transaction with (nolock),
					campaign_revision with (nolock),
					revision_transaction_type with (nolock)
where		outpost_revision_transaction.revision_id = campaign_revision.revision_id
and				campaign_revision.campaign_no = @campaign_no
and				outpost_revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and				revision_transaction_type.revision_group = 53

select 		@statutory_revenue = isnull(sum(cost),0)
from			v_statrev
where		campaign_no = @campaign_no
*/
/*
 * Insert into temp table
 */

insert into #values
(
--onscreen_std_con_units,
--onscreen_std_con_value,
onscreen_std_con_cost,
--onscreen_std_con_takeouts,
onscreen_std_con_adjustments,
--onscreen_std_prp_units,
--onscreen_std_prp_value,
--onscreen_std_prp_cost,
--onscreen_std_prp_takeouts,
--onscreen_pxy_con_units,
--onscreen_pxy_con_value,
onscreen_pxy_con_cost,
--onscreen_pxy_prp_units,
--onscreen_pxy_prp_value,
--onscreen_pxy_prp_cost,
--onscreen_revisions,
--cinelights_std_con_units,
--cinelights_std_con_value,
cinelights_std_con_cost,
--cinelights_std_con_takeouts,
cinelights_std_con_adjustments,
--cinelights_std_prp_units,
--cinelights_std_prp_value,
--cinelights_std_prp_cost,
--cinelights_std_prp_takeouts,
--cinelights_pxy_con_units,
--cinelights_pxy_con_value,
cinelights_pxy_con_cost,
--cinelights_pxy_prp_units,
--cinelights_pxy_prp_value,
--cinelights_pxy_prp_cost,
--cinelights_revisions,
--cinemarketing_std_con_units,
--cinemarketing_std_con_value,
--cinemarketing_std_con_cost,
--cinemarketing_std_con_takeouts,
--cinemarketing_std_con_adjustments,
--cinemarketing_std_prp_units,
--cinemarketing_std_prp_value,
--cinemarketing_std_prp_cost,
--cinemarketing_std_prp_takeouts,
--cinemarketing_pxy_con_units,
--cinemarketing_pxy_con_value,
--cinemarketing_pxy_con_cost,
--cinemarketing_pxy_prp_units,
--cinemarketing_pxy_prp_value,
--cinemarketing_pxy_prp_cost,
--cinemarketing_revisions,
--inclusion_std_con_units,
--inclusion_std_con_value,
--inclusion_std_con_cost,
--inclusion_std_con_revenue,
--inclusion_std_con_adjustments,
--inclusion_std_prp_units,
--inclusion_std_prp_value,
--inclusion_std_prp_cost,
--inclusion_std_prp_revenue,
--inclusion_revisions,
--actual_figures,
--cancelled_value,
--dandc_value,
--allocated_dandc_value,
--unallocated_dandc_value,
--under_dandc,
--booking_adjustments,
--onscreen_con_mkgood_value,
onscreen_con_mkgood_cost,
--onscreen_con_mkgood_mkgd,
--onscreen_prp_mkgood_value,
--onscreen_prp_mkgood_cost,
--onscreen_prp_mkgood_mkgd,
--cinelights_con_mkgood_value,
cinelights_con_mkgood_cost--,
--cinelights_con_mkgood_mkgd,
--cinelights_prp_mkgood_value,
--cinelights_prp_mkgood_cost,
--cinelights_prp_mkgood_mkgd,
--cinemarketing_con_mkgood_value,
--cinemarketing_con_mkgood_cost,
--cinemarketing_con_mkgood_mkgd,
--cinemarketing_prp_mkgood_value,
--cinemarketing_prp_mkgood_cost,
--cinemarketing_prp_mkgood_mkgd,
--outpost_std_con_units,
--outpost_std_con_value,
--outpost_std_con_cost,
--outpost_std_con_takeouts,
--outpost_std_con_adjustments,
--outpost_std_prp_units,
--outpost_std_prp_value,
--outpost_std_prp_cost,
--outpost_std_prp_takeouts,
--outpost_pxy_con_units,
--outpost_pxy_con_value,
--outpost_pxy_con_cost,
--outpost_pxy_prp_units,
--outpost_pxy_prp_value,
--outpost_pxy_prp_cost,
--outpost_revisions	,
--outpost_con_mkgood_value,
--outpost_con_mkgood_cost,
--outpost_con_mkgood_mkgd,
--outpost_prp_mkgood_value,
--outpost_prp_mkgood_cost,
--outpost_prp_mkgood_mkgd,
--outpost_revisions_super_wall,
--statutory_revenue
) values
(
--isnull(@onscreen_std_con_units,0),
--isnull(@onscreen_std_con_value,0),
isnull(@onscreen_std_con_cost,0),
--isnull(@onscreen_std_con_takeouts,0),
isnull(@onscreen_std_con_adjustments,0),
--isnull(@onscreen_std_prp_units,0),
--isnull(@onscreen_std_prp_value,0),
--isnull(@onscreen_std_prp_cost,0),
--isnull(@onscreen_std_prp_takeouts,0),
--isnull(@onscreen_pxy_con_units,0),
--isnull(@onscreen_pxy_con_value,0),
isnull(@onscreen_pxy_con_cost,0),
--isnull(@onscreen_pxy_prp_units,0),
--isnull(@onscreen_pxy_prp_value,0),
--isnull(@onscreen_pxy_prp_cost,0),
--isnull(@onscreen_revisions,0),
--isnull(@cinelights_std_con_units,0),
--isnull(@cinelights_std_con_value,0),
isnull(@cinelights_std_con_cost,0),
--isnull(@cinelights_std_con_takeouts,0),
isnull(@cinelights_std_con_adjustments,0),
--isnull(@cinelights_std_prp_units,0),
--isnull(@cinelights_std_prp_value,0),
--isnull(@cinelights_std_prp_cost,0),
--isnull(@cinelights_std_prp_takeouts,0),
--isnull(@cinelights_pxy_con_units,0),
--isnull(@cinelights_pxy_con_value,0),
isnull(@cinelights_pxy_con_cost,0),
--isnull(@cinelights_pxy_prp_units,0),
--isnull(@cinelights_pxy_prp_value,0),
--isnull(@cinelights_pxy_prp_cost,0),
--isnull(@cinelights_revisions,0),
--isnull(@cinemarketing_std_con_units,0),
--isnull(@cinemarketing_std_con_value,0),
--isnull(@cinemarketing_std_con_cost,0),
--isnull(@cinemarketing_std_con_takeouts,0),
--isnull(@cinemarketing_std_con_adjustments,0),
--isnull(@cinemarketing_std_prp_units,0),
--isnull(@cinemarketing_std_prp_value,0),
--isnull(@cinemarketing_std_prp_cost,0),
--isnull(@cinemarketing_std_prp_takeouts,0),
--isnull(@cinemarketing_pxy_con_units,0),
--isnull(@cinemarketing_pxy_con_value,0),
--isnull(@cinemarketing_pxy_con_cost,0),
--isnull(@cinemarketing_pxy_prp_units,0),
--isnull(@cinemarketing_pxy_prp_value,0),
--isnull(@cinemarketing_pxy_prp_cost,0),
--isnull(@cinemarketing_revisions,0),
--isnull(@inclusion_std_con_units,0),
--isnull(@inclusion_std_con_value,0),
--isnull(@inclusion_std_con_cost,0),
--isnull(@inclusion_std_con_revenue,0),
--isnull(@inclusion_std_con_adjustments,0),
--isnull(@inclusion_std_prp_units,0),
--isnull(@inclusion_std_prp_value,0),
--isnull(@inclusion_std_prp_cost,0),
--isnull(@inclusion_std_prp_revenue,0),
--isnull(@inclusion_revisions,0),
--isnull(@actual_figures,0),
--isnull(@cancelled_value,0),
--isnull(@dandc_value,0),
--isnull(@allocated_dandc_value,0),
--isnull(@unallocated_dandc_value,0),
--isnull(@under_dandc,0),
--isnull(@booking_adjustments,0),
--isnull(@onscreen_con_mkgood_value,0),
isnull(@onscreen_con_mkgood_cost,0),
--isnull(@onscreen_con_mkgood_mkgd,0),
--isnull(@onscreen_prp_mkgood_value,0),
--isnull(@onscreen_prp_mkgood_cost,0),
--isnull(@onscreen_prp_mkgood_mkgd,0),
--isnull(@cinelights_con_mkgood_value,0),
isnull(@cinelights_con_mkgood_cost,0)--,
--isnull(@cinelights_con_mkgood_mkgd,0),
--isnull(@cinelights_prp_mkgood_value,0),
--isnull(@cinelights_prp_mkgood_cost,0),
--isnull(@cinelights_prp_mkgood_mkgd,0),
--isnull(@cinemarketing_con_mkgood_value,0),
--isnull(@cinemarketing_con_mkgood_cost,0),
--isnull(@cinemarketing_con_mkgood_mkgd,0),
--isnull(@cinemarketing_prp_mkgood_value,0),
--isnull(@cinemarketing_prp_mkgood_cost,0),
--isnull(@cinemarketing_prp_mkgood_mkgd,0),
--isnull(@outpost_std_con_units,0),
--isnull(@outpost_std_con_value,0),
--isnull(@outpost_std_con_cost,0),
--isnull(@outpost_std_con_takeouts,0),
--isnull(@outpost_std_con_adjustments,0),
--isnull(@outpost_std_prp_units,0),
--isnull(@outpost_std_prp_value,0),
--isnull(@outpost_std_prp_cost,0),
--isnull(@outpost_std_prp_takeouts,0),
--isnull(@outpost_pxy_con_units,0),
--isnull(@outpost_pxy_con_value,0),
--isnull(@outpost_pxy_con_cost,0),
--isnull(@outpost_pxy_prp_units,0),
--isnull(@outpost_pxy_prp_value,0),
--isnull(@outpost_pxy_prp_cost,0),
--isnull(@outpost_revisions,0),
--isnull(@outpost_con_mkgood_value,0),
--isnull(@outpost_con_mkgood_cost,0),
--isnull(@outpost_con_mkgood_mkgd,0),
--isnull(@outpost_prp_mkgood_value,0),
--isnull(@outpost_prp_mkgood_cost,0),
--isnull(@outpost_prp_mkgood_mkgd,0),
--isnull(@outpost_revisions_super_wall,0),
--isnull(@statutory_revenue,0)
)

select 	--onscreen_std_con_units,
		--		onscreen_std_con_value,
				onscreen_std_con_cost,
		--		onscreen_std_con_takeouts,
				onscreen_std_con_adjustments,
		--		onscreen_std_prp_units,
		--		onscreen_std_prp_value,
		--		onscreen_std_prp_cost,
		--		onscreen_std_prp_takeouts,
		--		onscreen_pxy_con_units,
		--		onscreen_pxy_con_value,
				onscreen_pxy_con_cost,
		--		onscreen_pxy_prp_units,
		--		onscreen_pxy_prp_value,
		--		onscreen_pxy_prp_cost,
		--		onscreen_revisions,
		--		cinelights_std_con_units,
		--		cinelights_std_con_value,
				cinelights_std_con_cost,
		--		cinelights_std_con_takeouts,
				cinelights_std_con_adjustments,
		--		cinelights_std_prp_units,
		--		cinelights_std_prp_value,
		--		cinelights_std_prp_cost,
		--		cinelights_std_prp_takeouts,
		--		cinelights_pxy_con_units,
		--		cinelights_pxy_con_value,
				cinelights_pxy_con_cost,
		--		cinelights_pxy_prp_units,
		--		cinelights_pxy_prp_value,
		--		cinelights_pxy_prp_cost,
		--		cinelights_revisions,
		--		cinemarketing_std_con_units,
		--		cinemarketing_std_con_value,
		--		cinemarketing_std_con_cost,
		--		cinemarketing_std_con_takeouts,
		--		cinemarketing_std_con_adjustments,
		--		cinemarketing_std_prp_units,
		--		cinemarketing_std_prp_value,
		--		cinemarketing_std_prp_cost,
		--		cinemarketing_std_prp_takeouts,
		--		cinemarketing_pxy_con_units,
		--		cinemarketing_pxy_con_value,
		--		cinemarketing_pxy_con_cost,
		--		cinemarketing_pxy_prp_units,
		--		cinemarketing_pxy_prp_value,
		--		cinemarketing_pxy_prp_cost,
		--		cinemarketing_revisions,
		--		inclusion_std_con_units,
		--		inclusion_std_con_value,
		--		inclusion_std_con_cost,
		--		inclusion_std_con_revenue,
		--		inclusion_std_con_adjustments,
		--		inclusion_std_prp_units,
		--		inclusion_std_prp_value,
		--		inclusion_std_prp_cost,
		--		inclusion_std_prp_revenue,
		--		inclusion_revisions,
		--		actual_figures,
		--		cancelled_value,
		--		dandc_value,
		--		allocated_dandc_value,
		--		unallocated_dandc_value,
		--		under_dandc,
		--		booking_adjustments,
		--		onscreen_con_mkgood_value,
				onscreen_con_mkgood_cost,
		--		onscreen_con_mkgood_mkgd,
		--		onscreen_prp_mkgood_value,
		--		onscreen_prp_mkgood_cost,
		--		onscreen_prp_mkgood_mkgd,
		--		cinelights_con_mkgood_value,
				cinelights_con_mkgood_cost
				--,
		--		cinelights_con_mkgood_mkgd,
		--		cinelights_prp_mkgood_value,
		--		cinelights_prp_mkgood_cost,
		--		cinelights_prp_mkgood_mkgd,
		--		cinemarketing_con_mkgood_value,
		--		cinemarketing_con_mkgood_cost,
		--		cinemarketing_con_mkgood_mkgd,
		--		cinemarketing_prp_mkgood_value,
		--		cinemarketing_prp_mkgood_cost,
		--		cinemarketing_prp_mkgood_mkgd,
		--		outpost_std_con_units,
		--		outpost_std_con_value,
		--		outpost_std_con_cost,
		--		outpost_std_con_takeouts,
		--		outpost_std_con_adjustments,
		--		outpost_std_prp_units,
		--		outpost_std_prp_value,
		--		outpost_std_prp_cost,
		--		outpost_std_prp_takeouts,
		--		outpost_pxy_con_units,
		--		outpost_pxy_con_value,
		--		outpost_pxy_con_cost,
		--		outpost_pxy_prp_units,
		--		outpost_pxy_prp_value,
		--		outpost_pxy_prp_cost,
		--		outpost_revisions	,
		--		outpost_con_mkgood_value,
		--		outpost_con_mkgood_cost,
		--		outpost_con_mkgood_mkgd,
		--		outpost_prp_mkgood_value,
		--		outpost_prp_mkgood_cost,
		--		outpost_prp_mkgood_mkgd	,
		--		outpost_revisions_super_wall,
		--		statutory_revenue
from 		#values  with (nolock)

return 0
GO
