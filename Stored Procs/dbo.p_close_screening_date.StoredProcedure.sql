/****** Object:  StoredProcedure [dbo].[p_close_screening_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_close_screening_date]
GO
/****** Object:  StoredProcedure [dbo].[p_close_screening_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_close_screening_date]		@closing_date		datetime,
												@opening_date		datetime                         
as

/*
 * Declare Variables
 */

declare	@error								int,
		@errorode								int,
		@spot_id							int,
		@rowcount							int,
		@complex_id							int,
		@cert_groups						int,
		@spot_csr_open						tinyint,
		@film_plan_id   					int,
		@attendance_exhibitors				int


/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Closing Screening Date
 */
 
update			film_screening_dates
set				screening_date_status = 'X'
where			screening_date = @closing_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Opening Screening Date
 */
 
update			film_screening_dates
set				screening_date_status = 'C'
where			screening_date = @opening_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Status and Spot Instruction
 */

update			campaign_spot
set				spot_status = 'U',
				certificate_score = 9,
				spot_instruction = 'Screening Date Closure - Unallocation'
where			spot_status = 'A' 
and				screening_date = @closing_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Cinelight Status and Spot Instruction
 */

update			cinelight_spot
set				spot_status = 'U',
				certificate_score = 9,
				spot_instruction = 'Screening Date Closure - Unallocation'
where			spot_status = 'A' 
and				screening_date = @closing_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Inclusions - Set Cinemarketing Spots to allocated where appropriate.
 */

update 			inclusion_spot
set				spot_status = 'X'
where 			screening_date = @closing_date
and				spot_status = 'A'

select @error = @@error
if(@error !=0)
	goto error

/*
 * Declare Cursors
 */
 
declare			complex_date_csr cursor static for
select			complex_id
from			complex_date
where			screening_date = @closing_date
order by		complex_id
for read only

/*
 * Update Complex Date - Set Movies Confirmed if No certifcate generated
 */

open complex_date_csr
fetch complex_date_csr into @complex_id
while(@@fetch_status = 0)
begin

	/*
     * Check For Certificate
     */

	select			@cert_groups = 0

	select			@cert_groups = isnull(count(certificate_group_id),0)
    from			certificate_group
    where			complex_id = @complex_id 
	and				screening_date = @closing_date

	select @cert_groups = isnull(@cert_groups,0) 

	if(@cert_groups = 0)
	begin

	  /*
       * Update Complex Date
       */
	
		update			complex_date
		set				certificate_confirmation = 'N',
						no_movies = 1
		where			complex_id = @complex_id 
		and				screening_date = @closing_date

		select @error = @@error
		if(@error !=0)
		begin
			close complex_date_csr
			goto error
		end

	end
	
	/*
     * Fetch Next
     */

	fetch complex_date_csr into @complex_id

end
close complex_date_csr
deallocate complex_date_csr


declare			film_plan_expire_csr cursor static for
select			fp.film_plan_id
from			film_plan fp
where			fp.plan_status = 'A' 
and				fp.film_plan_id not in (	select			distinct fpd.film_plan_id
											from			film_plan_dates fpd
											where			fpd.screening_date > @closing_date)
order by fp.film_plan_id

/* 
 * Update Film Plans - Set to expired where plan has finished
 */

open film_plan_expire_csr
fetch film_plan_expire_csr into @film_plan_id
while(@@fetch_status = 0)
begin

	/*
     * Update Film PLan
     */

	update			film_plan
	set				film_plan.plan_status = 'E' --Expired
	where			film_plan.film_plan_id = @film_plan_id

	select @error = @@error
	if(@error !=0)
	begin
		close film_plan_expire_csr
        deallocate film_plan_expire_csr
		goto error
	end
	
	/*
     * Fetch Next
     */

	fetch film_plan_expire_csr into @film_plan_id

end
close film_plan_expire_csr
deallocate film_plan_expire_csr

/* 
 * Set Onscreen Flag
 */

update campaign_spot
   set onscreen = 'Y'
 where campaign_spot.screening_date = @closing_date
   and campaign_spot.spot_status = 'X' -- allocated

select @error = @@error
if @error != 0
begin
    rollback transaction
    raiserror ('There was an error updating the onscreen flag in the Campaign Spot table.', 16, 1)
    return -100
end 

update campaign_spot
   set onscreen = 'Y'
 where campaign_spot.screening_date = @closing_date
   and campaign_spot.spot_status = 'N' -- no show


select @error = @@error
if @error != 0
begin
    rollback transaction
    raiserror ('There was an error updating the onscreen flag in the Campaign Spot table.', 16, 1)
    return -100
end 

/*
 * Delete Unallocation Ghost Spots
 */

delete 	campaign_spot
where	spot_type = 'G'
and		(spot_status = 'U' 
or		spot_status = 'N')
and 	screening_date = @closing_date

select @error = @@error
if @error != 0
begin
    rollback transaction
    raiserror ('There was an error deleting ghost spots.', 16, 1)
    return -100
end 


/*
	new section for adding a new record in the movie history table 
	for complexs that advertise by screen
*/

exec @error = p_insert_movie_history_complex_by_screen @opening_date

if @error != 0
begin
    rollback transaction
    raiserror ('There was an error inserting movie programming for CINEads complexes.', 16, 1)
    return -100
end 


/*	
	new section to add cinead instructions
*/
	
exec @error = p_add_cinead_instructions @opening_date

if @error != 0
begin
    rollback transaction
    raiserror ('There was an error inserting screening instructions for CINEads campaigns.', 16, 1)
    return -100
end 

/*
 * Update audience targets - set processed = 'Y' for closing week where is has not been processed
 */

update			inclusion_follow_film_targets
set				processed = 'Y'
where			processed = 'N'
and				screening_date = @closing_date
and				inclusion_id in (select inclusion_id from inclusion where inclusion_status <> 'P')

select @error = @@error
if @error != 0
begin
    rollback transaction
    raiserror ('There was an error follow film targets to processed.', 16, 1)
    return -100
end 

update			inclusion_cinetam_targets
set				processed = 'Y'
where			processed = 'N'
and				screening_date = @closing_date
and				inclusion_id in (select inclusion_id from inclusion where inclusion_status <> 'P')

select @error = @@error
if @error != 0
begin
    rollback transaction
    raiserror ('There was an error map and tap targets to processed.', 16, 1)
    return -100
end 

/*
 * Add estimates for any movies that are active in the closing week and have no estimates in the 
 */

 
insert into		cinetam_movie_complex_estimates
select			cinetam_movie_complex_estimates.movie_id,
				cinetam_reporting_demographics_id,
				screening_dates.screening_date,
				cinetam_movie_complex_estimates.complex_id,
				round(attendance * power(0.900000000, DATEDIFF(WK, cinetam_movie_complex_estimates.screening_date, screening_dates.screening_date)),0),
				round(original_estimate * power(0.900000000, DATEDIFF(WK, cinetam_movie_complex_estimates.screening_date, screening_dates.screening_date)),0)
from			cinetam_movie_complex_estimates
inner join		complex on cinetam_movie_complex_estimates.complex_id = complex.complex_id
inner join		branch on complex.branch_code = branch.branch_code
inner join		(select			movie_history.movie_id,
								country
				from			movie_history 
				left outer join	(select			cmce.movie_id,
												br.country_code,
												sum(attendance) as estimate
								from			cinetam_movie_complex_estimates cmce
								inner join		complex cplx on cmce.complex_id = cplx.complex_id
								inner join		branch br on cplx.branch_code = br.branch_code
								where			screening_date = @opening_date
								group by		cmce.movie_id,
												br.country_code) as est_next_week
				on				movie_history.movie_id = est_next_week.movie_id
				and				movie_history.country = est_next_week.country_code
				where			screening_date = @closing_date
				group by		movie_history.movie_id,
								country
				having			count(estimate) = 0) as movies_missing_estimates
on				cinetam_movie_complex_estimates.movie_id = movies_missing_estimates.movie_id
and				branch.country_code = movies_missing_estimates.country
cross join		(select			screening_date
				from			film_screening_dates
				where			screening_date = @opening_date) as screening_dates
where			cinetam_movie_complex_estimates.screening_date = @closing_date


select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting extra estimates', 16, 1)
	rollback transaction
	return -1
end



/*
 * Commit and Return
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
