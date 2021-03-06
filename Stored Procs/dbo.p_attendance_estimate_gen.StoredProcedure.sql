/****** Object:  StoredProcedure [dbo].[p_attendance_estimate_gen]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_estimate_gen]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_estimate_gen]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_attendance_estimate_gen] @campaign_no integer
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

delete  attendance_campaign_estimates
where   campaign_no = @campaign_no

select @error = @@error
if @error <> 0
    goto error

delete  attendance_campaign_complex_estimates
where   campaign_no = @campaign_no

select @error = @@error
if @error <> 0
    goto error

/*
* Insert Valid Rows
*/

insert into 	attendance_campaign_estimates	
(				campaign_no,
			screening_date,
			employee_id,
			process_date,
			attendance,
			data_valid)
select			spot.campaign_no,
			spot.screening_date,
			@employee_id,
			getdate(),
			sum(average_programmed * cd.cinatt_weighting),
			'Y'
from 			campaign_spot spot,
     		film_campaign fc,
			complex c,
			complex_date cd,
			attendance_screening_date_averages asda
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no
and				(( fc.campaign_status = 'P' and
			spot.spot_status = 'P' ) or 
			( fc.campaign_status <> 'P' and
			spot.spot_status = 'X' or spot.spot_status = 'A'))
and				spot.complex_id = c.complex_id
and				asda.screening_date = spot.screening_date
and				asda.complex_id = spot.complex_id
and				asda.complex_id = c.complex_id
and				asda.complex_id = cd.complex_id
and				cd.complex_id = spot.complex_id
and				cd.complex_id = c.complex_id
and				cd.screening_date = spot.screening_date
and				cd.screening_date = asda.screening_date
group by 		spot.campaign_no,
			spot.screening_date

select @error = @@error
if @error <> 0
goto error

insert into 	attendance_campaign_complex_estimates	
(				campaign_no,
			screening_date,
			complex_id,
			attendance,
			data_valid)
select			spot.campaign_no,
			spot.screening_date,
			spot.complex_id,
			sum(average_programmed * cd.cinatt_weighting),
			'Y'
from 			campaign_spot spot,
     		film_campaign fc,
			complex c,
			attendance_screening_date_averages asda,
			complex_date cd
where 			fc.campaign_no = @campaign_no 
and				fc.campaign_no = spot.campaign_no
and				(( fc.campaign_status = 'P' and
			spot.spot_status = 'P' ) or 
			( fc.campaign_status <> 'P' and
			spot.spot_status = 'X' or spot.spot_status = 'A'))
and				spot.complex_id = c.complex_id
and				asda.screening_date = spot.screening_date
and				asda.complex_id = spot.complex_id
and				asda.complex_id = c.complex_id
and				asda.complex_id = cd.complex_id
and				cd.complex_id = spot.complex_id
and				cd.complex_id = c.complex_id
and				cd.screening_date = spot.screening_date
and				cd.screening_date = asda.screening_date
group by 		spot.campaign_no,
			spot.screening_date,
			spot.complex_id

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
