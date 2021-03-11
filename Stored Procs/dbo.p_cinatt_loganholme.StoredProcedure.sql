USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_loganholme]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_loganholme]
as

/* Populates film_cinatt_actuals table */

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @spot_csr_open			tinyint,
        @screen_csr_open        tinyint,
        @film_market_no			integer,
        @spot_id					integer,
        @complex_id				integer,
        @package_id				integer,
        @screening_date			datetime,
        @spot_status				char(1),
        @pack_code				char(1),
        @actual_attendance	     integer,
        @attendance				integer,
        @total_campaign_attendance integer,
        @movie_id					integer,
        @actual					char(1),
        @regional_indicator     char(1),
        @spot_count             integer,
        @max_attendance_date    datetime,
        @data_valid             char(1),
        @country_code            char(1),
        @cinatt_weighting       numeric(6,4),
         @campaign_no integer
        
set nocount on

CREATE TABLE #film_cinatt_actuals
(
    campaign_no         int         NOT NULL,
    screening_date      datetime    NOT NULL,
    attendance          int         NOT NULL,
    data_valid          char(1)     NOT NULL,
    complex_id          int         not null,
    actual              char(1)     not null,
    movie_id            int         not null
)

/* do not process if analysis not allowed */
/*if exists
        (select 1
         from   film_campaign
         where  campaign_no = @campaign_no
         and    attendance_analysis = 'Y')
begin
*/
    /*
     * Initialise Variables
     */
    
    select @actual_attendance = 0,
           @total_campaign_attendance = 0,
           @spot_csr_open = 0,
           @screen_csr_open = 0,
           @spot_count = 0,
           @data_valid = 'Y'

    select  @country_code = br.country_code
    from    film_campaign fc, branch br
    where   fc.branch_code = br.branch_code
    and     fc.campaign_no = @campaign_no


    select  @max_attendance_date = max(eds.required_load_date)
    from    external_data_load_status eds, external_data_providers edp
    where   eds.provider_id = edp.provider_id
    and     edp.country_code = @country_code
    and     eds.required_load_date not in (
                                            select  distinct eds.required_load_date
                                            from    external_data_load_status eds, external_data_providers edp
                                            where   eds.provider_id = edp.provider_id
                                            and     edp.country_code = @country_code
                                            and     eds.load_complete = 'N')

    begin transaction


/*
 * Declare Cursors
 */
     declare screening_csr cursor static for
      select distinct spot.screening_date
        from movie_history spot
       where spot.screening_date between '1-jul-2004' and '31-mar-2005'
       and  spot.complex_id = 659
    order by spot.screening_date
         for read only

         /*
         * Loop Screening dates - in order to populate table easier with screening_date as PK
         */
        open screening_csr
        select @screen_csr_open = 1
        fetch screening_csr into @screening_date
        while(@@fetch_status = 0)
        begin

		     declare spot_csr cursor static for
		      select movie_id
		        from movie_history
		       where screening_date = @screening_date and
		             complex_id = 659
            order by movie_id
		         for read only

            /*
   * Loop Spots
             */

            open spot_csr
            select @spot_csr_open = 1
            fetch spot_csr into @movie_id
            while(@@fetch_status = 0)
            begin
    
                /*
           * Get Certificate Details
                */

/*                select @movie_id = null
        
            	select @movie_id = mh.movie_id
                 from certificate_item ci,
                      certificate_group cg,
                      movie_history mh
                where ci.spot_reference = @spot_id and
                      ci.certificate_group = cg.certificate_group_id and
                      cg.certificate_group_id = mh.certificate_group
  */      
             	select @attendance = 0

        		exec @errorode = p_cinatt_get_movie_attendance_test   @screening_date,
        												      659,
        												      @movie_id,
        												      @attendance OUTPUT,
        												      @actual OUTPUT
    
        		if(@errorode = -1) /* -1 indicates that there was not a complete set of attendance data */
                begin
                    if @actual = 'M' /* special case for NZ - missing Regional data, still allow to be reported */
            			select @data_valid = 'M'
                    else
                        select @data_valid = 'N'
                end

                if @actual <> 'Y'
            		select @actual_attendance = convert(int,(@attendance * 1))
                else
            		select @actual_attendance = @attendance  

                select @spot_count = @spot_count + 1

            /* insert new estimate record */
            insert into #film_cinatt_actuals
            values(0, @screening_date, @actual_attendance, @data_valid, 659, @actual, @movie_id)
            if @@error <> 0
                goto error

        	    fetch spot_csr into @movie_id
            end /*while*/

            close spot_csr
            select @spot_csr_open = 0
			deallocate spot_csr

--            select @total_campaign_attendance = @total_campaign_attendance + @actual_attendance
            /* insert new estimate record */
/*            insert into #film_cinatt_actuals
            values(@campaign_no, @screening_date, @actual_attendance, @data_valid)
            if @@error <> 0
                goto error
*/
            /* reset variables */
            select  @actual_attendance = 0,
                    @data_valid = 'Y'
    
        fetch screening_csr into @screening_date
        end/*while*/


    commit transaction

    if(@spot_csr_open = 1)
    begin
        close spot_csr
        deallocate spot_csr
    end
    
    if(@screen_csr_open = 1)
    begin
        close screening_csr
        deallocate screening_csr
    end

/*end*/ /*if*/



/*
 * Return Success
 */
select screening_date, movie_id, complex_id, actual, sum(attendance) from #film_cinatt_actuals group by screening_date, movie_id, complex_id, actual
return 0

/*
 * Error Handler
 */

error:

rollback transaction

if(@spot_csr_open = 1)
begin
    close spot_csr
    deallocate spot_csr
end

if(@screen_csr_open = 1)
begin
    close screening_csr
    deallocate screening_csr
end

return -1
GO
