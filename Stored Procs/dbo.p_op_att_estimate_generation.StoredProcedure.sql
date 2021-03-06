/****** Object:  StoredProcedure [dbo].[p_op_att_estimate_generation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_att_estimate_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_op_att_estimate_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_att_estimate_generation] @campaign_no integer
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

delete  outpost_panel_attendance_estimates
where   campaign_no = @campaign_no

select @error = @@error
if @error <> 0
    goto error

delete  outpost_panel_attendance_digilite_estimates
where   campaign_no = @campaign_no

select @error = @@error
if @error <> 0
    goto error

/*
 * Insert Valid Rows
 */

insert into 	outpost_panel_attendance_estimates	
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
from 			outpost_spot spot,
	     		film_campaign fc,
				outpost_panel c,
				outpost_panel_attendance_history cah
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no
and				(( fc.campaign_status = 'P' and
				spot.spot_status = 'P' ) or 
				( fc.campaign_status <> 'P' and
				spot.spot_status = 'X' or spot.spot_status = 'A'))
and				spot.outpost_panel_id = c.outpost_panel_id
and				cah.screening_date = dbo.f_prev_attendance_screening_date(spot.screening_date)
and				cah.outpost_panel_id = spot.outpost_panel_id
and				cah.outpost_panel_id = c.outpost_panel_id
group by 		spot.campaign_no,
				spot.screening_date
having			sum(attendance) > 0

select @error = @@error
if @error <> 0
goto error

insert into 	outpost_panel_attendance_digilite_estimates	
(				campaign_no,
				screening_date,
				outpost_panel_id,
				attendance,
                showings,
				data_valid)
select			spot.campaign_no,
				spot.screening_date,
                spot.outpost_panel_id,
				sum(attendance),
                count(spot_id) * 1960,
				'Y'
from 			outpost_spot spot,
	     		film_campaign fc,
				outpost_panel c,
				outpost_panel_attendance_history cah
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no
and				(( fc.campaign_status = 'P' and
				spot.spot_status = 'P' ) or 
				( fc.campaign_status <> 'P' and
				spot.spot_status = 'X' or spot.spot_status = 'A'))
and				spot.outpost_panel_id = c.outpost_panel_id
and				cah.screening_date = dbo.f_prev_attendance_screening_date(spot.screening_date)
and				cah.outpost_panel_id = spot.outpost_panel_id
and				cah.outpost_panel_id = c.outpost_panel_id
group by 		spot.campaign_no,
				spot.screening_date,
                spot.outpost_panel_id
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
