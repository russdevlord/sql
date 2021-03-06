/****** Object:  StoredProcedure [dbo].[p_cl_prints_needed]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_prints_needed]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_prints_needed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cl_prints_needed] @campaign_no integer
as
set nocount on 
declare  @plan_qty	        	 integer,
	@error					 integer,
	@errorode					 integer

/*
 * Create a temp table to store all prints required by the campaign
 */

create table #prints_needed
(
	print_id			integer 		null,
	pack_count		    integer 		null,
	cinelight_id		integer 		null,
	screening_date      datetime		null
)

/*
 * Create a temp table to store summary of prints required by the campaign
 */

create table #total_prints_needed
(
	print_id			integer 		not null,
	pack_sum			integer 		not null,
	cinelight_id		integer		not null
)

/*
 * insert all prints needed by the campaign's schedule
 */

insert into #prints_needed (
			print_id,
			pack_count,				
			cinelight_id,
			screening_date )
  select 	ppack.print_id,
			count(ppack.print_id),
			spot.cinelight_id,
			spot.screening_date
	 from cinelight_spot spot,
			cinelight_package cp,
			cinelight_print_package ppack,
			cinelight_print,
			cinelight_print_medium
	where	spot.package_id = cp.package_id and
			cp.package_id = ppack.package_id and
			spot.campaign_no = @campaign_no and
			spot.screening_date is not null and
			cinelight_print.print_id = ppack.print_id and
			cinelight_print_medium.print_medium = cinelight_print.print_medium and
			cinelight_print_medium.cinelight_type_group = 'C' --stops prints being needed for plasma prints
group by 	spot.campaign_no,
			ppack.print_id,
			spot.screening_date,
			spot.cinelight_id

  select @error = @@error
  if ( @error !=0 )
  begin
	  goto error
  end	

insert into #total_prints_needed
		  (print_id,
			pack_sum,
			cinelight_id)
  select print_id,
			max(pack_count),
			cinelight_id
    from #prints_needed
group by print_id,
			cinelight_id

/*
 * Return results
 */

select 	print_id,
			sum(pack_sum)
from 		#total_prints_needed
group by print_id

return 0

error:
	raiserror ('Error Retrieving Cinelight Prints Required Information', 16, 1)
	close plan_prints_csr
	return -1
GO
