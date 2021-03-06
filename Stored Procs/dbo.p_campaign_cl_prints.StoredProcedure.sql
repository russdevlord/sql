/****** Object:  StoredProcedure [dbo].[p_campaign_cl_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_cl_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_cl_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_cl_prints] @campaign_no 	integer,
                                @print_id  		integer
as


declare 	@actual_qty       	integer,
        	@scheduled_qty_in 	integer,
        	@scheduled_qty_out 	integer,
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
			@film_market_no		integer,
			@film_market_code		char(3),
			@cinelight_id            integer,
			@cinelight_desc			varchar(255)

/*
 * Execute Stored Procedures to summarise print cinelights complex information
 */

create table #complex_select
(
	complex_id			integer			null,
	print_id				integer			null,
	complex_name		varchar(50)		null,
	prop_prints			integer			null,
	plan_prints			integer			null,
	start_date			datetime			null,
	actual_qty			integer			null,
	scheduled_in		integer			null,
	scheduled_out		integer			null,
	in_campaign			char(1)			null,
	campaign_no			integer			null,
	film_market_no		integer			null,
	film_market_code	char(3)			null,
	cinelight_id     	integer			null,
	cinelight_desc		varchar(255)	null
)

create table #campaign_complex
(
	complex_id		integer		null,
	cinelight_id    integer		null,
	in_campaign		char(1)		null,
	campaign_no		integer		null
)

 
select @print_type = print_type
  from cinelight_print
 where print_id = @print_id

insert into #campaign_complex
  select cl.complex_id,
  		 cl_complex.cinelight_id,
		'Y',
		cl_complex.campaign_no
   from cinelight_campaign_complex cl_complex, cinelight cl
   where cl_complex.campaign_no = @campaign_no and
         cl_complex.cinelight_id = cl.cinelight_id and 
			cl.complex_id not in (select distinct complex_id from #campaign_complex)

insert into #campaign_complex
   select distinct cl.complex_id,
   			cl_pt.cinelight_id,
			 'N',
			 cl_pt.campaign_no
	  from cinelight_print_transaction cl_pt, cinelight cl
	 where (cl_pt.campaign_no = @campaign_no or 
			  @campaign_no is null ) and
			  cl_pt.cinelight_id = cl.cinelight_id and
			 cl_pt.print_id = @print_id and
			 cl_pt.cinema_qty > 0 and
			 cl.complex_id not in (select distinct complex_id from #campaign_complex)


if @print_type = 'S' and not @campaign_no is null  
insert into #campaign_complex
   select distinct complex_id,
   			null,
			 'S',
			 null
	  from complex
	 where film_complex_status <> 'C' and
			 complex_id not in (select distinct complex_id from #campaign_complex)

/*
 * Declare Cursor
 */

declare campaign_complex_csr cursor static for 
  select complex_id,
  			cinelight_id,
			in_campaign,
			campaign_no
	 from #campaign_complex
order by complex_id

open campaign_complex_csr
fetch campaign_complex_csr into @complex_id, @cinelight_id, @in_campaign, @complex_campaign
while(@@fetch_status = 0)
begin
	
	select @actual_qty = sum(cinema_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 cinelight_id = @cinelight_id and
		    ((campaign_no = @complex_campaign) or
			 (@complex_campaign is null and
			  campaign_no is null) or 
			 ( campaign_no is null)) and
			 ptran_status_code = 'C'
	
	select @scheduled_qty_in = sum(cinema_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 cinelight_id = @cinelight_id and
			 ptran_status_code = 'S' and
		    ((campaign_no = @complex_campaign) or
			 (@complex_campaign is null and
			 campaign_no is null) or 
			 (campaign_no is null)) and
			 cinema_qty >= 0
	
	select @scheduled_qty_out = sum(cinema_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 cinelight_id= @cinelight_id and
			 ptran_status_code = 'S' and
		    ((campaign_no = @complex_campaign ) or
			 (@complex_campaign is null and
			 campaign_no is null)) and 
			 cinema_qty < 0
	
	select @complex_name = complex.complex_name,
			 @film_market_no = complex.film_market_no,
			 @film_market_code = film_market.film_market_code
	  from complex,
			 film_market
	 where complex_id = @complex_id and
			 complex.film_market_no = film_market.film_market_no
	
	select @start_date = min(spot.screening_date)
	  from 	cinelight_spot spot,
			cinelight_package cp,
			cinelight_print_package ppack
      where spot.package_id = cp.package_id and
			cp.package_id = ppack.package_id and
			ppack.print_id = @print_id and
            spot.cinelight_id = @cinelight_id and
			spot.campaign_no = @complex_campaign
	
			
select @pack_max = max(temp_table.count) from (
    select count(ppack.print_id) as count
	  from cinelight_spot spot,
			cinelight_package cp,
			 cinelight_print_package ppack
	 where spot.package_id = cp.package_id and
			 cp.package_id = ppack.package_id and
			 ppack.print_id = @print_id and
             spot.cinelight_id = @cinelight_id and
			 spot.campaign_no = @complex_campaign and
			 spot.screening_date is not null
	group by spot.screening_date) as temp_table

	select @cinelight_desc = cl.cinelight_desc
	from cinelight cl
	where cl.cinelight_id = @cinelight_id


insert into #complex_select
		   (complex_id,
			 print_id,
			 complex_name,
			 prop_prints,
			 plan_prints,
			 start_date,
			 actual_qty,
			 scheduled_in,
			 scheduled_out,
			 in_campaign,
			 campaign_no,
			 film_market_no,
			 film_market_code,
			 cinelight_id,
			 cinelight_desc

         ) values
		   (@complex_id,
			 @print_id, 
			 @complex_name,
			 IsNull(@pack_max,0), 
			 IsNull(@plan_max,0),
			 @start_date,
			 IsNull(@actual_qty,0),
			 IsNull(@scheduled_qty_in,0),
			 IsNUll(@scheduled_qty_out,0),
			 @in_campaign,
			 @complex_campaign,
			 @film_market_no,
			 @film_market_code,
			 @cinelight_id,
			 @cinelight_desc
		   )

	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	fetch campaign_complex_csr into @complex_id, @cinelight_id, @in_campaign, @complex_campaign
end	

close campaign_complex_csr

  select complex_id,
			print_id,
			complex_name,
			prop_prints,
			plan_prints,
			start_date,
			actual_qty,
			scheduled_in,
			scheduled_out, 
			in_campaign,
			campaign_no,
			film_market_no,
			film_market_code,
			cinelight_id,
			cinelight_desc
    from #complex_select 
   where print_id = @print_id

return 0

error:

	raiserror ('Error retrieving complex print transaction information' ,16,1)
	close campaign_complex_csr
	return -1
GO
