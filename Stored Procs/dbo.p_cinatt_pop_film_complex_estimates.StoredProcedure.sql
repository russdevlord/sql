/****** Object:  StoredProcedure [dbo].[p_cinatt_pop_film_complex_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_pop_film_complex_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_pop_film_complex_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_pop_film_complex_estimates] @campaign_no integer
as

/* Populates film_cinatt_estimates table */

/*
 * Declare Variables
 */

declare @error        					integer,
        @rowcount     					integer,
        @errorode							integer,
        @errno							integer,
        @spot_csr_open					tinyint,
        @screen_csr_open        		tinyint,
        @film_market_no					integer,
        @spot_id						integer,
        @complex_id						integer,
        @screening_date					datetime,
        @spot_status					char(1),
        @pack_code						char(1),
        @actual_attendance	    		integer,
        @attendance						integer,
        @total_campaign_attendance 		integer,
        @movie_id						integer,
        @actual							char(1),
        @regional_indicator     		char(1),
        @spot_count             		integer,
        @country_code           		char(1),
        @data_valid             		char(1),
        @cinatt_weighting       		numeric(6,4)


/*
 * Initialise Variables
 */

set nocount on

select @actual_attendance = 0,
       @total_campaign_attendance = 0,
       @spot_csr_open = 0,
       @screen_csr_open = 0,
       @spot_count = 0,
       @data_valid = 'Y'

begin transaction

delete  film_cinatt_estimates_cplx
where   campaign_no = @campaign_no
if @@error <> 0
    goto error

/*
 * Declare Cursors
 */

declare 	screening_csr cursor static for
select 		distinct spot.screening_date
from 		campaign_spot spot,
     		film_campaign fc
where 		fc.campaign_no = @campaign_no 
and  		fc.campaign_no = spot.campaign_no 
and			spot.spot_status != 'P'
and			spot.spot_type != 'M'
and			spot.spot_type != 'V'
and			spot.screening_date is not null
order by 	spot.screening_date
for 		read only

/*
 * Loop Screening dates - in order to populate table easier with screening_date as PK
 */
open screening_csr
select @screen_csr_open = 1
fetch screening_csr into @screening_date
while(@@fetch_status = 0)
begin

declare 		spot_csr cursor static for
select 			count(spot.spot_id),
				spot.complex_id,
				cplx.cinatt_weighting
from 			campaign_spot spot,
				complex cplx,
				film_campaign fc
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no  
and				spot.screening_date = @screening_date 
and				spot.complex_id = cplx.complex_id 
and				spot.spot_status != 'P'
and				spot.spot_type != 'M'
and				spot.spot_type != 'V'
group by 		spot.complex_id,
				cplx.cinatt_weighting
order by 		spot.complex_id
for 			read only

    /*
     * Loop Spots
     */
    open spot_csr
    select @spot_csr_open = 1
    fetch spot_csr into @spot_id,@complex_id,@cinatt_weighting
    while(@@fetch_status = 0)
    begin

       	select @attendance = 0

        select  @attendance = avg_per_movie
        from    cinema_attendance_by_complex
        where   screening_date = @screening_date
        and     complex_id = @complex_id

        if @@rowcount = 0 or @attendance = 0
        begin /* can't get avg for complex, so get average for country/region */
            select  @regional_indicator = complex_region_class.regional_indicator
            from    complex, complex_region_class
            where   complex.complex_id = @complex_id
            and     complex.complex_region_class = complex_region_class.complex_region_class

            select  @country_code = branch.country_code
            from    complex, branch
            where   complex.complex_id = @complex_id
            and     complex.branch_code = branch.branch_code    

            /* get region average */
            if @country_code = 'Z' -- special case for NZ, taking the average of all complexes
                select @attendance = avg(cinema_attendance_by_complex.avg_per_movie)
                from    branch,
                        complex,
                        cinema_attendance_by_complex
                where   branch.branch_code = complex.branch_code
                and     branch.country_code = @country_code
                and     cinema_attendance_by_complex.complex_id = complex.complex_id
                and     cinema_attendance_by_complex.screening_date = @screening_date
            else
                select @attendance = avg(cinema_attendance_by_complex.avg_per_movie)
                from    branch,
                        complex,
                        complex_region_class,
                        cinema_attendance_by_complex
                where   branch.branch_code = complex.branch_code
                and     branch.country_code = @country_code
                and     complex.complex_region_class = complex_region_class.complex_region_class
                and     complex_region_class.regional_indicator = @regional_indicator
                and     cinema_attendance_by_complex.complex_id = complex.complex_id
                and     cinema_attendance_by_complex.screening_date = @screening_date

            if @@rowcount = 0 or @attendance = null 
            begin
                /* if cinema_attendance_by_complex table has no data then there is no valid data for that date */
                /* Will allow missing NZ regional locations */
                if @country_code = 'Z'
                begin
                    if @regional_indicator = 'Y'
                        select  @attendance = 0,
                                @data_valid = 'M'
                    else
                        select  @attendance = 0,
                                @data_valid = 'N'                            
                
                end
                else
                begin
                    select  @attendance = 0,
                            @data_valid = 'N'
                end
            end
        end /*if*/

        if @data_valid <> 'Y'
    		select @actual_attendance = @actual_attendance + convert(int,(@attendance * @cinatt_weighting))
        else
    		select @actual_attendance = @actual_attendance + @attendance

		select  @actual_attendance = @actual_attendance * @spot_id                

	    insert into film_cinatt_estimates_cplx
	    values(@campaign_no, @screening_date, @complex_id, @actual_attendance,@data_valid)
	    if @@error <> 0
	        goto error
    
	    /* reset variables */
	    select  @actual_attendance = 0,
	            @data_valid = 'Y'

	    fetch spot_csr into @spot_id,@complex_id,@cinatt_weighting
    end /*while*/

    close spot_csr
	deallocate spot_csr
    select @spot_csr_open = 0
fetch screening_csr into @screening_date
end/*while*/

commit transaction


if(@screen_csr_open = 1)
begin
    close screening_csr
    deallocate screening_csr
end

/*
 * Return Success
 */

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
