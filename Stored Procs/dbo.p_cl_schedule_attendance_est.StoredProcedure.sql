/****** Object:  StoredProcedure [dbo].[p_cl_schedule_attendance_est]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_schedule_attendance_est]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_schedule_attendance_est]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cl_schedule_attendance_est] @campaign_no	int
as

set nocount on                              

declare @errorode					integer,
        @spot_weeks			    integer,
        @plan_weeks		    	integer,
        @total_spots            integer,
        @schedule_cost		    money,
        @schedule_value		    money,
        @first_spot			    datetime,
        @last_spot			    datetime,
        @first_plan			    datetime,
        @last_plan		    	datetime,
        @extra_value			money,
        @extra_cost			    money,
        @standby_cost 		    money,
        @reach                  numeric(10,4),
        @frequency              numeric(10,4),
        @demographic_desc       varchar(120),
        @est_attendance         integer,
        @est_showings           integer,
        @error                     tinyint,
        @est_cinatt_calc_date   datetime,
        @data_valid             char(1),
        @disclaimer_1           varchar(255),
        @disclaimer_2           varchar(255)

                                           

select  @first_spot = min(screening_date),
        @last_spot = max(screening_date)	
from    cinelight_spot
where   campaign_no = @campaign_no and
        spot_status <> 'D' and
        spot_status <> 'C' and
        spot_status <> 'H' and
        screening_date <> null

select  @spot_weeks = count(distinct screening_date)
from    cinelight_spot spot
where   campaign_no = @campaign_no and
        spot_type <> 'M' and
        spot_type <> 'V' and
        screening_date <> null

select  @total_spots = count(spot_id)
from    cinelight_spot spot
where   campaign_no = @campaign_no and
        spot_status <> 'C' and
        spot_status <> 'H' and
        spot_status <> 'N' and
        spot_status <> 'U' and
        screening_date <> null
        
select  @schedule_cost = sum(charge_rate)
from    cinelight_spot
where   campaign_no = @campaign_no 

SELECT      @est_attendance = sum(attendance),
            @est_cinatt_calc_date = process_date,
            @est_showings = sum(showings)    
FROM        cinelight_attendance_estimates
where       campaign_no = @campaign_no
group by    process_date

select @data_valid = 'Y'
if exists (select 1 from cinelight_attendance_estimates where campaign_no = @campaign_no and data_valid = 'N')
    select @data_valid = 'N'
if exists (select 1 from cinelight_attendance_estimates where campaign_no = @campaign_no and data_valid = 'M')
    select @data_valid = 'M'  /* special case for NZ where there is missing regional data */


select @disclaimer_1 = 'Calculation not valid due to missing attendance data. Please refer to Film Campaign for details.'
select @disclaimer_2 = 'Please note the attendance figure does not include data for regional complexes as this data is not currently available.'

select 	fc.campaign_no as campaign_no,
		fc.product_desc as product_desc,
		fc.revision_no as revision_no,
		fc.campaign_status as campaign_status,
		fc.branch_code as branch_code,
		@schedule_cost as campaign_cost,                          
		@spot_weeks as spot_weeks,
		@first_spot as first_spot,
		@last_spot as last_spot,
		@total_spots as total_spots,
		agency.agency_name as booking_agency,
		agb.agency_name as billing_agency,
		client.client_name as client_name,
		country.gst_rate as gst_rate,
		@est_attendance as est_attendance,
		@est_showings as est_showings,
		@est_cinatt_calc_date as est_cinatt_calc_date,
		@data_valid as data_valid,
		@disclaimer_1 as cinatt_disclaimer_1,
		@disclaimer_2 as cinatt_disclaimer_2
  from film_campaign fc,
       agency,
       agency agb,
       client,
       branch,
       country
 where fc.campaign_no = @campaign_no and
       fc.client_id = client.client_id and
       fc.agency_id = agency.agency_id and
       fc.billing_agency = agb.agency_id and
       fc.branch_code = branch.branch_code and
       branch.country_code = country.country_code and
	   fc.campaign_no in (select campaign_no from cinelight_spot where campaign_no = @campaign_no)

return 0
GO
