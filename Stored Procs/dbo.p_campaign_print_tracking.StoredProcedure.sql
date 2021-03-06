/****** Object:  StoredProcedure [dbo].[p_campaign_print_tracking]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_print_tracking]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_print_tracking]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_campaign_print_tracking] @campaign_no integer
as

declare 	@print_id    					integer,
			@actual_qty       				integer,
        	@scheduled_qty_in 				integer,
        	@scheduled_qty_out 				integer,
			@complex_qty					integer,
			@incoming_qty					integer,
			@requested_qty					integer,
			@calculated_qty					integer,
			@print_name						varchar(50),
			@error							integer,
			@print_medium					char(1),
			@three_d_type					int,
			@imax_count						integer,
			@nom_actual_qty	 				integer,
			@nom_scheduled_qty_in			integer,
			@nom_scheduled_qty_out			integer,	
			@nom_incoming_qty				integer,
			@nom_complex_qty				integer,
			@nominal_qty					integer,
			@digital_distribution_charge	char(1),
			@digital_distribution_amount	money,
			@inclusion_amount				money

create table #print_select
(
	print_id						integer			null,
	print_name						varchar(50)		null,
	requested_qty					integer			null,
	nominal_qty						integer			null,
	calculated_qty					integer			null,
	actual_qty	 					integer			null,
	scheduled_qty_in				integer			null,
	scheduled_qty_out				integer			null,	
	incoming_qty					integer			null,
	complex_qty						integer			null,
	imax_count						integer			null,
	nom_actual_qty	 				integer			null,
	nom_scheduled_qty_in			integer			null,
	nom_scheduled_qty_out			integer			null,	
	nom_incoming_qty				integer			null,
	nom_complex_qty					integer			null,
	print_medium					char(1)			null,
	three_d_type					integer			null,
	digital_distribution_charge		char(1)			null,
	digital_distribution_amount		money			null,
	inclusion_amount				money			null
)	

/*
 * Declare cursor static for each print in the campaign
 */

declare 	print_csr cursor static for 
select 		print_id,
			requested_qty,
			nominal_qty,
			calculated_qty,
			print_medium,
			three_d_type,
			digital_distribution_charge
from 		film_campaign_prints
where 		campaign_no = @campaign_no

/*
 * Get Totals for a particular campaign print
 */

open print_csr
fetch print_csr into @print_id, @requested_qty, @nominal_qty, @calculated_qty, @print_medium, @three_d_type, @digital_distribution_charge
while(@@fetch_status = 0)
begin

	select 	@print_name = print_name 
	from 	film_print
	where 	print_id = @print_id
	
	select 	@actual_qty = sum(branch_qty),
			@nom_actual_qty = sum(branch_nominal_qty)
	from 	print_transactions
	where 	print_id = @print_id 
	and		campaign_no = @campaign_no 
	and		ptran_status = 'C'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@scheduled_qty_in = sum(branch_qty),
			@nom_scheduled_qty_in = sum(branch_nominal_qty)
	from 	print_transactions
	where 	print_id = @print_id 
	and		ptran_status = 'S' 
	and		campaign_no = @campaign_no 
	and		branch_qty >= 0
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@scheduled_qty_out = sum(branch_qty),
			@nom_scheduled_qty_out = sum(branch_nominal_qty)
	from 	print_transactions
	where 	print_id = @print_id 
	and		ptran_status = 'S' 
	and		campaign_no = @campaign_no 
	and		branch_qty < 0
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@incoming_qty = sum(branch_qty),
			@nom_incoming_qty = sum(branch_nominal_qty)
	from 	print_transactions
	where 	print_id = @print_id 
	and		campaign_no = @campaign_no 
	and		ptran_type = 'I'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@complex_qty = sum(cinema_qty),
			@nom_complex_qty = sum(cinema_nominal_qty)
	from	print_transactions
	where 	print_id = @print_id 
	and		campaign_no = @campaign_no 
	and		ptran_status = 'C'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@imax_count = count(fcc.complex_id)
	from 	film_campaign_complex fcc,
			complex c,
			complex_three_d_type_xref td
	where 	fcc.campaign_no = @campaign_no 
	and 	c.complex_id = fcc.complex_id 
	and 	c.complex_category = 'I'
	and		'F' = @print_medium
	and		td.three_d_type = @three_d_type
	and		td.complex_id = c.complex_id

	if @digital_distribution_charge = 'Y'
	begin
		select 	@digital_distribution_amount = @calculated_qty * 50.0
		
		select  @inclusion_amount = isnull((sum(inclusion_qty * inclusion_charge)),0)
		from	inclusion 
		where	campaign_no = @campaign_no
		and		inclusion_type = 22

		select 	@inclusion_amount = @inclusion_amount + isnull(sum(takeout_rate), 0)
		from	inclusion_spot,
				inclusion
		where 	inclusion.campaign_no = @campaign_no
		and		inclusion_type = 22
		and		inclusion.inclusion_id = inclusion_spot.inclusion_id
	end
	else
	begin
		select 	@digital_distribution_amount = 0.0,
				@inclusion_amount = 0.0
	end

	insert into #print_select
	(	
	print_id,
	print_name,
	requested_qty,
	nominal_qty,
	calculated_qty,
	actual_qty,
	scheduled_qty_in,
	scheduled_qty_out,		
	incoming_qty,
	complex_qty,
	imax_count,
	nom_actual_qty,
	nom_scheduled_qty_in,
	nom_scheduled_qty_out,	
	nom_incoming_qty,
	nom_complex_qty, 
	print_medium, 
	three_d_type,
	digital_distribution_charge,
	digital_distribution_amount,
	inclusion_amount
	) values
	(
 	IsNull(@print_id,0), 
	IsNull(@print_name, ''),
	IsNull(@requested_qty,0),
	IsNull(@nominal_qty,0),
	IsNull(@calculated_qty,0),
	IsNull(@actual_qty,0),
	IsNull(@scheduled_qty_in,0),
	IsNull(@scheduled_qty_out,0),
	IsNull(@incoming_qty,0),
	IsNull(@complex_qty,0),
	IsNull(@imax_count,0),
	IsNull(@nom_actual_qty,0),
	IsNull(@nom_scheduled_qty_in,0),
	IsNull(@nom_scheduled_qty_out,0),
	IsNull(@nom_incoming_qty,0),
	IsNull(@nom_complex_qty,0), 
	@print_medium, 
	@three_d_type,
	@digital_distribution_charge,
	IsNull(@digital_distribution_amount,0),
	IsNull(@inclusion_amount,0)
	)
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	fetch print_csr into @print_id, @requested_qty, @nominal_qty, @calculated_qty, @print_medium, @three_d_type, @digital_distribution_charge
end	

close print_csr

/*
 * Return results
 */

select 		@campaign_no as campaign_no,
			print_id,
			print_name,
			requested_qty,
			nominal_qty,
			calculated_qty,
			incoming_qty,
			actual_qty,
			scheduled_qty_in,
			scheduled_qty_out,		
			complex_qty,
			imax_count,
			nom_incoming_qty,
			nom_actual_qty,
			nom_scheduled_qty_in,
			nom_scheduled_qty_out,	
			nom_complex_qty,
			print_medium,
			three_d_type,
			digital_distribution_charge,
			digital_distribution_amount,
			inclusion_amount
from		#print_select
order by 	print_id

return 0

error:

	raiserror ('Error retrieving Prints information', 16, 1)
	close print_csr
	return -1
GO
