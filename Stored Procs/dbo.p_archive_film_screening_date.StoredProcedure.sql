/****** Object:  StoredProcedure [dbo].[p_archive_film_screening_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_archive_film_screening_date]
GO
/****** Object:  StoredProcedure [dbo].[p_archive_film_screening_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_archive_film_screening_date] @screening_date 	datetime
as

/*
* Declare variables
*/

declare 	@error		integer,
		@current_date	datetime

/*
* If screening date > than current screening_date return error
*/

select @current_date = screening_date
  from film_screening_dates
 where screening_date_status = 'C'

if @current_date <= @screening_date
begin
	raiserror ('Error: Screening Date is after current screening date and will not be archived.', 16, 1)
	return -1
end

/*
* Begin Transaction
*/

begin transaction

/*
* Archive Complex Dates for this screening date
*/

insert into archive..vault_complex_date
			(complex_date_id,
			complex_id,
			screening_date,
			certificate_status,
			movies_confirmed,
			certificate_confirmation,
			certificate_generation_user,
			certificate_generation,
			certificate_lock_user,
			certificate_locked,
			certificate_comment,
			certificate_revision,
			campaign_safety_limit,
			clash_safety_limit,
			movie_target,
			session_target,
			max_ads,
			max_time,
			no_movies )
  select complex_date_id,
			complex_id,
			screening_date,
			certificate_status,
			movies_confirmed,
			certificate_confirmation,
			certificate_generation_user,
			certificate_generation,
			certificate_lock_user,
			certificate_locked,
			certificate_comment,
			certificate_revision,
			campaign_safety_limit,
			clash_safety_limit,
			movie_target,
			session_target,
			max_ads,
			max_time,
			no_movies
    from complex_date 
   where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

/*
* Delete Complex Date records for this screening date
*/

delete complex_date 
 where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

/*
* Archive Certificate Items and Groups
*/

insert into archive..vault_certificate_group
			(certificate_group_id,
			complex_id,
			screening_date,
			group_no,
			group_short_name,
			group_name,
			is_movie)
  select certificate_group_id,
			complex_id,
			screening_date,
			group_no,
			group_short_name,
			group_name,
			is_movie
    from certificate_group     
   where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

insert into archive..vault_certificate_item
			(certificate_item_id,
			certificate_group,
			print_id,
			sequence_no,
			item_comment,
			spot_reference,
			item_show,
			certificate_auto_create,
			certificate_source,
			campaign_summary)
  select ci.certificate_item_id,
			ci.certificate_group,
			ci.print_id,
			ci.sequence_no,
			ci.item_comment,
			ci.spot_reference,
			ci.item_show,
			ci.certificate_auto_create,
			ci.certificate_source,
			ci.campaign_summary
    from certificate_item ci,
			certificate_group cg
   where cg.screening_date = @screening_date and
			cg.certificate_group_id = ci.certificate_group

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

/*
 * Delete certificate items and groups for this screening date
 */

delete certificate_item
  from certificate_group
 where certificate_item.certificate_group = certificate_group.certificate_group_id and	
		 certificate_group.screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

delete certificate_group
 where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

/*
* Delete Certificate History for this screening date
*/

delete certificate_history 
 where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

/*
* Archive Movie History
*/

/*insert into archive..archive_movie_history 
			(movie_id,
			complex_id,
			screening_date,
			occurence,
			sessions_held,
			attendence)
  select movie_id, 
			complex_id,
			screening_date,
			count(occurence),
			sum(sessions_held),
			sum(attendence)
    from movie_history
   where screening_date = @screening_date
group by movie_id, 
			complex_id,
			screening_date	

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end
*/
/*
 * Delete Movie History records for this screening date
 */

/*delete movie_history
 where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end
*/
/*
* Update Screening Date Flags
*/

update film_screening_dates
   set screening_certificate_removed = 'Y',
		 complex_date_removed = 'Y'
 where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	return -1
end

/*
* Commit and Return
*/

commit transaction
return 0
GO
