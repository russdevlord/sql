/****** Object:  StoredProcedure [dbo].[p_schedule_attendance_est]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_attendance_est]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_attendance_est]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_schedule_attendance_est] @campaign_no	int
as

set nocount on                              

declare 	@errorode					integer,
			@spot_weeks				integer,
			@plan_weeks				integer,
			@total_spots        	integer,
			@schedule_cost			money,
			@schedule_value			money,
			@first_spot				datetime,
			@last_spot				datetime,
			@first_plan				datetime,
			@last_plan				datetime,
			@extra_value			money,
			@extra_cost				money,
			@standby_cost 			money,
			@reach            		numeric(10,4),
			@frequency        		numeric(10,4),
			@demographic_desc 		varchar(120),
			@est_attendance   		integer,
			@error               		tinyint,
			@est_cinatt_calc_date 	datetime,
			@data_valid       		char(1),
			@disclaimer_1     		varchar(255),
			@disclaimer_2     		varchar(255),
			@campaign_value			money,
			@campaign_cost			money,
			@cm_campaign_value		money,
			@cm_campaign_cost		money

                                           

select @first_spot = min(screening_date),
		 @last_spot = max(screening_date)	
  from campaign_spot
 where campaign_no = @campaign_no and
       spot_status <> 'D' and
       spot_status <> 'C' and
       spot_status <> 'H' and
       screening_date is not null

                                           

select @first_plan = min(fpd.screening_date),
		 @last_plan = max(fpd.screening_date)	
  from film_plan fp,
       film_plan_dates fpd
 where fp.campaign_no = @campaign_no and
		 fp.plan_status <> 'X' and
       fp.film_plan_id = fpd.film_plan_id

                                                   

select @spot_weeks = count(distinct screening_date)
  from campaign_spot spot
 where campaign_no = @campaign_no and
       spot_type <> 'M' and
       spot_type <> 'V' and
       screening_date is not null

select @plan_weeks = count(distinct fpd.screening_date)
  from film_plan fp,
       film_plan_dates fpd
 where fp.campaign_no = @campaign_no and
		 fp.plan_status <> 'X' and
       fp.film_plan_id = fpd.film_plan_id

select  @total_spots = count(spot_id)
  from campaign_spot spot
 where campaign_no = @campaign_no and
       spot_status <> 'C' and
       spot_status <> 'H' and
       spot_status <> 'N' and
       spot_status <> 'U' and
       screening_date is  not null

select @extra_value = sum(track_qty * track_unit_cost)
  from film_track
 where campaign_no = @campaign_no and
       include_value_cost = 'Y'

select @extra_value = isnull(@extra_value, 0)

select @extra_cost = sum(track_qty * track_charge)
  from film_track
 where campaign_no = @campaign_no and
       include_value_cost = 'Y'

select @extra_cost = isnull(@extra_cost, 0)
 
select 	@campaign_value = sum(rate),
		@campaign_cost = sum(charge_rate)
from 	campaign_spot 
where 	campaign_no = @campaign_no
and 	spot_status <> 'P'

select 	@cm_campaign_value = sum(rate),
		@cm_campaign_cost = sum(charge_rate)
from 	inclusion_spot ,
		inclusion
where 	inclusion_spot.campaign_no = @campaign_no
and		inclusion.inclusion_id = inclusion_spot.inclusion_id
and		(inclusion_type = 11
or		inclusion_type = 12)
and 	spot_status <> 'P'

select 	@campaign_value = isnull(@campaign_value,0) + isnull(@cm_campaign_value,0),
		@campaign_cost = isnull(@campaign_cost,0) + isnull(@cm_campaign_cost,0)                            

select @standby_cost = sum(maximum_spend)
  from film_plan
 where campaign_no = @campaign_no

select @standby_cost = isnull(@standby_cost, 0)

select  @reach = frf.reach,
        @frequency = frf.frequency,
        @demographic_desc = rfd.demographic_desc
from    film_reach_frequency frf, reach_frequency_demographics rfd
where   frf.campaign_no =  @campaign_no
and     frf.demographic_code = rfd.demographic_code

SELECT   @est_attendance = sum(attendance),
         @est_cinatt_calc_date = process_date
    FROM attendance_campaign_estimates
 where campaign_no = @campaign_no
  group by process_date

select @data_valid = 'Y'
if exists (select 1 from attendance_campaign_estimates where campaign_no = @campaign_no and data_valid = 'N')
    select @data_valid = 'N'
if exists (select 1 from attendance_campaign_estimates where campaign_no = @campaign_no and data_valid = 'M')
    select @data_valid = 'M'  /* special case for NZ where there is missing regional data */


select @disclaimer_1 = 'Calculation not valid due to missing attendance data. Please refer to Film Campaign for details.'
select @disclaimer_2 = 'Please note the attendance figure does not include data for regional complexes as this data is not currently available.'

select fc.campaign_no as campaign_no,
       fc.product_desc as product_desc,
       fc.revision_no as revision_no,
       fc.campaign_status as campaign_status,
       fc.branch_code as branch_code,
       @campaign_cost as campaign_cost,                          
       @campaign_value as campaign_value,                              
		 @standby_cost as standby_cost,
       @spot_weeks as spot_weeks,
       @plan_weeks as plan_weeks,
       @extra_cost as extra_cost,
       @extra_value as extra_value,
       @first_spot as first_spot,
       @last_spot as last_spot,
       @first_plan as first_plan,
       @last_plan as last_plan,
       @total_spots as total_spots,
       agency.agency_name as booking_agency,
       agb.agency_name as billing_agency,
       client.client_name as client_name,
       country.gst_rate as gst_rate,
        @reach as reach,
        @frequency as frequency,
        @demographic_desc as demographic_desc,
        @est_attendance as est_attendance,
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
       branch.country_code = country.country_code

return 0
GO
