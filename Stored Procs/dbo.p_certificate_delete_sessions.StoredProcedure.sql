/****** Object:  StoredProcedure [dbo].[p_certificate_delete_sessions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_delete_sessions]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_delete_sessions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_certificate_delete_sessions]			@provider_id				int,
																			@process_time			datetime

as

declare			@error				int

set nocount on

/*
 * Begin Transaction
 */

begin transaction

/*
 * Log all sessions after run date
 */

insert into	movie_history_sessions_log
select			movie_id,
					complex_id,
					screening_date, 
					print_medium,
					three_d_type,
					session_time,
					premium_cinema,
					'deleted',
					getdate()
from				movie_history_sessions				
where			complex_id in (select complex_id from data_translate_complex where data_provider_id = @provider_id)
and				session_time > 	@process_time		
group by		movie_id,
					complex_id,
					screening_date, 
					print_medium,
					three_d_type,
					session_time,
					premium_cinema

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting temporary sessions', 16, 1)
	rollback transaction
	return -1
end
						
/*
 * Delete All sessions after run date
 */

delete			movie_history_sessions_certificate
where			complex_id in (select complex_id from data_translate_complex where data_provider_id = @provider_id)
and				session_time > 	@process_time

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting movie_history_sessions_certificate', 16, 1)
	rollback transaction
	return -1
end

delete			movie_history_sessions				
where			complex_id in (select complex_id from data_translate_complex where data_provider_id = @provider_id)
and				session_time > 	@process_time

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting movie_history_sessions', 16, 1)
	rollback transaction
	return -1
end

/*
 * commit & return
 */

commit transaction
return 0
GO
