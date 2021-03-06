/****** Object:  StoredProcedure [dbo].[p_attendance_estimate_gen_all]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_estimate_gen_all]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_estimate_gen_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_attendance_estimate_gen_all] 
as

/* Populates film_cinatt_estimates table */

/*
 * Declare Variables
 */
set nocount on
declare @error        				integer,
		@employee_id				integer,
		@campaign_no 				integer

/*
 * Begin Transaction
 */

begin transaction


select 		@employee_id = employee_id
from		employee
where		login_id = CURRENT_USER

if @@rowcount != 1
	select @employee_id = 193

/*declare     campaign_csr cursor for
select      campaign_no
from        film_campaign
where       campaign_status = 'L'
order by    campaign_no
for         read only
*/

declare     campaign_csr cursor for
select      campaign_no
from        film_campaign
where       campaign_no in (204735	,
204869	,
302641	,
500287	,
302774	,
204813	,
302880	,
205068	,
205082	,
205051	,
302895	,
205055	,
205043	,
500304	,
400878	,
302640	,
205078	,
600385	,
205225	,
400875	,
400909	,
205312	,
205140	,
302968	,
205052	,
302934	,
600390	,
302998	,
205353	,
500305	,
400876	,
205352	,
205349	,
303052	,
302864	,
205321	,
600382	,
400932	,
205203	,
205385	,
205303	,
205314	,
205076	,
302994	,
205196	,
205197	,
400877	,
303049	,
205354	,
205370	,
205218	,
204444	,
205227	,
205195	,
303004	,
205355	,
205380	,
400927	,
205087	,
303033	,
205290	,
302891	,
302851	,
302853	,
302988	,
303006	,
302886	,
400933	,
204965	,
205284	,
205212	,
400923	,
205251	,
500308	,
600391	,
400914	,
205150	,
302909	,
205372	,
205275	,
302980	,
205328	,
302962	,
205235	,
302973	,
303036	,
302999	,
400894	,
400895	,
303025	,
302983	,
205249	,
303041	,
205248	,
205202	,
205299	,
205311	,
205113	,
303015	,
205149	,
303013	,
302972	,
302984	,
600392	,
205376	,
302938	,
302969	,
205378	,
302937	,
302936	,
302940	,
302939	,
303005	,
205152	,
500306	,
302951	,
205181	,
302859	,
302954	,
302920	,
205344	,
400892	,
400893	,
303011	,
400896	,
400897	,
302917	,
205269	,
205359	,
302857	,
302858	,
302915	,
302918	,
302925	)
for read only

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status=0)
begin
	
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
	and				asda.screening_date = dbo.f_prev_attendance_screening_date(spot.screening_date)
	and				asda.complex_id = spot.complex_id
	and				asda.complex_id = c.complex_id
	and				asda.complex_id = cd.complex_id
	and				cd.complex_id = spot.complex_id
	and				cd.complex_id = c.complex_id
	and				cd.screening_date = spot.screening_date
	and				dbo.f_prev_attendance_screening_date(cd.screening_date) = asda.screening_date
	group by 		spot.campaign_no,
					spot.screening_date
	having			sum(average_programmed * cd.cinatt_weighting) > 0
	
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
	and				asda.screening_date = dbo.f_prev_attendance_screening_date(spot.screening_date)
	and				asda.complex_id = spot.complex_id
	and				asda.complex_id = c.complex_id
	and				asda.complex_id = cd.complex_id
	and				cd.complex_id = spot.complex_id
	and				cd.complex_id = c.complex_id
	and				cd.screening_date = spot.screening_date
	and				dbo.f_prev_attendance_screening_date(cd.screening_date) = asda.screening_date
	group by 		spot.campaign_no,
					spot.screening_date,
					spot.complex_id
	having			sum(average_programmed * cd.cinatt_weighting) > 0

	
	select @error = @@error
	if @error <> 0
	    goto error

	fetch campaign_csr into @campaign_no
end

deallocate campaign_csr

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
