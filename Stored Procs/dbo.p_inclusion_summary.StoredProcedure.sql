/****** Object:  StoredProcedure [dbo].[p_inclusion_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc [dbo].[p_inclusion_summary] 	@campaign_no			int

as

declare		@error								int,
			@ticket_cost						decimal(14,4),
			@ticket_value						decimal(14,4),
			@ticket_vm_cost						decimal(14,4),
			@ticket_billing_credit				decimal(14,4),
			@ticket_number						int,
			@ticket_tkout_number				int,
			@ticket_qty							int,
			@misc_cost							decimal(14,4),
			@misc_value							decimal(14,4),
			@misc_vm_cost						decimal(14,4),
			@misc_billing_credit				decimal(14,4),
			@misc_number						int,
			@misc_tkout_number					int,
			@media_proxy_cost					decimal(14,4),
			@media_proxy_value					decimal(14,4),
			@media_proxy_vm_cost				decimal(14,4),
			@media_proxy_billing_credit			decimal(14,4),
			@media_proxy_number					int,
			@invoicing_cost					decimal(14,4),
			@invoicing_value					decimal(14,4),
			@invoicing_vm_cost				decimal(14,4),
			@invoicing_billing_credit			decimal(14,4),
			@invoicing_number					int,
			@production_cost					decimal(14,4),
			@production_value					decimal(14,4),
			@production_vm_cost					decimal(14,4),
			@production_billing_credit			decimal(14,4),
			@production_number					int,
			@production_tkout_number			int,
			@cinemarketing_cost					decimal(14,4),
			@cinemarketing_value				decimal(14,4),
			@cinemarketing_vm_cost				decimal(14,4),
			@cinemarketing_billing_credit		decimal(14,4),
			@cinemarketing_number				int,
			@onscreen_tkout_number				int,
			@cinemarketing_tkout_number			int,
			@cinelight_tkout_number				int,
			@onscreen_tkout_ok					char(1),
			@cinemarketing_tkout_ok				char(1),
			@cinelight_tkout_ok					char(1),
			@onscreen_tkout_amount				decimal(14,4),
			@cinemarketing_tkout_amount			decimal(14,4),
			@cinelight_tkout_amount				decimal(14,4),
			@inclusion_category					char(1),
			@billings							decimal(14,4),
			@commission							decimal(14,4),
			@billing_credit						decimal(14,4),
			@billing_period						datetime,
			@takeout_amount						decimal(14,4),
			@payment							decimal(14,4),
			@takeout_left						decimal(14,4),
			@ticket_revenue						decimal(14,4),
			@misc_revenue						decimal(14,4),
			@media_proxy_revenue				decimal(14,4),
			@invoicing_revenue				decimal(14,4),
			@production_revenue					decimal(14,4),
			@cinemarketing_revenue				decimal(14,4),
			@ticket_schedule					decimal(14,4),
			@misc_schedule						decimal(14,4),
			@media_proxy_schedule				decimal(14,4),
			@invoicing_schedule				decimal(14,4),
			@production_schedule				decimal(14,4),
			@cinemarketing_schedule				decimal(14,4)

select 		@onscreen_tkout_ok = 'Y'
select 		@cinemarketing_tkout_ok = 'Y'
select 		@cinelight_tkout_ok = 'Y'

select 		@ticket_billing_credit = 0
select		@cinemarketing_billing_credit = 0
select		@misc_billing_credit = 0
select		@media_proxy_billing_credit = 0
select		@invoicing_billing_credit = 0
select		@production_billing_credit = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Setting Takeout OK Variables', 16, 1)
	return -1
end

select 		@ticket_cost = isnull(sum(inclusion_charge * inclusion_qty),0),
			@ticket_value = isnull(sum(inclusion_value * inclusion_qty),0),
			@ticket_vm_cost = isnull(sum(vm_cost_amount),0),
			@ticket_number = count(inclusion_id),
			@ticket_qty = isnull(sum(inclusion_qty),0)
from		inclusion
where 		campaign_no = @campaign_no
and 		inclusion_type = 8
and			inclusion_category = 'S'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Tickets 1', 16, 1)
	return -1
end

/*@ticket_billing_credit*/


select		@ticket_tkout_number = count(inclusion_id)
from		inclusion
where 		campaign_no = @campaign_no
and 		inclusion_type = 8
and			inclusion_category <> 'S'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Tickets 2', 16, 1)
	return -1
end

select 		@misc_cost = isnull(sum(inclusion_charge * inclusion_qty),0),
			@misc_value = isnull(sum(inclusion_value * inclusion_qty),0),
			@misc_vm_cost = isnull(sum(vm_cost_amount),0),
			@misc_number = count(inclusion_id)
from		inclusion,
			inclusion_type
where 		campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group in ('G','D')
and			inclusion.inclusion_category = 'S'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Misc 1', 16, 1)
	return -1
end

/*@misc_billing_credit*/

select 		@misc_tkout_number = count(inclusion_id)
from		inclusion,
			inclusion_type
where 		campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group in ('G','D')
and			inclusion.inclusion_category <> 'S'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Misc 2', 16, 1)
	return -1
end

select 		@media_proxy_cost = isnull(sum(charge_rate),0),
			@media_proxy_value = isnull(sum(rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_format in ('M', 'T')

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Media Proxy 1', 16, 1)
	return -1
end

select 		@media_proxy_vm_cost = isnull(sum(vm_cost_amount),0),
			@media_proxy_number = count(inclusion_id)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_format in ('M', 'T')

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Media Proxy 2', 16, 1)
	return -1
end

select 		@invoicing_cost = isnull(sum(charge_rate),0),
			@invoicing_value = isnull(sum(rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_format = 'I'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Media Proxy 1', 16, 1)
	return -1
end

select 		@invoicing_vm_cost = isnull(sum(vm_cost_amount),0),
			@invoicing_number = count(inclusion_id)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_format = 'I'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Media Proxy 2', 16, 1)
	return -1
end

/*@media_proxy_billing_credit*/

select 		@production_cost = isnull(sum(inclusion_charge * inclusion_qty),0),
			@production_value = isnull(sum(inclusion_value * inclusion_qty),0),
			@production_vm_cost = isnull(sum(vm_cost_amount),0),
			@production_number = count(inclusion_id)
from		inclusion,
			inclusion_type
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group = 'P'
and			inclusion.inclusion_category = 'S'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Production 1', 16, 1)
	return -1
end

/*@production_billing_credit*/

select 		@production_tkout_number = count(inclusion_id)
from		inclusion,
			inclusion_type
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group = 'P'
and			inclusion.inclusion_category <> 'S'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Production 2', 16, 1)
	return -1
end


select 		@cinemarketing_cost = isnull(sum(charge_rate),0),
			@cinemarketing_value = isnull(sum(rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			(inclusion.inclusion_type = 5
or			inclusion.inclusion_type = 18)

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Cinemarketing 1', 16, 1)
	return -1
end

select 		@cinemarketing_vm_cost = isnull(sum(vm_cost_amount),0),
			@cinemarketing_number = count(inclusion_id)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			(inclusion.inclusion_type = 5
or			inclusion.inclusion_type = 18)

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Cinemarketing 2', 16, 1)
	return -1
end

/*@cinemarketing_billing_credit*/

select 		@onscreen_tkout_number = count(distinct inclusion.inclusion_id),
			@onscreen_tkout_amount = isnull(sum(takeout_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			(inclusion.inclusion_category = 'D' 
or			inclusion.inclusion_category = 'F')

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Onscreen Takeout', 16, 1)
	return -1
end

select 		@cinelight_tkout_number = count(distinct inclusion.inclusion_id),
			@cinelight_tkout_amount = isnull(sum(takeout_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_category = 'C' 

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Cinelight Takeout', 16, 1)
	return -1
end

select 		@cinemarketing_tkout_number = count(distinct inclusion.inclusion_id),
			@cinemarketing_tkout_amount = isnull(sum(takeout_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_category = 'I' 

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Cinemarketing Takeout', 16, 1)
	return -1
end

select 		@ticket_revenue = isnull(sum(inclusion_charge * inclusion_qty),0) - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		campaign_no = @campaign_no
and 		inclusion.inclusion_type = 8
and			inclusion.inclusion_category = 'S'
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Tickets', 16, 1)
	return -1
end

select 		@misc_revenue = isnull(sum(inclusion_charge * inclusion_qty),0) - isnull(sum(vm_cost_amount),0)
from		inclusion,
			inclusion_type
where 		campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group in ('G', 'D', 'F', 'L', 'U', 'V')
and			inclusion.inclusion_category = 'S'
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Misc', 16, 1)
	return -1
end
			

select 		@media_proxy_revenue = isnull(sum(charge_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_format in ('M', 'T')
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 1', 16, 1)
	return -1
end

select 		@media_proxy_revenue = @media_proxy_revenue - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_format in ('M', 'T')
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 2', 16, 1)
	return -1
end

select 		@invoicing_revenue = isnull(sum(charge_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_format = 'I'
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 1', 16, 1)
	return -1
end

select 		@invoicing_revenue = @invoicing_revenue - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_format = 'I'
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 2', 16, 1)
	return -1
end

/*@media_proxy_billing_credit*/

select 		@production_revenue = isnull(sum(inclusion_charge * inclusion_qty),0) - isnull(sum(vm_cost_amount),0)
from		inclusion,
			inclusion_type
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group = 'P'
and			inclusion.inclusion_category = 'S'
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting revenue Production', 16, 1)
	return -1
end

select 		@cinemarketing_revenue = isnull(sum(charge_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			(inclusion.inclusion_type = 5
or			inclusion.inclusion_type = 18)
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Cinemarketing 1', 16, 1)
	return -1
end

select 		@cinemarketing_revenue = @cinemarketing_revenue - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			(inclusion.inclusion_type = 5
or			inclusion.inclusion_type = 18)
and			inclusion.include_revenue = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Cinemarketing 2', 16, 1)
	return -1
end

select 		@ticket_schedule = isnull(sum(inclusion_charge * inclusion_qty),0) - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		campaign_no = @campaign_no
and 		inclusion.inclusion_type = 8
and			inclusion.inclusion_category = 'S'
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Tickets', 16, 1)
	return -1
end

select 		@misc_schedule = isnull(sum(inclusion_charge * inclusion_qty),0) - isnull(sum(vm_cost_amount),0)
from		inclusion,
			inclusion_type
where 		campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group in ('G','D')
and			inclusion.inclusion_category = 'S'
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Misc', 16, 1)
	return -1
end
			

select 		@media_proxy_schedule = isnull(sum(charge_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_format in ('M', 'T')
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 1', 16, 1)
	return -1
end

select 		@media_proxy_schedule = @media_proxy_schedule - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_format in ('M', 'T')
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 2', 16, 1)
	return -1
end

select 		@invoicing_schedule = isnull(sum(charge_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.inclusion_format = 'I'
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 1', 16, 1)
	return -1
end

select 		@invoicing_schedule = @invoicing_schedule - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_format = 'I'
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Media Proxy 2', 16, 1)
	return -1
end

/*@media_proxy_billing_credit*/

select 		@production_schedule = isnull(sum(inclusion_charge * inclusion_qty),0) - isnull(sum(vm_cost_amount),0)
from		inclusion,
			inclusion_type
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_type.inclusion_type = inclusion.inclusion_type
and			inclusion_type.inclusion_type_group = 'P'
and			inclusion.inclusion_category = 'S'
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting revenue Production', 16, 1)
	return -1
end

select 		@cinemarketing_schedule = isnull(sum(charge_rate),0)
from		inclusion,
			inclusion_spot
where 		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			(inclusion.inclusion_type = 5
or			inclusion.inclusion_type = 18)
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Cinemarketing 1', 16, 1)
	return -1
end

select 		@cinemarketing_schedule = @cinemarketing_schedule - isnull(sum(vm_cost_amount),0)
from		inclusion
where 		inclusion.campaign_no = @campaign_no
and			(inclusion.inclusion_type = 5
or			inclusion.inclusion_type = 18)
and			inclusion.include_schedule = 'Y'

select @error = @@error
if @error <> 0
begin
	raiserror ('Inclusion Summary Error: Getting Revenue Cinemarketing 2', 16, 1)
	return -1
end

declare		takeout_csr cursor static forward_only for
select		inclusion_spot.billing_period,
			sum(takeout_rate),
			inclusion_category
from		inclusion_spot,
			inclusion
where		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_category <> 'S'
group by 	inclusion_spot.billing_period,
			inclusion_category
order by 	inclusion_category,
			inclusion_spot.billing_period

open takeout_csr
fetch takeout_csr into @billing_period,  @takeout_amount, @inclusion_category
while(@@fetch_status=0)
begin

	if @inclusion_category = 'F' --film
	begin
		select 	@billings = sum(campaign_spot.charge_rate)
		from	campaign_spot,
				campaign_package
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 1
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period

		select 	@commission = 0 - sum(campaign_spot.charge_rate * film_campaign.commission)
		from	campaign_spot,
				campaign_package,
				film_campaign
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 1
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		film_campaign.campaign_no = @campaign_no
		and		film_campaign.campaign_no = campaign_spot.campaign_no
		and		film_campaign.campaign_no = campaign_package.campaign_no

		select 	@billing_credit = sum(spot_amount)
		from	spot_liability,
				campaign_spot,
				campaign_package,
				liability_type
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 1
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		spot_liability.spot_id = campaign_spot.spot_id
		and		liability_type.liability_type_id = spot_liability.liability_type
		and		liability_category_id = 2		

		select 	@payment = sum(spot_amount)
		from	spot_liability,
				campaign_spot,
				campaign_package,
				liability_type
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 1
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		spot_liability.spot_id = campaign_spot.spot_id
		and		liability_category_id = 6		
		and		liability_type.liability_type_id = spot_liability.liability_type

		if @onscreen_tkout_ok = 'Y'
		begin
			select @takeout_left = @billings - @commission - @billing_credit - @payment
			if @takeout_left < @takeout_amount
				select @onscreen_tkout_ok = 'N'
		end

	end
	else if @inclusion_category = 'D' --dmg
	begin
		select 	@billings = sum(campaign_spot.charge_rate)
		from	campaign_spot,
				campaign_package
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 2
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period

		select 	@commission = 0 - sum(campaign_spot.charge_rate * film_campaign.commission)
		from	campaign_spot,
				campaign_package,
				film_campaign
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 2
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		film_campaign.campaign_no = @campaign_no
		and		film_campaign.campaign_no = campaign_spot.campaign_no
		and		film_campaign.campaign_no = campaign_package.campaign_no

		select 	@billing_credit = sum(spot_amount)
		from	spot_liability,
				campaign_spot,
				campaign_package,
				liability_type
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 2
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		spot_liability.spot_id = campaign_spot.spot_id
		and		liability_type.liability_type_id = spot_liability.liability_type
		and		liability_category_id = 2		

		select 	@payment = sum(spot_amount)
		from	spot_liability,
				campaign_spot,
				campaign_package,
				liability_type
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_package.media_product_id = 2
		and		campaign_spot.campaign_no = campaign_package.campaign_no
		and		campaign_spot.campaign_no = @campaign_no
		and		campaign_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		spot_liability.spot_id = campaign_spot.spot_id
		and		liability_category_id = 6		
		and		liability_type.liability_type_id = spot_liability.liability_type

		if @onscreen_tkout_ok = 'Y'
		begin
			select @takeout_left = @billings - @commission - @billing_credit - @payment
			if @takeout_left < @takeout_amount
				select @onscreen_tkout_ok = 'N'
		end
	end
	else if @inclusion_category = 'C' --cinelights
	begin
		select 	@billings = sum(cinelight_spot.charge_rate)
		from	cinelight_spot,
				cinelight_package
		where	cinelight_spot.package_id = cinelight_package.package_id
		and		cinelight_package.media_product_id = 3
		and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		and		cinelight_spot.campaign_no = @campaign_no
		and		cinelight_package.campaign_no = @campaign_no
		and		billing_period = @billing_period

		select 	@commission = 0 - sum(cinelight_spot.charge_rate * film_campaign.commission)
		from	cinelight_spot,
				cinelight_package,
				film_campaign
		where	cinelight_spot.package_id = cinelight_package.package_id
		and		cinelight_package.media_product_id = 3
		and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		and		cinelight_spot.campaign_no = @campaign_no
		and		cinelight_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		film_campaign.campaign_no = @campaign_no
		and		film_campaign.campaign_no = cinelight_spot.campaign_no
		and		film_campaign.campaign_no = cinelight_package.campaign_no

		select 	@billing_credit = sum(spot_amount)
		from	cinelight_spot_liability,
				cinelight_spot,
				cinelight_package,
				liability_type
		where	cinelight_spot.package_id = cinelight_package.package_id
		and		cinelight_package.media_product_id = 1
		and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		and		cinelight_spot.campaign_no = @campaign_no
		and		cinelight_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		cinelight_spot_liability.spot_id = cinelight_spot.spot_id
		and		liability_type.liability_type_id = cinelight_spot_liability.liability_type
		and		liability_category_id = 2		

		select 	@payment = sum(spot_amount)
		from	cinelight_spot_liability,
				cinelight_spot,
				cinelight_package,
				liability_type
		where	cinelight_spot.package_id = cinelight_package.package_id
		and		cinelight_package.media_product_id = 1
		and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		and		cinelight_spot.campaign_no = @campaign_no
		and		cinelight_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		cinelight_spot_liability.spot_id = cinelight_spot.spot_id
		and		liability_category_id = 6		
		and		liability_type.liability_type_id = cinelight_spot_liability.liability_type

		if @cinelight_tkout_ok = 'Y'
		begin
			select @takeout_left = @billings - @commission - @billing_credit - @payment
			if @takeout_left < @takeout_amount
				select @cinelight_tkout_ok = 'N'
		end
	end
	else if @inclusion_category = 'I' --cinemarketing
	begin
		select 	@billings = sum(charge_rate)
		from	inclusion_spot,
				inclusion,
				inclusion_type
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion.inclusion_type = inclusion_type.inclusion_type
		and		inclusion_type.inclusion_type_group = 'C'	

		select 	@commission = 0 - sum(charge_rate * inclusion.commission)
		from	inclusion_spot,
				inclusion,
				inclusion_type
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion.inclusion_type = inclusion_type.inclusion_type
		and		inclusion_type.inclusion_type_group = 'C'	

		select 	@billing_credit = sum(spot_amount)
		from	inclusion_spot_liability,
				inclusion_spot,
				inclusion,
				liability_type
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion_spot_liability.spot_id = inclusion_spot.spot_id
		and		liability_type.liability_type_id = inclusion_spot_liability.liability_type
		and		liability_category_id = 2		

		select 	@payment = sum(spot_amount)
		from	inclusion_spot_liability,
				inclusion_spot,
				inclusion,
				liability_type
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion_spot_liability.spot_id = inclusion_spot.spot_id
		and		liability_category_id = 6		
		and		liability_type.liability_type_id = inclusion_spot_liability.liability_type

		if @cinemarketing_tkout_ok = 'Y'
		begin
			select @takeout_left = @billings - @commission - @billing_credit - @payment
			if @takeout_left < @takeout_amount
				select @cinemarketing_tkout_ok = 'N'
		end
	end

	fetch takeout_csr into @billing_period,  @takeout_amount, @inclusion_category
end

deallocate takeout_csr		

select 		@ticket_cost 					as 	ticket_cost,
			@ticket_value 					as 	ticket_value,
			@ticket_vm_cost 				as 	ticket_vm_cost,
			@ticket_billing_credit 			as 	ticket_billing_credit,
			@ticket_number 					as 	ticket_number,
			@ticket_tkout_number 			as 	ticket_tkout_number,
			@ticket_qty						as  ticket_qty,
			@misc_cost 						as 	misc_cost,
			@misc_value 					as 	misc_value,
			@misc_vm_cost 					as 	misc_vm_cost,
			@misc_billing_credit 			as 	misc_billing_credit,
			@misc_number 					as 	misc_number,
			@misc_tkout_number 				as 	misc_tkout_number,
			@media_proxy_cost 				as 	media_proxy_cost,
			@media_proxy_value 				as 	media_proxy_value,
			@media_proxy_vm_cost 			as 	media_proxy_vm_cost,
			@media_proxy_billing_credit		as 	media_proxy_billing_credit,
			@media_proxy_number 			as 	media_proxy_number,
			@production_cost 				as 	production_cost,
			@production_value 				as 	production_value,
			@production_vm_cost 			as 	production_vm_cost,
			@production_billing_credit 		as 	production_billing_credit,
			@production_number 				as 	production_number,
			@production_tkout_number 		as 	production_tkout_number,
			@cinemarketing_cost 			as 	cinemarketing_cost,
			@cinemarketing_value 			as 	cinemarketing_value,
			@cinemarketing_vm_cost 			as 	cinemarketing_vm_cost,
			@cinemarketing_billing_credit 	as 	cinemarketing_billing_credit,
			@cinemarketing_number 			as 	cinemarketing_number,
			@onscreen_tkout_number 			as 	onscreen_tkout_number,
			@cinemarketing_tkout_number 	as 	cinemarketing_tkout_number,
			@cinelight_tkout_number 		as 	cinelight_tkout_number,
			@onscreen_tkout_ok 				as 	onscreen_tkout_ok,
			@cinemarketing_tkout_ok 		as 	cinemarketing_tkout_ok,
			@cinelight_tkout_ok 			as 	cinelight_tkout_ok,
			@onscreen_tkout_amount 			as 	onscreen_tkout_amount,
			@cinemarketing_tkout_amount 	as 	cinemarketing_tkout_amount,
			@cinelight_tkout_amount 		as 	cinelight_tkout_amount,
			@ticket_revenue					as	ticket_revenue,
			@misc_revenue					as	misc_revenue,
			@media_proxy_revenue			as	media_proxy_revenue,
			@production_revenue				as	production_revenue,
			@cinemarketing_revenue			as	cinemarketing_revenue,
			@ticket_schedule				as	ticket_schedule,
			@misc_schedule					as	misc_schedule,
			@media_proxy_schedule			as	media_proxy_schedule,
			@production_schedule			as	production_schedule,
			@cinemarketing_schedule			as	cinemarketing_schedule,
			@invoicing_cost 				as 	invoicing_cost,
			@invoicing_value 				as 	invoicing_value,
			@invoicing_vm_cost 			as 	invoicing_vm_cost,
			@invoicing_billing_credit		as 	invoicing_billing_credit,
			@invoicing_number 			as 	invoicing_number,
			@invoicing_revenue			as	invoicing_revenue,
			@invoicing_schedule			as	invoicing_schedule

return 0
GO
