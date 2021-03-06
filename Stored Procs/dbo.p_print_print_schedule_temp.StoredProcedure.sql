/****** Object:  StoredProcedure [dbo].[p_print_print_schedule_temp]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_print_schedule_temp]
GO
/****** Object:  StoredProcedure [dbo].[p_print_print_schedule_temp]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_print_print_schedule_temp] @campaign_no 	integer
as
set nocount on 
declare 	@error					integer,
         @complex_id				integer,
			@film_market_no		integer,
			@film_market_desc	varchar(50),
			@complex_name		varchar(50),
			@pack_max		integer,
			@plan_max		integer,
			@start_date		datetime,
			@plan_start_date	datetime,
			@print_id		integer,
			@print_name		varchar(50),
			@scheduled_qty		integer,
			@branch_code		char(2),
			@deliv_branch		char(2),
			@confirmed_qty		integer

/*
 * Create temp table to summarise print complex information
 */

create table #campaign_print_schedule
(
	complex_id			integer			null,
	film_market_no		integer			null,
	film_market_desc	varchar(50) 	null,
	complex_name		varchar(50) 	null,
	pack_max				integer		null,
	plan_max				integer		null,
	start_date			datetime		null,
	print_id				integer		null,
	print_name			varchar(50)		null,
	scheduled_qty		integer			null,
	branch_code			char(2)			null,
	deliv_branch		char(2)			null,
	confirmed_qty		integer			null
)

/*
 * Return the consolidated information 
 */

create table #campaign_complex
(
	complex_id		integer		not null
)



-- added 26-9-01 by michael
 insert into #campaign_complex
	select distinct complex_id
     from print_transactions
	 where print_id = @campaign_no and
			 cinema_qty <> 0



/*
 * open cursor and collect information 
 */

 declare prints_csr cursor static for
  select print_id 
 	 from film_print
   where print_id = @campaign_no
order by print_id
for read only

open prints_csr
fetch prints_csr into @print_id
while(@@fetch_status = 0)
begin
	declare 	campaign_complex_csr cursor static for 
	  select complex_id 
		 from #campaign_complex
	group by complex_id
	order by complex_id
	for read only

	open campaign_complex_csr
	fetch campaign_complex_csr into @complex_id
	while(@@fetch_status = 0)
	begin
		
		select @complex_name = c.complex_name,
				 @film_market_no = c.film_market_no,
				 @film_market_desc = fm.film_market_desc
		  from complex c,
				 film_market fm
		 where c.complex_id = @complex_id and
				 c.film_market_no = fm.film_market_no

		select @print_name = print_name
		  from film_print
		 where print_id = @print_id
		
		select @scheduled_qty = sum(cinema_qty)
		  from print_transactions
		 where print_id = @print_id and
				 complex_id = @complex_id and
--				 campaign_no = @campaign_no and
         	 ptran_type = 'T' and
		       ptran_status = 'S' 

		select @confirmed_qty = sum(cinema_qty)
		  from print_transactions
		 where --campaign_no = @campaign_no and
				 print_id = @print_id and
				 complex_id = @complex_id and
				 ptran_status = 'C'

		select @branch_code = branch_code
		  from print_transactions
       where print_id = @print_id and
				 complex_id = @complex_id
	 group by branch_code

		select @start_date = min(spot.screening_date)
		  from campaign_spot spot,
				 campaign_package cp,
				 print_package ppack
		 where spot.package_id = cp.package_id and
				 cp.package_id = ppack.package_id and
				 ppack.print_id = @print_id and
				 spot.complex_id = @complex_id and
				 spot.campaign_no = @campaign_no
		
		select @plan_start_date = min(fpd.screening_date)
		  from film_plan fp,
				 film_plan_complex fpc,
				 film_plan_dates fpd,
				 print_package pp
		 where fp.film_plan_id = fpc.film_plan_id and
				 fp.film_plan_id = fpd.film_plan_id and	
				 fp.package_id = pp.package_id and
				 fp.campaign_no = @campaign_no and
				 fpc.complex_id = @complex_id and
				 pp.print_id = @print_id
		
		select @start_date = isnull(@start_date, @plan_start_date)
	
		if @plan_start_date < @start_date
		begin
			select @start_date = @plan_start_date
		end

--		SYBASE version	
-- 		select @pack_max = max(count(ppack.print_id))
-- 		  from campaign_spot spot,
-- 				 campaign_package cp,
-- 				 print_package ppack
-- 		 where spot.package_id = cp.package_id and
-- 				 cp.package_id = ppack.package_id and
-- 				 ppack.print_id = @print_id and
-- 				 spot.complex_id = @complex_id and
-- 				 spot.campaign_no = @campaign_no
-- 		group by spot.screening_date

--		MS SQL Version
/*		select @pack_max = max(temp_table.count) 
		from	(select count(spot.screening_date) as count
		 	 from	campaign_spot spot,
			 	campaign_package cp,
				print_package ppack
		 	where	spot.package_id = cp.package_id and
				cp.package_id = ppack.package_id and
				ppack.print_id = @print_id and
				spot.complex_id = @complex_id and
				spot.campaign_no = @campaign_no
			group by spot.screening_date) as temp_table
				

				
		select @plan_max = fpc.max_screens
		  from film_plan fp,
				 film_plan_complex fpc,
				 print_package pp
		 where fp.film_plan_id = fpc.film_plan_id and
				 fp.package_id = pp.package_id and
				 fp.campaign_no = @campaign_no and
				 fpc.complex_id = @complex_id and
				 pp.print_id = @print_id
	
		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end
*/	
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
			branch_code,
			deliv_branch,
			confirmed_qty
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
			isnull(@branch_code,''),
			@deliv_branch,
			isnull(@confirmed_qty,0)
		)

		fetch campaign_complex_csr into @complex_id
	end	
	close campaign_complex_csr
	deallocate campaign_complex_csr
	fetch prints_csr into @print_id
end

close prints_csr
deallocate prints_csr


  select complex_id,
			film_market_no,
			film_market_desc,
			complex_name,
			pack_max,
			plan_max,
			start_date,
			print_id,
			print_name,
			scheduled_qty,
			branch_code,
			deliv_branch,
			confirmed_qty
    from #campaign_print_schedule

return -1

error:
	raiserror ( 'p_print_print_schedule_temp', 16, 1) 
	deallocate prints_csr
	deallocate campaign_complex_csr
	return -1
GO
