/****** Object:  StoredProcedure [dbo].[p_campaign_commencement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_commencement]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_commencement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_campaign_commencement] @start_date 		datetime,
											@end_date 			datetime,
											@country_code		char(1),
											@company            char(1)
as

declare @campaign_no							integer,
				@errorode   					integer,
				@complex_id						integer,
				@pack_max						integer,
				@complex_name   				varchar(50),
				@print_id						integer,
				@product_desc					varchar(100),
				@error							integer,
				@cinema_qty      				integer,
				@vm_qty          				integer,
				@requested_qty    				integer,
				@nom_cinema_qty	     			integer,
				@nom_vm_qty          			integer,
				@nom_requested_qty    			integer,
				@sched_start_date				datetime,
				@plan_start_date				datetime,
				@print_name		      			varchar(50),
				@duration						integer,
				@package_id						integer,
				@print_medium					char(1),
				@three_d_type					integer,
				@nominal_qty					integer,
				@business_unit_id		        integer,
				@product_category_desc			varchar(100),
				@sub_product_category_desc		varchar(100)

/*
 * create temp tables 
 */

create table #complex_select
(
	campaign_no						integer				null,
	product_desc					varchar(100)   		null,
	print_id						integer				null,
	print_name						varchar(50)			null,
	print_medium					char(1)				null,
	three_d_type					integer				null,
	duration						integer				null,
	start_date						datetime			null,
	requested_qty					integer				null,
	vm_qty							integer				null,
	cinema_qty						integer				null,	
	nom_requested_qty				integer				null,
	nom_vm_qty						integer				null,
	nom_cinema_qty					integer				null,
    business_unit_id				integer				null,
	product_category_desc			varchar(100)		null,
	sub_product_category_desc		varchar(100)		null
)

/*
 * Declare Cursor
 */

declare 	commence_csr cursor static for
select 		film_campaign.campaign_no,
			film_campaign.product_desc,
            film_campaign.business_unit_id
from 		film_campaign,
			branch
where		branch.branch_code = film_campaign.branch_code
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8)))
and			(campaign_no in (select 		campaign_no 
							from 			print_package,
							 				v_commencement_spots
							where			print_package.package_id = v_commencement_spots.package_id
							group by	 	campaign_no,
											print_id
							having			min(v_commencement_spots.screening_date) between @start_date and @end_date )
or			campaign_no in (select 			campaign_package.campaign_no 
							from 			campaign_package,
							 				v_commencement_spots
							where 			campaign_package.package_id = v_commencement_spots.package_id
							group by	 	campaign_package.campaign_no, 
											campaign_package.start_date
							having			campaign_package.start_date between @start_date and @end_date))
and			campaign_no in (select			campaign_no 
							from			v_commencement_spots, 
											complex, 
											branch 
							where			v_commencement_spots.complex_id = complex.complex_id 
							and				complex.branch_code = branch.branch_code 
							and				country_code = @country_code)							
order by 	film_campaign.campaign_no
for 		read only

/*
 * Loop through Cursors
 */

open commence_csr 
fetch commence_csr into @campaign_no, @product_desc, @business_unit_id
while (@@fetch_status = 0)
begin
	
	declare 	camp_prints_csr cursor static for 
	select 		print_id,
				requested_qty,
				nominal_qty, 
				print_medium,
				three_d_type
	from 		film_campaign_prints
	where 		campaign_no = @campaign_no
	and			(print_id in (	select 		print_id 
							 	from 		print_package,
							 				campaign_package,
							 				v_commencement_spots
								where 		v_commencement_spots.campaign_no = @campaign_no
								and			print_package.package_id = v_commencement_spots.package_id
								and			campaign_package.package_id = v_commencement_spots.package_id
								and			print_package.package_id = campaign_package.package_id
								group by 	print_id
								having		min(v_commencement_spots.screening_date) between @start_date and @end_date or min(campaign_package.start_date) between @start_date and @end_date)
	or				print_id in (select		substitution_print_id 
							 	from 		print_package,
							 				v_commencement_spots,
							 				film_campaign_print_substitution,
							 				campaign_package
								where 		v_commencement_spots.campaign_no = @campaign_no
								and			print_package.package_id = v_commencement_spots.package_id
								and			campaign_package.package_id = v_commencement_spots.package_id
								and			print_package.package_id = campaign_package.package_id
								and			film_campaign_print_substitution.print_package_id = print_package.print_package_id
								group by 	substitution_print_id
								having		min(v_commencement_spots.screening_date) between @start_date and @end_date or min(campaign_package.start_date) between @start_date and @end_date))
	and			print_medium in ('D')
	and			(three_d_type in (select 	three_d_type 
							 	from 		print_package,
							 				v_commencement_spots,
							 				print_package_three_d,
							 				campaign_package
								where 		v_commencement_spots.campaign_no = @campaign_no
								and			print_package.package_id = v_commencement_spots.package_id
								and			campaign_package.package_id = v_commencement_spots.package_id
								and			print_package.package_id = campaign_package.package_id
								and			print_package.print_package_id = print_package_three_d.print_package_id
								group by 	print_id, 
											three_d_type
								having		min(v_commencement_spots.screening_date) between @start_date and @end_date or min(campaign_package.start_date) between @start_date and @end_date)
	or			three_d_type in (select 	three_d_type 
							 	from 		print_package,
							 				v_commencement_spots,
							 				film_campaign_print_sub_threed,
							 				campaign_package
								where 		v_commencement_spots.campaign_no = @campaign_no
								and			print_package.package_id = v_commencement_spots.package_id
								and			campaign_package.package_id = v_commencement_spots.package_id
								and			print_package.package_id = campaign_package.package_id
								and			print_package.print_package_id = film_campaign_print_sub_threed.print_package_id
								group by 	print_id, 
											three_d_type
								having		min(v_commencement_spots.screening_date) between @start_date and @end_date or min(campaign_package.start_date) between @start_date and @end_date))								
	order by 	print_id
	for read only

	open camp_prints_csr
	fetch camp_prints_csr into @print_id, @requested_qty,@nominal_qty, @print_medium, @three_d_type
	while(@@fetch_status = 0)
	begin

		select 	@print_name = null,	
				@duration = null,
				@vm_qty = null,
				@cinema_qty = null,
				@nom_vm_qty = null,
				@nom_cinema_qty = null,
				@sched_start_date = null,
				@plan_start_date = null,
				@product_category_desc= null,
				@sub_product_category_desc = null

		select 	@vm_qty = sum(branch_qty),
				@nom_vm_qty = sum(branch_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id and
				ptran_status = 'C' and
				campaign_no = @campaign_no and
				print_medium = @print_medium and
				three_d_type = @three_d_type 
		
		select 	@cinema_qty = sum(cinema_qty),
				@nom_cinema_qty = sum(cinema_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id and
				ptran_status = 'C' and
				campaign_no = @campaign_no and
				print_medium = @print_medium and
				three_d_type = @three_d_type
		
		select 	@print_name = print_name,	
				@duration = duration	
		from 	film_print
		where 	print_id = @print_id
		
		select 	@sched_start_date = min(spot.screening_date)
		from 	v_commencement_spots spot,
				campaign_package cp,
				print_package ppack
		where 	spot.package_id = cp.package_id and
				cp.package_id = ppack.package_id and
				ppack.print_id = @print_id and
				spot.campaign_no = @campaign_no

		select	@product_category_desc = product_category_desc
		from 	v_commencement_spots spot,
				campaign_package cp,
				print_package ppack,
				product_category pc
		where 	spot.package_id = cp.package_id and
				cp.package_id = ppack.package_id and
				cp.product_category = pc.product_category_id and
				ppack.print_id = @print_id and
				spot.campaign_no = @campaign_no

		select	@sub_product_category_desc = product_subcategory_desc
		from 	v_commencement_spots spot,
				campaign_package cp,
				print_package ppack,
				product_subcategory pc
		where 	spot.package_id = cp.package_id and
				cp.package_id = ppack.package_id and
				cp.product_subcategory = pc.product_subcategory_id and
				ppack.print_id = @print_id and
				spot.campaign_no = @campaign_no
		
		select 	@plan_start_date = min(fpd.screening_date)
		from 	film_plan fp,
				film_plan_complex fpc,
				film_plan_dates fpd,
				print_package pp
				where fp.film_plan_id = fpc.film_plan_id and
				fp.film_plan_id = fpd.film_plan_id and	
				fp.package_id = pp.package_id and
				fp.campaign_no = @campaign_no and
				pp.print_id = @print_id
		
		select 	@sched_start_date = isnull(@sched_start_date, @plan_start_date)
		
		if @plan_start_date < @sched_start_date
		begin
		    select @sched_start_date = @plan_start_date
		end
		
		insert into #complex_select
		(campaign_no,
		product_desc,
		print_id,
		print_name,
		duration,
		start_date,
		requested_qty,
		vm_qty,
		cinema_qty,
		nom_requested_qty,
		nom_vm_qty,
		nom_cinema_qty,
		print_medium,
		three_d_type,
        business_unit_id,
		product_category_desc,
		sub_product_category_desc	
		) values
		(@campaign_no,
		@product_desc,
		@print_id, 
		@print_name,
		@duration,							
		@sched_start_date,
		IsNull(@requested_qty,0),
		IsNull(@vm_qty,0),
		IsNull(@cinema_qty,0),
		IsNull(@nominal_qty,0),
		IsNull(@nom_vm_qty,0),
		IsNull(@nom_cinema_qty,0),
		@print_medium,
		@three_d_type,
        @business_unit_id,
		@product_category_desc,
		@sub_product_category_desc
		)
		
		select @error = @@error
		if (@error !=0)
		begin
			raiserror ('Error retrieving campaign prints information', 16, 1)
			close camp_prints_csr
			deallocate camp_prints_csr
			return @error
		end
		
		fetch camp_prints_csr into @print_id, @requested_qty,@nominal_qty, @print_medium, @three_d_type
		end	
	close camp_prints_csr
	deallocate camp_prints_csr
	fetch commence_csr into @campaign_no, @product_desc, @business_unit_id
end

close commence_csr
deallocate commence_csr


/*
 * Return the consolidated information 
 */

select			campaign_no,
				product_desc,
				print_id,
				print_name,
				duration,
				start_date,
				sum(requested_qty) 'requested_qty',
				sum(vm_qty) 'vm_qty',
				sum(cinema_qty) 'cinema_qty',
				print_medium,
				three_d_type,
				business_unit_id,
				product_category_desc,
				sub_product_category_desc
from			#complex_select
group by		campaign_no,
				product_desc,
				print_id,
				print_name,
				duration,
				start_date,
				print_medium,
				three_d_type,
				business_unit_id,
				product_category_desc,
				sub_product_category_desc
order by		campaign_no asc
GO
