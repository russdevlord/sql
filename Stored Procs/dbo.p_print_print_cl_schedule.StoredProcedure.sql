/****** Object:  StoredProcedure [dbo].[p_print_print_cl_schedule]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_print_cl_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_print_print_cl_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_print_print_cl_schedule] @print_id 	integer
as
set nocount on 
declare 	@error					integer,
            @cinelight_id		integer,
			@film_market_no		integer,
			@film_market_desc	varchar(50),
			@complex_name		varchar(50),
			@pack_max		integer,
			@start_date		datetime,
			@print_name		varchar(50),
			@scheduled_qty		integer,
			@branch_code		char(2),
			@deliv_branch		char(2),
			@confirmed_qty		integer,
            @cinelight_desc     varchar(50)

/*
 * Create temp table to summarise print cinelight information
 */

create table #campaign_print_schedule
(
	cinelight_id			integer			null,
	film_market_no		integer			null,
	film_market_desc	varchar(50) 	null,
	cinelight_desc		varchar(50) 	null,
	pack_max				integer		null,
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

create table #campaign_cinelight
(
	cinelight_id		integer		not null
)


insert into #campaign_cinelight
	select distinct cinelight_id
     from cinelight_print_transaction
	 where print_id = @print_id and
			 cinema_qty <> 0 and
			 cinelight_id <> null
			 
/*
 * open cursor and collect information 
 */

  declare campaign_cinelight_csr cursor static for 
  select cinelight_id 
  from #campaign_cinelight
  group by cinelight_id
  order by cinelight_id
  for read only

	open campaign_cinelight_csr
	fetch campaign_cinelight_csr into @cinelight_id
	while(@@fetch_status = 0)
	begin
		
		select  @cinelight_desc = cl.cinelight_desc,
				 @film_market_no = c.film_market_no,
				 @film_market_desc = fm.film_market_desc
		  from  cinelight cl,
                complex c,
				film_market fm
		 where  cl.cinelight_id = @cinelight_id and
                cl.complex_id = c.complex_id and
				c.film_market_no = fm.film_market_no

		select @print_name = print_name
		  from cinelight_print
		 where print_id = @print_id
		
		select @scheduled_qty = sum(cinema_qty)
		  from cinelight_print_transaction
		 where print_id = @print_id and
			   cinelight_id = @cinelight_id and
         	   ptran_type_code = 'T' and
		       ptran_status_code = 'S' 

		select @confirmed_qty = sum(cinema_qty)
		  from cinelight_print_transaction
		 where  print_id = @print_id and
				cinelight_id = @cinelight_id and
				 ptran_status_code = 'C'

		select @branch_code = branch_code
		from   cinelight_print_transaction
       where   print_id = @print_id and
			   cinelight_id = @cinelight_id
	 group by  branch_code

		select @start_date = min(spot.screening_date)
		  from cinelight_spot spot,
			   cinelight_package cp,
				cinelight_print_package ppack
		 where spot.package_id = cp.package_id and
				 cp.package_id = ppack.package_id and
				 ppack.print_id = @print_id and
				 spot.cinelight_id = @cinelight_id
		

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

return -1

error:
	raiserror ( 'p_print_print_cl_schedule', 16, 1) 
	deallocate campaign_cinelight_csr
	return -1
GO
