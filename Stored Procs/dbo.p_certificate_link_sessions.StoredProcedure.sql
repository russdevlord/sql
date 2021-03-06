/****** Object:  StoredProcedure [dbo].[p_certificate_link_sessions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_link_sessions]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_link_sessions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_certificate_link_sessions]			@complex_id				int,
																							@screening_date		datetime

as

declare				@error								int,
						@movie_id						int,
						@certificate_count			int,
						@premium_cinema			char(1),   
						@print_medium				char(1),   
						@three_d_type				int,
						@no_movies						int,
						@exhibitor_id					int
						
set nocount on

				
select			@exhibitor_id = exhibitor_id
from				complex 
where			complex_id = @complex_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to delete existing session certificate links', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction
						
/* 
 * Delete existing	movie_history_sessions_certificate records
 */

delete			movie_history_sessions_certificate  
where			screening_date = @screening_date 
and				complex_id = @complex_id

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete existing session certificate links', 16, 1)
	return -1
end

/* 
 * Create Temp Table
 */

create table #sessions
(
movie_id								int				not null,
complex_id							int				not null,
screening_date					datetime		not null,
print_medium						char(1)		not null,
three_d_type						int				not null,
session_time						datetime		not null,
premium_cinema					char(1)		not null,
rowno									int				not null,
rowno_mod							int				not null,
no_movies								int				not null
)

create table #occurence
(
occurence								int				not null,
rowno									int				not null,
rowno_mod							int				not null,
no_movies								int				not null,
complex_id							int				not null,
screening_date					datetime		not null,
movie_id								int				not null,
print_medium						char(1)			not null,					
three_d_type						int				not null,
premium_cinema					char(1)			not null,
certificate_group					int				not null
)

/*
 * Loop distinct movies
 */
  
declare			movie_csr cursor for
select			movie_history.movie_id,   
					movie_history.premium_cinema,   
					movie_history.print_medium,   
					movie_history.three_d_type,
					count(*) as no_movies
from				movie_history  
where			movie_history.complex_id = @complex_id
and				movie_history.screening_date = @screening_date
and				movie_history.movie_id <> 102 
and				movie_history.certificate_group is not null
group by		movie_history.movie_id,   
					movie_history.premium_cinema,   
					movie_history.print_medium,   
					movie_history.three_d_type
for				read only

open movie_csr
fetch movie_csr into @movie_id, @premium_cinema, @print_medium, @three_d_type, @no_movies
while(@@fetch_status = 0)
begin

	insert			into #sessions
	select			movie_history_sessions.movie_id, 
						movie_history_sessions.complex_id,
						movie_history_sessions.screening_date,
						movie_history_sessions.print_medium,
						movie_history_sessions.three_d_type,
						movie_history_sessions.session_time, 
						movie_history_sessions.premium_cinema,
						row_number() over (order by session_priority_matrix.rank ) as rowno,
						row_number() over (order by session_priority_matrix.rank )  % @no_movies as rowno_mod,
						@no_movies
	from				movie_history_sessions,
						session_priority_matrix														
	where			movie_history_sessions.complex_id = @complex_id
	and				movie_history_sessions.screening_date = @screening_date
	and				movie_history_sessions.movie_id = @movie_id
	and				movie_history_sessions.print_medium = @print_medium
	and				movie_history_sessions.three_d_type = @three_d_type
	and				movie_history_sessions.premium_cinema = @premium_cinema
	and				session_priority_matrix.exhibitor_id = @exhibitor_id
	and				session_priority_matrix.hour = datepart(hh, session_time)
	and				session_priority_matrix.day = datepart(dw, session_time)

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to insert into temp table', 16, 1)
		return -1
	end

	insert			into #occurence
	select			movie_history.occurence,
						row_number() over (order by occurence ) as rowno,
						row_number() over (order by occurence )  % @no_movies as rowno_mod,
						@no_movies,
						movie_history.complex_id,
						movie_history.screening_date,
						movie_history.movie_id, 
						movie_history.print_medium,
						movie_history.three_d_type,
						movie_history.premium_cinema,
						movie_history.certificate_group
	from				movie_history
	where			movie_history.complex_id = @complex_id
	and				movie_history.screening_date = @screening_date
	and				movie_history.movie_id = @movie_id
	and				movie_history.print_medium = @print_medium
	and				movie_history.three_d_type = @three_d_type
	and				movie_history.premium_cinema = @premium_cinema
	and				movie_history.certificate_group is not null

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to insert into temp table', 16, 1)
		return -1
	end
	
	fetch movie_csr into @movie_id, @premium_cinema, @print_medium, @three_d_type,  @no_movies
end

/*
 * Insert all rows from temp table into the real table
 */

update			#sessions
set				rowno_mod		 = no_movies
where			rowno_mod		= 0

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert into temp table', 16, 1)
	return -1
end

update			#occurence
set				rowno_mod		= no_movies
where			rowno_mod		= 0

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert into temp table', 16, 1)
	return -1
end

insert into	movie_history_sessions_certificate
select			#sessions.movie_id,
					#sessions.complex_id,
					#sessions.screening_date,
					#sessions.print_medium,
					#sessions.three_d_type,
					#sessions.session_time,
					#sessions.premium_cinema,
					#occurence.certificate_group
from				#sessions,
					#occurence
where			#occurence.rowno_mod = #sessions.rowno_mod
and				#sessions.complex_id = #occurence.complex_id
and				#sessions.screening_date = #occurence.screening_date
and				#sessions.movie_id = #occurence.movie_id
and				#sessions.print_medium = #occurence.print_medium
and				#sessions.three_d_type = #occurence.three_d_type
and				#sessions.premium_cinema = #occurence.premium_cinema

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert into temp table', 16, 1)
	return -1
end

/*
  * Commit Transaction and Return
  */
  
commit transaction
return 0
GO
