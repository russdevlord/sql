/****** Object:  StoredProcedure [dbo].[p_check_premium]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_premium]
GO
/****** Object:  StoredProcedure [dbo].[p_check_premium]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_premium] @campaign_no integer
as

declare @error							integer,
		@spot_csr_open					tinyint,
		@screening_date					datetime,
		@screening_trailers				char(1),
		@spot_count						integer,
		@premium_count					smallint,
		@campaign_premium_count			smallint,
		@premium_limit					smallint,
		@row_type						char(10),
		@package_code					char(4),
		@complex_id 					integer,
		@package_id 					integer

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #premium
(
	screening_date		datetime,
	complex_id			integer,
   	package_id			integer,
	row_type			char(10),
   	spot_count			integer
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0



/*
 * Declare Cursors
 */ 

declare 	spot_csr cursor static for
select 		count(spot.spot_id),
			spot.complex_id,
			spot.screening_date,
			pack.screening_trailers,
			'Screening',
			pack.package_id
from 		campaign_spot spot,
			campaign_package pack
where 		spot.campaign_no = @campaign_no and
			spot.package_id = pack.package_id 
group by 	spot.complex_id,
			spot.screening_date,
			pack.screening_trailers,
			pack.package_id
union all
select 		count(spot.spot_id),
			spot.complex_id,
			spot.billing_date,
			pack.screening_trailers,
			'Billing',
			pack.package_id
from 		campaign_spot spot,
			campaign_package pack
where 		spot.campaign_no = @campaign_no and
			spot.package_id = pack.package_id 
group by 	spot.complex_id,
			spot.billing_date,
			pack.screening_trailers,
			pack.package_id
for 		read only


/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into @spot_count, 
				  	@complex_id, 
				  	@screening_date, 
				  	@screening_trailers,
				  	@row_type,
					@package_id

while(@@fetch_status=0)
begin

	/*
	 * Get Package Code to Count Packages less than this one
	 */
	
	select @package_code = package_code
	  from campaign_package
	 where package_id = @package_id

	if @screening_trailers = 'F' or @screening_trailers = 'B'
	begin

		/*
		 * Get premium Limit for Complex and Screening Date
		 */
	
		  select @premium_limit = movie_target / 2
			 from complex_date
			where complex_id = @complex_id and
					screening_date = @screening_date
		 
		/*
		 * Get Count of Booked Premium Spots
		 */
	
		  select @premium_count = IsNull(count(pack.package_id),0)
			 from campaign_spot spot,
					campaign_package pack
			where spot.complex_id = @complex_id and
					spot.screening_date = @screening_date and
					spot.spot_status <> 'P' and
					spot.campaign_no <> @campaign_no and
					spot.package_id = pack.package_id and
					(pack.screening_trailers = 'B' or 
					pack.screening_trailers = 'F')
	
		/*
		 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
		 * With a Package Code less than the package being checked.
		 */
	
		 select @campaign_premium_count = isnull(count(pack.package_id),0)
			from campaign_spot spot,
				  campaign_package pack
		  where spot.complex_id = @complex_id and
					spot.screening_date = @screening_date and
					spot.campaign_no = @campaign_no and
					spot.package_id = pack.package_id and
					pack.package_code < @package_code and				
					(pack.screening_trailers = 'B' or 
					pack.screening_trailers = 'F')	
		 
		select @premium_limit = @premium_limit - (@premium_count + @campaign_premium_count)
	
		if(@premium_limit < 0)
			select @premium_limit = 0
	
		select @premium_limit = @premium_limit - @spot_count
	
		/*
		 * Check if this spot is Affected
		 */
	
		if(@premium_limit < 0)
		begin
	
			if(@row_type = 'Screening')
				select @premium_limit = @premium_limit * -1
			else
				select @premium_limit = 0
	
			insert into #premium values (@screening_date, @complex_id, @package_id, @row_type, @premium_limit)
	
		end

	end
	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @spot_count, 
						@complex_id, 
						@screening_date, 
					  	@screening_trailers,
					  	@row_type,
						@package_id

end

close spot_csr
deallocate spot_csr

/*
 * Return premium List
 */

select 		screening_date,
			complex_id,
			package_id,
			row_type,
			spot_count
from 		#premium
order by 	screening_date asc,
			complex_id asc,
			package_id asc

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	if (@spot_csr_open = 1)
   begin
		close spot_csr
		deallocate spot_csr
	end
	return -1
GO
