/****** Object:  StoredProcedure [dbo].[p_print_print_schedule]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_print_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_print_print_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_print_print_schedule] @campaign_no 	integer
as

declare 	@error					integer,
         	@complex_id				integer,
			@film_market_no			integer,
			@film_market_desc		varchar(50),
			@complex_name			varchar(50),
			@pack_max				integer,
			@plan_max				integer,
			@start_date				datetime,
			@plan_start_date		datetime,
			@print_id				integer,
			@print_name				varchar(50),
			@scheduled_qty			integer,
			@nom_scheduled_qty		integer,
			@branch_code			char(2),
			@deliv_branch			char(2),
			@confirmed_qty			integer,
			@nom_confirmed_qty		integer,
			@print_medium			char(1),
			@three_d_type			integer

/*
 * Create temp table to summarise print complex information
 */

create table #campaign_print_schedule
(
	complex_id			integer			not null,
	film_market_no		integer			not null,
	film_market_desc	varchar(50) 	not null,
	complex_name		varchar(50) 	not null,
	pack_max			integer			not null,
	plan_max			integer			not null,
	start_date			datetime		null,
	print_id			integer			not null,
	print_name			varchar(50)		not null,
	scheduled_qty		integer			null,
	nom_scheduled_qty	integer			null,
	branch_code			char(2)			not null,
	deliv_branch		char(2)			not null,
	confirmed_qty		integer			null,
	nom_confirmed_qty	integer			null,
	print_medium		char(1)			null,
	three_d_type		integer			null
)

/*
 * Return the consolidated information 
 */

create table #campaign_complex
(
	complex_id		integer		not null
)

insert 	into #campaign_complex
select 	fpc.complex_id
from 	film_plan fp,
		film_plan_complex fpc
where 	fp.film_plan_id = fpc.film_plan_id 
and		fp.campaign_no = @campaign_no

insert 	into #campaign_complex
select 	complex_id
from 	film_campaign_complex
where 	campaign_no = @campaign_no 
and		complex_id <> null

-- added 26-9-01 by michael
insert 	into #campaign_complex
select 	distinct complex_id
from 	print_transactions
where 	campaign_no = @campaign_no 
and		cinema_qty <> 0


select 	@deliv_branch = delivery_branch
from 	film_campaign
where 	campaign_no = @campaign_no				 

declare 	prints_csr cursor static for
select 		print_id,
			print_medium,
			three_d_type
from 		film_campaign_prints
where 		campaign_no = @campaign_no
group by 	print_id,
			print_medium,
			three_d_type
order by 	print_id,
			print_medium,
			three_d_type
for			read only

/*
 * open cursor and collect information 
 */

open prints_csr
fetch prints_csr into @print_id, @print_medium, @three_d_type
while(@@fetch_status = 0)
begin

	declare 	campaign_complex_csr cursor static for 
	select 		complex_id 
	from 		#campaign_complex
	group by 	complex_id
	order by 	complex_id
	for 		read only

	open campaign_complex_csr
	fetch campaign_complex_csr into @complex_id
	while(@@fetch_status = 0)
	begin
	
		select 	@complex_name = c.complex_name,
				@film_market_no = c.film_market_no,
				@film_market_desc = fm.film_market_desc
		from 	complex c,
				film_market fm
		where 	c.complex_id = @complex_id 
		and		c.film_market_no = fm.film_market_no
		
		select 	@print_name = print_name
		from 	film_print
		where 	print_id = @print_id
		
		select 	@scheduled_qty = sum(cinema_qty),
				@nom_scheduled_qty = sum(cinema_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id 
		and		complex_id = @complex_id 
		and		campaign_no = @campaign_no 
		and		ptran_type = 'T' 
		and		ptran_status = 'S' 
		and		three_d_type = @three_d_type
		and		print_medium = @print_medium
		
		select 	@confirmed_qty = sum(cinema_qty),
				@nom_confirmed_qty = sum(cinema_nominal_qty)
		from 	print_transactions
		where 	campaign_no = @campaign_no 
		and		print_id = @print_id 
		and		complex_id = @complex_id 
		and		ptran_status = 'C'
		and		three_d_type = @three_d_type
		and		print_medium = @print_medium
		
		select 		@branch_code = branch_code
		from 		print_transactions
		where 		print_id = @print_id 
		and			complex_id = @complex_id
		and			three_d_type = @three_d_type
		and			print_medium = @print_medium
		group by 	branch_code
		
		select 	@start_date = min(spot.screening_date)
		from 	campaign_spot spot,
				campaign_package cp,
				print_package ppack,
				complex_digital_medium cdm,
				complex_three_d_xref ctd
		where 	spot.package_id = cp.package_id 
		and		cp.package_id = ppack.package_id
		and		ppack.print_id = @print_id 
		and		spot.complex_id = @complex_id 
		and		spot.campaign_no = @campaign_no
		and		cdm.complex_id = spot.complex_id
		and		cdm.print_medium = @print_medium
		and		ctd.complex_id = spot.complex_id
		and		ctd.three_d_type = @three_d_type
		
		select 	@plan_start_date = min(fpd.screening_date)
		from 	film_plan fp,
				film_plan_complex fpc,
				film_plan_dates fpd,
				print_package pp,
				complex_digital_medium cdm,
				complex_three_d_xref ctd
		where 	fp.film_plan_id = fpc.film_plan_id 
		and		fp.film_plan_id = fpd.film_plan_id 	
		and		fp.package_id = pp.package_id 
		and		fp.campaign_no = @campaign_no 
		and		fpc.complex_id = @complex_id 
		and		pp.print_id = @print_id
		and		cdm.complex_id = fpc.complex_id
		and		cdm.print_medium = @print_medium
		and		ctd.complex_id = spot.complex_id
		and		ctd.three_d_type = @three_d_type
		
		select @start_date = isnull(@start_date, @plan_start_date)
		
		if @plan_start_date < @start_date
		begin
		select @start_date = @plan_start_date
		end
		
		select 	@pack_max = max(temp_table.count) 
		from 	(select 	count(ppack.print_id) as count
				from 		campaign_spot spot,
							campaign_package cp,
							print_package ppack,
							complex_digital_medium cdm,
							complex_three_d_xref ctd
				where 		spot.package_id = cp.package_id 
				and			cp.package_id = ppack.package_id 
				and			ppack.print_id = @print_id 
				and			spot.complex_id = @complex_id 
				and			spot.campaign_no = @campaign_no
				and			cdm.complex_id = spot.complex_id
				and			cdm.print_medium = @print_medium
				and			ctd.complex_id = spot.complex_id
				and			ctd.three_d_type = @three_d_type
				group by 	spot.screening_date) as temp_table	
		
		select 	@plan_max = fpc.max_screens
		from 	film_plan fp,
				film_plan_complex fpc,
				print_package pp,
				complex_digital_medium cdm,
				complex_three_d_xref ctd
		where 	fp.film_plan_id = fpc.film_plan_id 
		and		fp.package_id = pp.package_id 
		and		fp.campaign_no = @campaign_no 
		and		fpc.complex_id = @complex_id
		and		pp.print_id = @print_id
		and		fpc.complex_id = cdm.complex_id
		and		cdm.print_medium = @print_medium
		and		ctd.complex_id = spot.complex_id
		and		ctd.three_d_type = @three_d_type
		
		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end

		insert into #campaign_print_schedule
		(
			complex_id,
			film_market_no,
			film_market_desc,
			complex_name,
			pack_max,
			plan_max,
			start_date,
			print_id,
			print_name,
			scheduled_qty,
			nom_scheduled_qty,
			branch_code,
			deliv_branch,
			confirmed_qty,
			nom_confirmed_qty,
			print_medium,
			three_d_type
		) values
		(
			@complex_id,
			@film_market_no,
			@film_market_desc,
			@complex_name,
			isnull(@pack_max,0),
			isnull(@plan_max,0),
			@start_date,
			@print_id,
			@print_name,
			@scheduled_qty,
			@nom_scheduled_qty,
			isnull(@branch_code,''),
			@deliv_branch,
			isnull(@confirmed_qty,0),
			isnull(@nom_confirmed_qty,0),
			@print_medium,
			@three_d_type
		)

		fetch campaign_complex_csr into @complex_id
	end	
	close campaign_complex_csr
	deallocate campaign_complex_csr

	fetch prints_csr into @print_id, @print_medium, @three_d_type
end

close prints_csr


select 	complex_id,
		film_market_no,
		film_market_desc,
		complex_name,
		pack_max,
		plan_max,
		start_date,
		print_id,
		print_name,
		scheduled_qty,
		nom_scheduled_qty,
		branch_code,
		deliv_branch,
		confirmed_qty,
		nom_confirmed_qty,
		print_medium,
		three_d_type
from #campaign_print_schedule

deallocate prints_csr
return 0


error:
	raiserror ( 'Error', 16, 1) 
	close prints_csr
	close campaign_complex_csr
	return -1
GO
