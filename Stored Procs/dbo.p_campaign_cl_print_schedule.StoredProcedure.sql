/****** Object:  StoredProcedure [dbo].[p_campaign_cl_print_schedule]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_cl_print_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_cl_print_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_cl_print_schedule] @campaign_no 	integer
as

declare 	@error					integer,
            @cinelight_id			integer,
			@film_market_no		    integer,
			@film_market_desc		varchar(50),
			@cinelight_desc			varchar(50),
			@pack_max				integer,
			@start_date				datetime,
			@print_id				integer,
			@print_name				varchar(50),
			@scheduled_qty			integer,
			@branch_code			char(2),
			@deliv_branch			char(2),
			@confirmed_qty			integer

/*
 * Create temp table to summarise print complex information
 */

create table #campaign_print_schedule
(
	cinelight_id			integer			not null,
	film_market_no		integer			not null,
	film_market_desc	varchar(50) 	not null,
	cinelight_desc		varchar(50) 	not null,
	pack_max				integer			not null,
	start_date			datetime			null,
	print_id				integer			not null,
	print_name			varchar(50)		not null,
	scheduled_qty		integer			null,
	branch_code			char(2)			not null,
	deliv_branch		char(2)			not null,
	confirmed_qty		integer			null
)

/*
 * Return the consolidated information 
 */

create table #campaign_cinelight
(
	cinelight_id		integer		not null,
	print_id			integer     not null
)



 insert into #campaign_cinelight
	select distinct cinelight_id,
					print_id
     from cinelight_print_transaction
	 where campaign_no = @campaign_no and
			 cinema_qty <> 0 and
			 cinelight_id <> null


  select @deliv_branch = delivery_branch
    from film_campaign
   where campaign_no = @campaign_no				 

 declare prints_csr cursor static for
  select print_id 
 	 from cinelight_campaign_print
   where campaign_no = @campaign_no
order by print_id
for read only

/*
 * open cursor and collect information 
 */

open prints_csr
fetch prints_csr into @print_id
while(@@fetch_status = 0)
begin

	declare campaign_cinelight_csr cursor static for 
	select cinelight_id 
    from #campaign_cinelight
	where print_id = @print_id
	order by cinelight_id
	for read only

	open campaign_cinelight_csr
	fetch campaign_cinelight_csr into @cinelight_id
	while(@@fetch_status = 0)
	begin
		
		select  @cinelight_desc = cl.cinelight_desc,
			    @film_market_no = c.film_market_no,
				@film_market_desc = fm.film_market_desc
		  from   cinelight cl,
                 complex c,
				 film_market fm
		 where   cl.cinelight_id = @cinelight_id and
                 cl.complex_id = c.complex_id and
				 c.film_market_no = fm.film_market_no

		select @print_name = print_name
		  from cinelight_print
		 where print_id = @print_id
		
		select @scheduled_qty = sum(cinema_qty)
		  from cinelight_print_transaction
		 where print_id = @print_id and
			   cinelight_id = @cinelight_id and
			    campaign_no = @campaign_no and
         	    ptran_type_code = 'T' and
		        ptran_status_code = 'S' 

		select @confirmed_qty = sum(cinema_qty)
		  from cinelight_print_transaction
		 where campaign_no = @campaign_no and
				 print_id = @print_id and
				 cinelight_id = @cinelight_id and
				 ptran_status_code = 'C'

		select @branch_code = branch_code
		from  cinelight_print_transaction
       	where print_id = @print_id and
			  cinelight_id = @cinelight_id and
			  campaign_no = @campaign_no
	 group by branch_code

		select @start_date = min(spot.screening_date)
		  from   cinelight_spot spot,
				 cinelight_package cp,
				 cinelight_print_package ppack
		 where spot.package_id = cp.package_id and
				 cp.package_id = ppack.package_id and
				 ppack.print_id = @print_id and
				 spot.cinelight_id = @cinelight_id and
				 spot.campaign_no = @campaign_no
		
				
		select @pack_max = max(temp_table.count) from (
	            select count(ppack.print_id) as count
	            from cinelight_spot spot,
				         cinelight_package cp,
				         cinelight_print_package ppack
		         where spot.package_id = cp.package_id and
				     cp.package_id = ppack.package_id and
				         ppack.print_id = @print_id and
				         spot.cinelight_id = @cinelight_id and
				         spot.campaign_no = @campaign_no
		        group by spot.screening_date) as temp_table	

		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end
	
		insert into #campaign_print_schedule
		(
			cinelight_id,
			film_market_no,
			film_market_desc,
			cinelight_desc,
			pack_max,
			start_date,
			print_id,
			print_name,
			scheduled_qty,
			branch_code,
			deliv_branch,
			confirmed_qty
		) values
		(
			@cinelight_id,
			@film_market_no,
			@film_market_desc,
			@cinelight_desc,
			isnull(@pack_max,0),
			@start_date,
			@print_id,
			@print_name,
			@scheduled_qty,
			isnull(@branch_code,''),
			@deliv_branch,
			isnull(@confirmed_qty,0)
		)

		fetch campaign_cinelight_csr into @cinelight_id
	end	
	close campaign_cinelight_csr
	deallocate campaign_cinelight_csr
	fetch prints_csr into @print_id
end

close prints_csr


  select    cinelight_id,
			film_market_no,
			film_market_desc,
			cinelight_desc,
			pack_max,
			start_date,
			print_id,
			print_name,
			scheduled_qty,
			branch_code,
			deliv_branch,
			confirmed_qty
    from #campaign_print_schedule

deallocate prints_csr
return 0

error:
	raiserror ('Error', 16, 1)
	close prints_csr
	close campaign_cinelight_csr
	return -1
GO
