/****** Object:  StoredProcedure [dbo].[p_campaign_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[p_campaign_prints] 	@campaign_no 	integer,
								@shell_code		char(7),
								@print_id  		integer
as

declare 	@actual_qty       		integer,
        	@scheduled_qty_in 		integer,
        	@scheduled_qty_out 		integer,
			@nom_actual_qty       	integer,
        	@nom_scheduled_qty_in 	integer,
        	@nom_scheduled_qty_out 	integer,
			@error					integer,
			@complex_id				integer,
			@pack_max				integer,
			@plan_max				integer,
         	@start_date				datetime,
			@plan_start_date		datetime,
			@complex_name			varchar(50),
			@in_campaign			char(1),
			@complex_campaign		integer,
			@print_type				char(1),
			@film_market_no			integer,
			@film_market_code		char(3),
			@print_medium			char(1),
			@three_d_type			integer,
			@pack_nom_max			integer,
			@plan_nom_max			integer,
			@film					char(1)
	
/*
 * Execute Stored Procedures to summarise print complex information
 */

create table #complex_select
(
	complex_id			integer			null,
	print_id			integer			null,
	complex_name		varchar(50)		null,
	prop_prints			integer			null,
	plan_prints			integer			null,
	prop_nom_prints		integer			null,
	plan_nom_prints		integer			null,
	start_date			datetime		null,
	actual_qty			integer			null,
	scheduled_in		integer			null,
	scheduled_out		integer			null,
	nom_actual_qty		integer			null,
	nom_scheduled_in	integer			null,
	nom_scheduled_out	integer			null,
	in_campaign			char(1)			null,
	campaign_no			integer			null,
	film_market_no		integer			null,
	film_market_code	char(3)			null,
	three_d_type		int				null,
	print_medium		char(1)			null
)

create table #campaign_complex
(
	complex_id		integer		null,
	in_campaign		char(1)		null,
	campaign_no		integer		null
)

 
select 	@print_type = print_type
from 	film_print
where 	print_id = @print_id

insert 	into #campaign_complex
select 	fpc.complex_id,
		'Y',
		fp.campaign_no
from 	film_plan fp,
		film_plan_complex fpc
where 	fp.film_plan_id = fpc.film_plan_id 
and		fp.campaign_no = @campaign_no

insert 	into #campaign_complex
select 	complex_id,
		'Y',
		campaign_no
from 	film_campaign_complex
where 	campaign_no = @campaign_no 
and		complex_id not in (	select 	distinct complex_id 
							from 	#campaign_complex)

insert 	into #campaign_complex
select 	distinct complex_id,
		'N',
		campaign_no
from 	print_transactions
where 	(campaign_no = @campaign_no 
or 		@campaign_no is null ) 
and		print_id = @print_id 
and		cinema_qty > 0 
and		complex_id not in (	select 	distinct complex_id 
							from 	#campaign_complex)

insert 	into #campaign_complex
select 	distinct complex_id,
		'N',
		null
from 	film_shell_xref,
		film_shell_print
where 	film_shell_print.shell_code = film_shell_xref.shell_code 
and		film_shell_xref.shell_code = @shell_code 
and		@campaign_no is null 
and		print_id = @print_id 
and		complex_id not in (	select 	distinct complex_id 
							from 	#campaign_complex)
							
insert		into #campaign_complex						
select		distinct iffs.complex_id,
				'Y',
				spot.campaign_no
from 		inclusion_spot spot,
				print_package ppack,
				complex_digital_medium cdm,
				print_medium pm,
				film_print_three_d_xref fp,
				print_package_three_d pp3d,
				print_package_medium pppm,
				inclusion_cinetam_package iffp,
				inclusion_cinetam_settings iffs
where		spot.inclusion_id = iffp.inclusion_id
and			spot.inclusion_id = iffs.inclusion_id
and			iffp.package_id = ppack.package_id 
and			spot.campaign_no = @campaign_no 
and			ppack.print_id = @print_id
and			spot.screening_date is not null 
and			fp.print_id = ppack.print_id 
and			pm.print_medium = cdm.print_medium 
and			pppm.print_package_id = ppack.print_package_id 
and			pp3d.print_package_id = ppack.print_package_id 
and			pp3d.three_d_type = fp.three_d_type 
and			pppm.print_medium = cdm.print_medium 
and			spot.spot_type not in ('V', 'M', 'R') 
and			iffs.complex_id = cdm.complex_id
and			iffs.complex_id not in (	select 	distinct complex_id from 	#campaign_complex)
group by 	iffs.complex_id,
			spot.campaign_no

if @print_type = 'S' and not @campaign_no is null and not @shell_code is null 
begin
	insert 	into #campaign_complex
	select 	distinct complex_id,
			'S',
			null
	from 	complex
	where 	film_complex_status <> 'C' 
	and		complex_id not in (	select 	distinct complex_id 
								from 	#campaign_complex)
end

/*
 * Declare Cursor
 */

/*
declare 	campaign_complex_csr cursor static for 
select 		#campaign_complex.complex_id,
			in_campaign,
			campaign_no,
			print_medium,
			three_d_type
from 		#campaign_complex
			left outer join complex_digital_medium on #campaign_complex.complex_id = complex_digital_medium.complex_id
			left outer join complex_three_d_type_xref on #campaign_complex.complex_id = complex_three_d_type_xref.complex_id
group by 	#campaign_complex.complex_id,
			in_campaign,
			campaign_no,
			print_medium,
			three_d_type
order by 	#campaign_complex.complex_id,
			print_medium,
			three_d_type

*/

declare 	campaign_complex_csr cursor static for 
select 		#campaign_complex.complex_id,
				in_campaign,
				campaign_no,
				complex_digital_medium.print_medium,
				complex_three_d_type_xref.three_d_type
from 		#campaign_complex,
				complex_digital_medium  ,
				complex_three_d_type_xref ,
				film_print_medium_xref,
				film_print_three_d_xref
where		#campaign_complex.complex_id = complex_digital_medium.complex_id
and			#campaign_complex.complex_id = complex_three_d_type_xref.complex_id
and			film_print_medium_xref.print_id = @print_id
and			film_print_three_d_xref.print_id = @print_id
and			film_print_medium_xref.print_medium = complex_digital_medium.print_medium
and			film_print_three_d_xref.three_d_type = complex_three_d_type_xref.three_d_type
group by 	#campaign_complex.complex_id,
				in_campaign,
				campaign_no,
				complex_digital_medium.print_medium,
				complex_three_d_type_xref.three_d_type
order by 	#campaign_complex.complex_id,
				complex_digital_medium.print_medium,
				complex_three_d_type_xref.three_d_type

open campaign_complex_csr
fetch campaign_complex_csr into @complex_id, @in_campaign, @complex_campaign, @print_medium, @three_d_type
while(@@fetch_status = 0)
begin
	
	select 		@actual_qty = sum(cinema_qty),
					@nom_actual_qty = sum(cinema_nominal_qty)
	from 		print_transactions
	where 		print_id = @print_id 
	and			complex_id = @complex_id 
	and			((campaign_no = @complex_campaign 
	and			@shell_code is null) 
	or				(@complex_campaign is null 
	and			@shell_code is null 
	and			campaign_no is null) 
	or 			(@shell_code is not null 
	and 			campaign_no is null)) 
	and			ptran_status = 'C'
	and			three_d_type = @three_d_type
	and			print_medium = @print_medium

	select 		@scheduled_qty_in = sum(cinema_qty),
				@nom_scheduled_qty_in = sum(cinema_nominal_qty)
	from 		print_transactions
	where 		print_id = @print_id and
				complex_id = @complex_id 
	and			ptran_status = 'S' 
	and			((campaign_no = @complex_campaign 
	and			@shell_code is null) 
	or			(@complex_campaign is null 
	and			@shell_code is null 
	and			campaign_no is null) 
	or 			(@shell_code is not null 
	and			campaign_no is null)) 
	and			cinema_qty >= 0
	and			three_d_type = @three_d_type
	and			print_medium = @print_medium
	
	select 		@scheduled_qty_out = sum(cinema_qty),
				@nom_scheduled_qty_out = sum(cinema_nominal_qty)
	from 		print_transactions
	where 		print_id = @print_id 
	and			complex_id = @complex_id 
	and			ptran_status = 'S' 
	and			((campaign_no = @complex_campaign 
	and			@shell_code is null) 
	or			(@complex_campaign is null 
	and			@shell_code is null 
	and			campaign_no is null) 
	or 			(@shell_code is not null 
	and			campaign_no is null)) 
	and			cinema_qty < 0
	and			three_d_type = @three_d_type
	and			print_medium = @print_medium
	
	select 		@complex_name = complex.complex_name,
				@film_market_no = complex.film_market_no,
				@film_market_code = film_market.film_market_code
	from 		complex,
				film_market
	where 		complex_id = @complex_id 
	and			complex.film_market_no = film_market.film_market_no

	select 		@start_date = min(temp_table.screening_date)
	from		(select spot.screening_date
				from 		campaign_spot spot,
							campaign_package cp,
							print_package ppack,
							complex_digital_medium cdm,
							complex_three_d_type_xref ctd
				where 		spot.package_id = cp.package_id 
				and			cp.package_id = ppack.package_id 
				and			ppack.print_id = @print_id 
				and			spot.complex_id = @complex_id 
				and			spot.campaign_no = @complex_campaign
				and			spot.complex_id = cdm.complex_id
				and			cdm.print_medium = @print_medium
				and			ctd.complex_id = spot.complex_id
				and			ctd.three_d_type = @three_d_type
				union all
				select		spot.screening_date
				from 		inclusion_spot spot,
							print_package ppack,
							complex_digital_medium cdm,
							print_medium pm,
							film_print_three_d_xref fp,
							print_package_three_d pp3d,
							print_package_medium pppm,
							inclusion_cinetam_package iffp,
							inclusion_cinetam_settings iffs
				where		spot.inclusion_id = iffp.inclusion_id
				and			spot.inclusion_id = iffs.inclusion_id
				and			iffp.package_id = ppack.package_id 
				and			spot.campaign_no = @complex_campaign 
				and			ppack.print_id = @print_id
				and			iffs.complex_id = @complex_id
				and			spot.screening_date is not null 
				and			fp.print_id = ppack.print_id 
				and			pm.print_medium = cdm.print_medium 
				and			pppm.print_package_id = ppack.print_package_id 
				and			pp3d.print_package_id = ppack.print_package_id 
				and			pp3d.three_d_type = fp.three_d_type 
				and			pppm.print_medium = cdm.print_medium 
				and			pppm.print_medium = @print_medium
				and			pp3d.three_d_type = @three_d_type
				and			spot.spot_type not in ('V', 'M', 'R') 
				and			iffs.complex_id = cdm.complex_id) as temp_table
				
	select 		@plan_start_date = min(fpd.screening_date)
	from 		film_plan fp,
				film_plan_complex fpc,
				film_plan_dates fpd,
				print_package pp,
				complex_digital_medium cdm,
				complex_three_d_type_xref ctd
	where 		fp.film_plan_id = fpc.film_plan_id 
	and			fp.film_plan_id = fpd.film_plan_id 
	and			fp.package_id = pp.package_id 	
	and			fp.campaign_no = @complex_campaign 
	and			fpc.complex_id = @complex_id 
	and			pp.print_id = @print_id
	and			fpc.complex_id = cdm.complex_id
	and			cdm.print_medium = @print_medium
	and			ctd.complex_id = fpc.complex_id
	and			ctd.three_d_type = @three_d_type
	
	select @start_date = isnull(@start_date, @plan_start_date)
	
	if @plan_start_date < @start_date
	begin
	select @start_date = @plan_start_date
	end
	
	select 		@pack_max = max(temp_table.count) 
	from 		(select 	count(ppack.print_id) as count
				from 		campaign_spot spot,
							campaign_package cp,
							print_package ppack,
							complex_digital_medium cdm,
							complex_three_d_type_xref ctd
				where 		spot.package_id = cp.package_id 
				and			cp.package_id = ppack.package_id 
				and			ppack.print_id = @print_id 
				and			spot.complex_id = @complex_id 
				and			spot.campaign_no = @complex_campaign 
				and			spot.screening_date is not null
				and			spot.complex_id = cdm.complex_id
				and			cdm.print_medium = @print_medium
				and			ctd.complex_id = spot.complex_id
				and			ctd.three_d_type = @three_d_type
				and			spot.spot_type not in ('M','V','R')
				group by 	spot.screening_date
				union all
				select		count(ppack.print_id) as count
				from 		inclusion_spot spot,
							print_package ppack,
							complex_digital_medium cdm,
							print_medium pm,
							film_print_three_d_xref fp,
							print_package_three_d pp3d,
							print_package_medium pppm,
							inclusion_cinetam_package iffp,
							inclusion_cinetam_settings iffs
				where		spot.inclusion_id = iffp.inclusion_id
				and			spot.inclusion_id = iffs.inclusion_id
				and			iffp.package_id = ppack.package_id 
				and			spot.campaign_no = @complex_campaign 
				and			ppack.print_id = @print_id
				and			iffs.complex_id = @complex_id
				and			spot.screening_date is not null 
				and			fp.print_id = ppack.print_id 
				and			pm.print_medium = cdm.print_medium 
				and			pppm.print_package_id = ppack.print_package_id 
				and			pp3d.print_package_id = ppack.print_package_id 
				and			pp3d.three_d_type = fp.three_d_type 
				and			pppm.print_medium = cdm.print_medium 
				and			pppm.print_medium = @print_medium
				and			pp3d.three_d_type = @three_d_type
				and			spot.spot_type not in ('V', 'M', 'R') 
				and			iffs.complex_id = cdm.complex_id) as temp_table
	
	select 		@plan_max = fpc.max_screens
	from 		film_plan fp,
					film_plan_complex fpc,
					print_package pp,
					complex_digital_medium cdm,
					complex_three_d_type_xref ctd
	where 		fp.film_plan_id = fpc.film_plan_id 
	and			fp.package_id = pp.package_id 
	and			fp.campaign_no = @complex_campaign 
	and			fpc.complex_id = @complex_id 
	and			pp.print_id = @print_id
	and			fpc.complex_id = cdm.complex_id
	and			cdm.print_medium = @print_medium
	and			ctd.complex_id = fpc.complex_id
	and			ctd.three_d_type = @three_d_type
	
	select 		@plan_nom_max = @plan_max

	select 	@film = film
	from 	print_medium  
	where	print_medium.print_medium = @print_medium

	if @film = 'N'
	begin
		if @pack_max > 0 
			select 		@pack_max = 1

		if @plan_max > 0 
			select 		@plan_max = 1
	end

    if not (@three_d_type > 1 and @print_medium = 'F')
    begin
        insert into #complex_select
        (
        complex_id,
        print_id,
        complex_name,
        prop_prints,
        plan_prints,
        prop_nom_prints,
        plan_nom_prints,
        start_date,
        actual_qty,
        scheduled_in,
        scheduled_out,
        nom_actual_qty,
        nom_scheduled_in,
        nom_scheduled_out,
        in_campaign,
        campaign_no,
        film_market_no,
        film_market_code,
        print_medium, 
        three_d_type
        ) values
        (
        @complex_id,
        @print_id, 
        @complex_name,
        IsNull(@pack_max,0), 
        IsNull(@plan_max,0),
        IsNull(@pack_nom_max,0), 
        IsNull(@plan_nom_max,0),
        @start_date,
        IsNull(@actual_qty,0),
        IsNull(@scheduled_qty_in,0),
        IsNUll(@scheduled_qty_out,0),
        IsNull(@nom_actual_qty,0),
        IsNull(@nom_scheduled_qty_in,0),
        IsNUll(@nom_scheduled_qty_out,0),
        @in_campaign,
        @complex_campaign,
        @film_market_no,
        @film_market_code, 
        @print_medium, 
        @three_d_type
        )
	
        select @error = @@error
        if (@error !=0)
        begin
            goto error
        end
    end

	fetch campaign_complex_csr into @complex_id, @in_campaign, @complex_campaign, @print_medium, @three_d_type
end	

close campaign_complex_csr

select 		complex_id,
			print_id,
			complex_name,
			prop_prints,
			plan_prints,
			prop_nom_prints,
			plan_nom_prints,
			start_date,
			actual_qty,
			scheduled_in,
			scheduled_out, 
			in_campaign,
			campaign_no,
			film_market_no,
			film_market_code,
			print_medium, 
			three_d_type
from 		#complex_select 
where 		print_id = @print_id
order by 	film_market_no,
			complex_name
return 0

error:

	raiserror ('Error retrieving complex print transaction information' ,11,1)
	close campaign_complex_csr
	return -1
GO
