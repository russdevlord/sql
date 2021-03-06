/****** Object:  StoredProcedure [dbo].[p_cinatt_package_evaluation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_package_evaluation]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_package_evaluation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_package_evaluation] @min_date datetime, @max_date datetime,
                                        @min_duration smallint, @max_duration smallint
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @spot_csr_open			tinyint,
        @campaign_csr_open		tinyint,
        @film_market_no			integer,
        @spot_id					integer,
        @complex_id				integer,
        @complex_id_store		integer,
        @package_id				integer,
        @screening_date			datetime,
        @spot_status				char(1),
        @pack_code				char(1),
        @charge_rate				money,
        @start						tinyint,
	     @actual_attendance		integer,
        @estimated_attendance	integer,
	     @location_cost			money,
	     @cancelled_cost			money,
        @attendance				integer,
        @movie_id					integer,
        @actual					char(1),
        @duration               smallint,
        @campaign_no            integer

/*
 * Create Temporary Tables
 */

create table #results
(	campaign_no               integer           null,
    package_duration           smallint         null,
    film_market_no				integer			null,
    complex_id					integer			null,
	complex_name				varchar(50)		null,
	actual_attendance			integer			null,
    estimated_attendance		integer			null,
	location_cost				money			null,
	cancelled_cost				money			null)



/*
 * Initialise Cursor Flags
 */

select  @spot_csr_open = 0,
        @campaign_csr_open = 0

/*
 * Initialise Variables
 */

select @start = 0,
       @complex_id_store = 0,
	    @actual_attendance = 0,
       @estimated_attendance = 0,
	    @location_cost = 0,
	    @cancelled_cost = 0,
        @duration = 0


/*
 * Declare Cursor
 */

 declare campaign_csr cursor static for
 select film_campaign.campaign_no,
        cpack.package_id,
        cpack.duration
   from film_campaign,
        branch,
        campaign_package cpack
 where film_campaign.branch_code = branch.branch_code and
       film_campaign.campaign_no = cpack.campaign_no and
       cpack.duration >= @min_duration and
       cpack.duration <= @max_duration and
       film_campaign.campaign_status <> 'P' and
       film_campaign.campaign_type = 0 and
       film_campaign.branch_code <> 'Z' and
       film_campaign.campaign_no in (select distinct campaign_no
                                     from campaign_spot
                                     group by campaign_no
                                     having max(screening_date) <= @max_date and
                                     min(screening_date) >= @min_date)
order by film_campaign.campaign_no
for read only


 
/*
 * Loop campaigns
 */
open campaign_csr
select @campaign_csr_open = 1
fetch campaign_csr into @campaign_no, @package_id, @duration
while(@@fetch_status = 0)
begin

    /*
     * Loop Spots
     */

	declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.complex_id,
	         spot.package_id,
	         spot.screening_date,
	         spot.spot_status,
	         spot.charge_rate
	    from campaign_spot spot,
	         campaign_package cpack,
	         complex cplx
	   where spot.campaign_no = @campaign_no and
	         cpack.package_id = @package_id and
	         spot.complex_id = cplx.complex_id and
	         spot.package_id = cpack.package_id and
	         spot.spot_status <> 'P'
	order by spot.complex_id,
	         spot_id
	     for read only

    open spot_csr
    select @spot_csr_open = 1
    fetch spot_csr into @spot_id,@complex_id,@package_id,@screening_date,@spot_status,@charge_rate
    while(@@fetch_status = 0)
    begin

/*    select @spot_id,@complex_id,@package_id,@screening_date,@spot_status,@charge_rate */

   	   /*
        * Insert and Reset Variables
        */

	if(@complex_id <> @complex_id_store and @start = 1)
	begin

		insert into #results (
	                campaign_no,
                    package_duration,
                    film_market_no,
                    complex_id,
                	complex_name,
                	actual_attendance,
                    estimated_attendance,
                    location_cost,
                    cancelled_cost)
      select        @campaign_no,
                    @duration,
                    film_market_no,
    	            complex_id,
    	            complex_name,
    	            @actual_attendance,
                    @estimated_attendance,
	                @location_cost,
	                @cancelled_cost
        from complex
       where complex_id = @complex_id_store

		select @actual_attendance = 0,
				 @estimated_attendance = 0,
				 @location_cost = 0,
				 @cancelled_cost = 0

	end

	select @start = 1,
	       @complex_id_store = @complex_id,
          @movie_id = null

       	/*
        * Get Certificate Details
        */
        select @movie_id = null
    	select @movie_id = mh.movie_id
         from certificate_item ci,
              certificate_group cg,
              movie_history mh
        where ci.spot_reference = @spot_id and
              ci.certificate_group = cg.certificate_group_id and
              cg.certificate_group_id = mh.certificate_group

    	select @errno = @@error
    	if (@errno != 0)
    		goto error

    	/*
        * Work Out Cost
        */

    	if(@spot_status = 'C' or @spot_status = 'H')
    		select @cancelled_cost = @cancelled_cost + @charge_rate
    	else
    		select @location_cost = @location_cost + @charge_rate


    	/*
    	 * Call Attendance Procedure
    	 */

    	select @attendance = 0

    	if(@screening_date is not null)
    	begin

    		exec @errorode = p_cinatt_get_movie_attendance @screening_date,
    																  @complex_id,
    																  @movie_id,
    																  @attendance OUTPUT,
    																  @actual OUTPUT

    		if(@errorode !=0)
    		begin
    			goto error
    		end
    /*
    select @screening_date, @complex_id, @movie_id, @attendance , @actual
    */
    		if(@actual = 'Y')
    			select @actual_attendance = @actual_attendance + @attendance
    		else
    			select @estimated_attendance = @estimated_attendance + @attendance

    	end

    	/*
    	 * Fetch Next
    	 */

    	fetch spot_csr into @spot_id,@complex_id,@package_id,@screening_date,@spot_status,@charge_rate

    end
    close spot_csr
    select @spot_csr_open = 0
	deallocate spot_csr

fetch campaign_csr into @campaign_no, @package_id, @duration
end

close campaign_csr
select @campaign_csr_open = 0

deallocate campaign_csr

/*
 * Insert remaining Data
 */

if(@start = 1)
begin
		insert into #results (
	                campaign_no,
                    package_duration,
                    film_market_no,
                    complex_id,
                	complex_name,
                	actual_attendance,
                    estimated_attendance,
                    location_cost,
                    cancelled_cost)
      select        @campaign_no,
                    @duration,
                    film_market_no,
    	            complex_id,
    	            complex_name,
    	            @actual_attendance,
                    @estimated_attendance,
	                @location_cost,
	                @cancelled_cost
        from complex
       where complex_id = @complex_id_store

	select @errno = @@error
	if (@errno != 0)
		goto error

end

/*
 * Return Dataset
 */

select 	campaign_no,
        package_duration ,
        film_market_no	,
        complex_id		,
	    complex_name	,
	    sum(actual_attendance),
        sum(estimated_attendance),
        sum(location_cost),
        sum(cancelled_cost)
  from #results
  group by campaign_no,
           package_duration,
           film_market_no	,
           complex_id		,
	       complex_name
 order by campaign_no

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	 if(@spot_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
	 end

	 if(@campaign_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
	 end


	 return -1
GO
