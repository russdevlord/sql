/****** Object:  StoredProcedure [dbo].[p_schedule_invoicing_breakdown]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_invoicing_breakdown]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_invoicing_breakdown]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc [dbo].[p_schedule_invoicing_breakdown]		@campaign_no		int

as

declare		@error								int,
			@billing_period					datetime,
			@onscreen_amount				money,
			@offscreen_amount				money,
			@miscellaneous_amount			money,
			@production_amount				money,
			@outpost_amount					money,
			@start_date						datetime,
			@makedummy						smallint,
			@count							int


set nocount on

create table #invoicings
(
	billing_period		datetime		not null,
	invoicing_desc		varchar(100)	not null,
	invoicing_amount	money			not null,
	start_date			datetime		not null
)

select		@count = COUNT(*)
from		inclusion
where		campaign_no = @campaign_no
and			inclusion_type = 28

if @count = 0
begin
	declare 	invoice_period_csr cursor static forward_only for
	select		accounting_period.end_date,
				accounting_period.start_date
	from		accounting_period
	where		accounting_period.end_date between (select min(billing_period) from v_all_spot_billing_periods where campaign_no = @campaign_no) 
	and			(select max(billing_period) from v_all_spot_billing_periods where campaign_no = @campaign_no)
	for 		read only

	open invoice_period_csr
	fetch invoice_period_csr into @billing_period, @start_date
	while(@@fetch_status = 0)
	begin

		select	@onscreen_amount = 0,
				@offscreen_amount = 0,
				@miscellaneous_amount = 0,
				@production_amount = 0,
				@outpost_amount = 0

		select 	@onscreen_amount = isnull(sum(charge_rate),0)
		from 	campaign_spot
		where	campaign_no = @campaign_no
		and		spot_status <> 'D'
		and		billing_period = @billing_period

		select	@onscreen_amount = @onscreen_amount + isnull(sum(charge_rate),0)
		from	inclusion,
				inclusion_spot
		where	inclusion.campaign_no = @campaign_no
		and		inclusion.inclusion_id = inclusion_spot.inclusion_id
		and		inclusion_spot.billing_period = @billing_period 
		and		spot_status <> 'D'
		and		inclusion_type in (11, 12, 24, 29, 30, 31, 32, 33, 34, 36, 37, 38, 39, 41, 43, 44, 45, 46, 48, 50, 51, 52, 53, 55, 57, 58, 59, 60)
	
		select 	@offscreen_amount = isnull(sum(charge_rate),0)
		from 	cinelight_spot
		where	cinelight_spot.campaign_no = @campaign_no
		and		spot_status <> 'D'
		and		billing_period = @billing_period

		select	@offscreen_amount = isnull(@offscreen_amount,0) + isnull(sum(charge_rate),0)
		from	inclusion,
				inclusion_spot
		where	inclusion.campaign_no = @campaign_no
		and		inclusion.inclusion_id = inclusion_spot.inclusion_id
		and		inclusion_spot.billing_period = @billing_period 
		and		spot_status <> 'D'
		and		(inclusion_type = 13
		or		inclusion_type = 14
		or		inclusion_type = 5)

		select		@offscreen_amount = isnull(@offscreen_amount,0) + isnull(sum(inclusion_spot_liability.spot_amount),0)   
		from	 	inclusion_spot with (nolock),
					inclusion_spot_liability with (nolock)
		where		inclusion_spot.campaign_no = @campaign_no
		AND 		inclusion_spot.spot_status != 'P'
		and			inclusion_spot.billing_period = @billing_period
		AND			inclusion_spot_liability.liability_type in (10,16)
		AND			inclusion_spot.spot_id  = inclusion_spot_liability.spot_id

		select 	@miscellaneous_amount = isnull(sum(inclusion_qty * inclusion_charge),0)
		from	inclusion,
				inclusion_type
		where	inclusion_category in ('S','M')
		and		inclusion_format = 'S'
		and		campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		inclusion.invoice_client = 'Y'
		and		inclusion.inclusion_type = inclusion_type.inclusion_type
		and		inclusion_type.inclusion_type_group <> 'P'
		and		inclusion.inclusion_type <> 18

		select 	@production_amount = isnull(sum(inclusion_qty * inclusion_charge),0)
		from	inclusion,
				inclusion_type
		where	inclusion_category  in ('S','M')
		and		inclusion_format = 'S'
		and		campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		inclusion.invoice_client = 'Y'
		and		inclusion.inclusion_type = inclusion_type.inclusion_type
		and		inclusion_type.inclusion_type_group = 'P'

    
		select 	@outpost_amount = isnull(sum(charge_rate),0)
		from 	outpost_spot
		where	outpost_spot.campaign_no = @campaign_no
		and		spot_status <> 'D'
		and		billing_period = @billing_period

		select 	@outpost_amount = @outpost_amount + isnull(sum(charge_rate),0)
		from 	inclusion_spot
		where	campaign_no = @campaign_no
		and		spot_status <> 'D'
		and		billing_period = @billing_period
		and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)

		select @makedummy = 0

		select @onscreen_amount = isnull(@onscreen_amount,0) + isnull(@offscreen_amount,0)
	
		if @onscreen_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Media',
			@onscreen_amount,
			@start_date
			)
        
			select @makedummy = 1
        
		end

	/*	if @offscreen_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Offscreen',
			@offscreen_amount,
			@start_date
			)
        
			select @makedummy = 1
   		end
	*/

		if @outpost_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Retail',
			@outpost_amount,
			@start_date
			)
        
			select @makedummy = 1
   		end

		select @miscellaneous_amount = isnull(@miscellaneous_amount,0) + isnull(@production_amount ,0)

		if @miscellaneous_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Production & Services',
			@miscellaneous_amount,
			@start_date
			)
        
			select @makedummy = 1
		end

	/*	if @production_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Production',
			@production_amount,
			@start_date
			)
        
			select @makedummy = 1
		end
	*/
		if @makedummy = 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			' ',
			0,
			@start_date
			)
		end

		fetch invoice_period_csr into @billing_period, @start_date
	end
end
else
begin
	declare 	invoice_period_csr cursor static forward_only for
	select		accounting_period.end_date,
				accounting_period.start_date
	from		accounting_period
	where		accounting_period.end_date between (select min(billing_period) from inclusion_spot where campaign_no = @campaign_no and inclusion_id in (select inclusion_id from inclusion where inclusion_type = 28)) 
	and			(select max(billing_period) from inclusion_spot where campaign_no = @campaign_no and inclusion_id in (select inclusion_id from inclusion where inclusion_type = 28))
	for 		read only

	open invoice_period_csr
	fetch invoice_period_csr into @billing_period, @start_date
	while(@@fetch_status = 0)
	begin

		select	@onscreen_amount = 0,
				@miscellaneous_amount = 0,
				@production_amount = 0,
				@outpost_amount = 0

		select 	@onscreen_amount = isnull(sum(charge_rate),0)
		from 	inclusion_spot
		where	campaign_no = @campaign_no
		and		spot_status <> 'D'
		and		billing_period = @billing_period
		and		inclusion_id in (select inclusion_id from inclusion where inclusion_type = 28)

		select 	@miscellaneous_amount = isnull(sum(inclusion_qty * inclusion_charge),0)
		from	inclusion,
				inclusion_type
		where	inclusion_category in ('S','M')
		and		inclusion_format = 'S'
		and		campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		inclusion.invoice_client = 'Y'
		and		inclusion.inclusion_type = inclusion_type.inclusion_type
		and		inclusion_type.inclusion_type_group <> 'P'
		and		inclusion.inclusion_type <> 18

		select 	@production_amount = isnull(sum(inclusion_qty * inclusion_charge),0)
		from	inclusion,
				inclusion_type
		where	inclusion_category  in ('S','M')
		and		inclusion_format = 'S'
		and		campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		inclusion.invoice_client = 'Y'
		and		inclusion.inclusion_type = inclusion_type.inclusion_type
		and		inclusion_type.inclusion_type_group = 'P'

		select @makedummy = 0

		select @onscreen_amount = isnull(@onscreen_amount,0) + isnull(@offscreen_amount,0)
	
		if @onscreen_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Media',
			@onscreen_amount,
			@start_date
			)
        
			select @makedummy = 1
        
		end

		select @miscellaneous_amount = isnull(@miscellaneous_amount,0) + isnull(@production_amount ,0)

		if @miscellaneous_amount > 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			'Production & Services',
			@miscellaneous_amount,
			@start_date
			)
        
			select @makedummy = 1
		end

		if @makedummy = 0
		begin
			insert into #invoicings
			(
			billing_period,
			invoicing_desc,
			invoicing_amount,
			start_date
			) values 
			(
			@billing_period,
			' ',
			0,
			@start_date
			)
		end

		fetch invoice_period_csr into @billing_period, @start_date
	end	
end

select	billing_period,
		invoicing_desc,
		invoicing_amount,
		start_date 
from	#invoicings

return 0
GO
