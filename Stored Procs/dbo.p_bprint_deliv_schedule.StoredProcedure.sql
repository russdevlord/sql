/****** Object:  StoredProcedure [dbo].[p_bprint_deliv_schedule]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_bprint_deliv_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_bprint_deliv_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_bprint_deliv_schedule] @branch_scope tinyint,
                                    @branch_code  char(2)
as

/*
 * Declare Variables
 */

declare		@branch_name 		varchar(50),
			@campaign_no		integer,
			@last_campaign		integer,
			@product_desc		varchar(100),   
			@print_id			integer,   
			@print_name			varchar(50),
			@agency_deal		char(1),   
			@agency_name		varchar(50),   
			@client_name		varchar(50),   
			@branch_qty			integer,
			@screening_date		datetime,
			@spot_screening		datetime,
			@plan_screening		datetime,
			@branch_nominal_qty	integer,
			@print_medium		char(1),
			@three_d_type		integer



create table #bprint_sch
(	
	branch_name 		varchar(50)		null,
	campaign_no			integer			null,   
	product_desc		varchar(100)	null,   
	print_id			integer			null,   
	print_name			varchar(50)		null,   
	agency_deal			char(1)			null,   
	agency_name			varchar(50)		null,   
	client_name			varchar(50)		null,   
	branch_qty			integer			null,   
	branch_nominal_qty	integer			null,   
	screening_date		datetime		null,
	print_medium		char(1)			null,
	three_d_type		integer			null 
)

/*
 * Declare Cursor
 */

declare 	bprint_csr cursor static for 
select 		b.branch_name,
			pt.campaign_no,   
			pt.print_id,
			pt.print_medium,
			pt.three_d_type,   
			max(fp.print_name),
			sum(pt.branch_qty),
			sum(pt.branch_nominal_qty)
from 		print_transactions pt,
			film_print fp,    
			branch b
where 		pt.ptran_type = 'I' 
and			pt.ptran_status = 'S' 
and			( pt.branch_code = @branch_code 
or			@branch_scope = 1 ) 
and			pt.branch_code = b.branch_code 
and			pt.print_id = fp.print_id
group by 	b.branch_name,
			pt.campaign_no,   
			pt.print_id,
			pt.print_medium,
			pt.three_d_type
order by 	b.branch_name,
			pt.campaign_no,   
			pt.print_id,
			pt.print_medium,
			pt.three_d_type

/*
 * Initialise Variables
 */

select @last_campaign = -1

/*
 * Loop Campaign Print Transactions
 */

open bprint_csr
fetch bprint_csr into @branch_name,	@campaign_no, @print_id, @print_medium, @three_d_type, @print_name, @branch_qty, @branch_nominal_qty
while (@@fetch_status = 0)
begin

	/*
	 * Get Campaign Information
	 */
	
	if(@last_campaign <> @campaign_no)
	begin
		select 	@product_desc = fc.product_desc,
				@agency_deal = fc.agency_deal,
				@agency_name = a.agency_name,
				@client_name = c.client_name,
				@screening_date = fc.start_date
		from 	film_campaign fc,
				agency a,
				client c
		where 	fc.campaign_no = @campaign_no 
		and		fc.agency_id = a.agency_id 
		and		fc.client_id = c.client_id
	end
	
	select @last_campaign = @campaign_no
	
	/*
	* Get Screening Date
	*/
	
	select	@spot_screening = null,
			@plan_screening = null
	
	select 	@spot_screening = min(spot.screening_date)
	from 	campaign_spot spot,
			campaign_package cp,
			print_package pp,
			complex_digital_medium cdm,
			complex_three_d_type_xref ctd
	where 	spot.campaign_no = @campaign_no 
	and		spot.package_id = cp.package_id 
	and		cp.package_id = pp.package_id 
	and 	cdm.complex_id = spot.complex_id
	and		cdm.print_medium = @print_medium
	and 	ctd.complex_id = spot.complex_id
	and		ctd.three_d_type = @three_d_type
	and		pp.print_id = @print_id
	
	select 	@plan_screening = min(fpd.screening_date)
	from 	film_plan fp,
			film_plan_dates fpd,
			campaign_package cp,
			print_package pp,
			film_plan_complexes fpc,
			complex_digital_medium cmd,
			complex_three_d_type_xref ctd
	where 	fp.campaign_no = @campaign_no
	and		fp.film_plan_id = fpd.film_plan_id 
	and		fp.package_id = cp.package_id 
	and		cp.package_id = pp.package_id 
	and 	fp.film_plan_id = fpc.film_plan_id
	and		fpc.complex_id = cdm.complex_id
	and		cdm.print_medium = @print_medium
	and 	ctd.complex_id = spot.complex_id
	and		ctd.three_d_type = @three_d_type
	and		pp.print_id = @print_id


	
	if(@spot_screening is not null)
		select @screening_date = @spot_screening
	
	if(@plan_screening is not null)
	begin
		if(@spot_screening is not null)
		begin
			if(@plan_screening < @spot_screening)
			begin
				select @screening_date = @plan_screening
			end
		end
		else
		begin
			select @screening_date = @plan_screening
		end
	end
	
	/*
	 * Insert Row into Table
	 */

	insert into #bprint_sch (
		branch_name,
		campaign_no,
		product_desc,
		print_id,
		print_name,
		agency_deal,
		agency_name,
		client_name,
		branch_qty,
		screening_date,
		branch_nominal_qty,
		print_medium,
		three_d_type ) values (
		@branch_name,
		@campaign_no,
		@product_desc, 
		@print_id, 
		@print_name, 
		@agency_deal, 
		@agency_name, 
		@client_name, 
		@branch_qty, 
		@screening_date,
		@branch_nominal_qty,
		@print_medium,
		@three_d_type)
	
	/*
    * Fetch Next
    */
	
	fetch bprint_csr into @branch_name,	@campaign_no, @print_id, @print_medium, @three_d_type, @print_name, @branch_qty, @branch_nominal_qty
end
close bprint_csr
deallocate bprint_csr

/*
 * Return Dataset
 */

select * 
  from #bprint_sch

/*
 * Return Success
 */

return 0
GO
