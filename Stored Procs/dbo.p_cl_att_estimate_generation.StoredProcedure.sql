/****** Object:  StoredProcedure [dbo].[p_cl_att_estimate_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_att_estimate_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_att_estimate_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cl_att_estimate_generation] @campaign_no integer
as

/* Populates film_cinatt_estimates table */

/*
 * Declare Variables
 */

declare @error        				integer,
		@employee_id				integer

/*
 * Begin Transaction
 */

begin transaction

select 		@employee_id = employee_id
from		employee
where		login_id = CURRENT_USER

if @@rowcount != 1
	select @employee_id = 193

/*
 * Delete Previous Record if there are any
 */

delete  cinelight_attendance_estimates
where   campaign_no = @campaign_no

select @error = @@error
if @error <> 0
    goto error

delete  cinelight_attendance_digilite_estimates
where   campaign_no = @campaign_no

select @error = @@error
if @error <> 0
    goto error

/*
 * Insert Valid Rows
 */

insert into 	cinelight_attendance_estimates	
(				campaign_no,
				screening_date,
				employee_id,
				process_date,
				attendance,
                showings,
				data_valid)
select			spot.campaign_no,
				spot.screening_date,
				@employee_id,
				getdate(),
				sum(attendance),
                count(spot_id) * 1960,
				'Y'
from 			cinelight_spot spot,
	     		film_campaign fc,
				cinelight c,
				cinelight_attendance_history cah
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no
and				(( fc.campaign_status = 'P' and
				spot.spot_status = 'P' ) or 
				( fc.campaign_status <> 'P' and
				spot.spot_status = 'X' or spot.spot_status = 'A'))
and				spot.cinelight_id = c.cinelight_id
and				cah.screening_date = dbo.f_prev_attendance_screening_date(spot.screening_date)
and				cah.cinelight_id = spot.cinelight_id
and				cah.cinelight_id = c.cinelight_id
group by 		spot.campaign_no,
				spot.screening_date
having			sum(attendance) > 0

select @error = @@error
if @error <> 0
goto error

insert into 	cinelight_attendance_digilite_estimates	
(				campaign_no,
				screening_date,
				cinelight_id,
				attendance,
                showings,
				data_valid)
select			spot.campaign_no,
				spot.screening_date,
                spot.cinelight_id,
				sum(attendance),
                count(spot_id) * 1960,
				'Y'
from 			cinelight_spot spot,
	     		film_campaign fc,
				cinelight c,
				cinelight_attendance_history cah
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no
and				(( fc.campaign_status = 'P' and
				spot.spot_status = 'P' ) or 
				( fc.campaign_status <> 'P' and
				spot.spot_status = 'X' or spot.spot_status = 'A'))
and				spot.cinelight_id = c.cinelight_id
and				cah.screening_date = dbo.f_prev_attendance_screening_date(spot.screening_date)
and				cah.cinelight_id = spot.cinelight_id
and				cah.cinelight_id = c.cinelight_id
group by 		spot.campaign_no,
				spot.screening_date,
                spot.cinelight_id
having			sum(attendance) > 0

select @error = @@error
if @error <> 0
goto error



/*
 * Commit & Return Success
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:
	rollback transaction
	return -1
GO
