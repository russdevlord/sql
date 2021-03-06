/****** Object:  StoredProcedure [dbo].[p_film_prop_figs_rpt_pack_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_prop_figs_rpt_pack_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_film_prop_figs_rpt_pack_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_prop_figs_rpt_pack_sub]		@campaign_no		integer

as

/*
 * Decalare Variables
 */

declare 	@error			integer,
		@pack_code		char(1),
		@pack_duration		smallint,
		@pack_prints		smallint,
		@pack_average_rate	money,
		@pack_spot_count	integer,
	         @package_id		integer,
		@package_desc		varchar(100)
		
/*
 * Create Temporary Table
 */

create table #results
(
	campaign_no			integer				null,
	pack_code			char(1)				null,
	pack_duration		smallint				null,
	pack_prints			smallint				null,
	average_rate		money					null,
	spot_count			integer				null,
	package_desc		varchar(100)		null
)


/*
 * Declare Cursors
 */

 declare package_csr cursor static for
  select pack.package_id
    from film_campaign fc, 
		   campaign_package pack,
		   branch br
   where fc.campaign_no = pack.campaign_no and
         fc.branch_code = br.branch_code and
		   fc.campaign_no = @campaign_no
group by pack.package_id
order by pack.package_id ASC
     for read only


/*
 * Loop Packages for Campaign
 */

open package_csr
fetch package_csr into @package_id 
while(@@fetch_status = 0)
begin

	select @pack_code = pack.package_code,
			 @pack_duration = pack.duration,
			 @pack_prints = pack.prints,	
			 @pack_average_rate = 0,
			 @pack_spot_count = 0,
			 @package_desc = package_desc
	  from campaign_package pack
	 where pack.package_id = @package_id


	select @pack_average_rate = avg(spot.charge_rate),
			 @pack_spot_count = count(spot.charge_rate)			    
	  from campaign_spot spot
	 where spot.campaign_no = @campaign_no and
			 spot.package_id = @package_id and
		  ( spot.spot_type = 'S' or
			 spot.spot_type = 'Y' )

	select @pack_average_rate = isnull(@pack_average_rate,0),
			 @pack_spot_count = isnull(@pack_spot_count,0)		

	/*
	 * Write to Table
	 */

	if(@pack_spot_count > 0)
		insert into #results (
				 campaign_no,
				 pack_code,
				 pack_duration,
				 pack_prints,
				 average_rate,
				 spot_count,
				 package_desc	 ) values (
				 @campaign_no,
				 @pack_code,
				 @pack_duration,
				 @pack_prints,
				 @pack_average_rate,
				 @pack_spot_count,
				 @package_desc )

	/*
	 * Fetch Next
	 */

	fetch package_csr into @package_id 

end
close package_csr
deallocate package_csr

/*
 * Return Results
 */
	 
select campaign_no,
		 pack_code,
		 pack_duration,
		 pack_prints,
		 average_rate,
		 spot_count,
		 package_desc
  from #results
					
/*
 * Return Success
 */

return 0
GO
