/****** Object:  StoredProcedure [dbo].[p_certificate_link_sessions_provider]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_link_sessions_provider]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_link_sessions_provider]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

					
create proc [dbo].[p_certificate_link_sessions_provider]			@data_provider_id				int,
																	@process_time					datetime,
																	@issues							varchar(max) OUTPUT
																						
as

declare			@error								int,
				@movie_id						int,
				@certificate_count			int,
				@premium_cinema			char(1),   
				@print_medium				char(1),   
				@three_d_type				int,
				@show_category				char(1),
				@no_movies						int,
				@exhibitor_id					int,
				@complex_id					int,
				@screening_date				datetime,
				@error_message				varchar(max),
				@error_message1			varchar(max)
						
set nocount on

				
select			@exhibitor_id = exhibitor_id
from				data_provider 
where			data_provider_id = @data_provider_id

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
 * Create Temp Table
 */

create table #sessions
(
movie_id								int				not null,
complex_id							int				not null,
screening_date					datetime		not null,
print_medium						char(1)			not null,
three_d_type						int				not null,
session_time						datetime		not null,
premium_cinema					char(1)			not null,
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
select			movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,   
					movie_history.premium_cinema,   
					movie_history.print_medium,   
					movie_history.three_d_type,
					count(*) as no_movies
from				movie_history  
where			movie_history.complex_id in (select complex_id from data_translate_complex where data_provider_id = @data_provider_id)
and				dateadd(ss, -1, dateadd(wk, 1, movie_history.screening_date)) >= @process_time
and				movie_history.movie_id <> 102 
and				movie_history.certificate_group is not null
group by		movie_history.screening_date,
					movie_history.complex_id,
					movie_history.movie_id,   
					movie_history.premium_cinema,   
					movie_history.print_medium,   
					movie_history.three_d_type
for				read only

open movie_csr
fetch movie_csr into @screening_date, @complex_id, @movie_id, @premium_cinema, @print_medium, @three_d_type, @no_movies
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
	and				movie_history_sessions.session_time > @process_time
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
	
	fetch movie_csr into @screening_date, @complex_id, @movie_id, @premium_cinema, @print_medium, @three_d_type, @no_movies
end

/*
 * Insert all rows from temp table into the real table
 */

update			#sessions
set				rowno_mod		= no_movies
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
 * New Movies
 */

--orphaned movies - where vm have playlists and there are now no sessions when there used to be
select			@error_message1 = coalesce(@error_message1 + char(10) + char(13), '' ) + '!!NO SESSIONS ANYMORE!!: ' + error_desc
from				(select			convert(varchar(20), screening_date, 106) + ' / ' + complex_name + ' / ' + long_name + ' / ' + three_d_type_desc + ' / ' 	+ case when premium_cinema = 'Y' then 'Premium' when  premium_cinema = 'L' then 'Premium Shared' else 'Normal' end as error_desc
					from				(select					complex_id,
																	screening_date, 
																	movie_id,
																	print_medium,
																	three_d_type,
																	premium_cinema,
																	count(*) as no_sessions,
																	(select			count(*) 
																	from				movie_history_sessions
																	where			movie_history.screening_date = movie_history_sessions.screening_date
																	and				movie_history.complex_id = movie_history_sessions.complex_id
																	and				movie_history.print_medium = movie_history_sessions.print_medium
																	and				movie_history.three_d_type = movie_history_sessions.three_d_type
																	and				movie_history.movie_id = movie_history_sessions.movie_id
																	and				movie_history.premium_cinema = movie_history_sessions.premium_cinema
																	and				movie_history_sessions.session_time >= @process_time) as number_of_playlists
										from						movie_history
										where					movie_history.complex_id in (select complex_id from data_translate_complex where data_provider_id = @data_provider_id)
										and						movie_history.complex_id not in (114,216,307,308,454,454)
										and						screening_date = dateadd(dd,datediff(dd,0,getdate())/7 * 7 + 3,0)
										and						premium_cinema <> 'S'
										and						movie_id not in (3007,2630,246,1345,102)
										group by				complex_id,
																	screening_date, 
																	movie_id,
																	print_medium,
																	three_d_type,
																	premium_cinema) as temp_table
					inner join		complex				on temp_table.complex_id = complex.complex_id
					inner join		movie					on  temp_table.movie_id = movie.movie_id
					inner join		print_medium		on  temp_table.print_medium = print_medium.print_medium
					inner join		three_d				on  temp_table.three_d_type = three_d.three_d_type
					where			temp_table.number_of_playlists = 0
					group by		screening_date,
										complex_name,
										temp_table.complex_id,
										three_d_type_desc,
										print_medium_desc,
										long_name, 
										temp_table.movie_id,
										premium_cinema,
										no_sessions,
										case when premium_cinema = 'Y' then 'Premium' when  premium_cinema = 'L' then 'Premium Shared' else 'Normal' end) as temp_outer_table


--new movies where there are no corresponding playlists on the VM side
--select			@error_message = coalesce(@error_message + char(13) /*+ char(10)*/, '' ) + '!!NEW MOVIE!!: ' + error_desc
select			@error_message = coalesce(@error_message + char(10) + char(13), '' ) + '!!NEW MOVIE!!: ' + error_desc
from				(select			convert(varchar(20), screening_date, 106) + ' / ' + complex_name + ' / ' + long_name + ' / ' + three_d_type_desc + ' / ' 	+ case when premium_cinema = 'Y' then 'Premium' when  premium_cinema = 'L' then 'Premium Shared' else 'Normal' end + ' / No. Sessions:' + convert(varchar(5), no_sessions) as error_desc
					from				(select					complex_id,
																	screening_date, 
																	movie_id,
																	print_medium,
																	three_d_type,
																	premium_cinema,
																	count(*) as no_sessions,
																	(select			count(*) 
																	from				movie_history
																	where			movie_history.screening_date = movie_history_sessions.screening_date
																	and				movie_history.complex_id = movie_history_sessions.complex_id
																	and				movie_history.print_medium = movie_history_sessions.print_medium
																	and				movie_history.three_d_type = movie_history_sessions.three_d_type
																	and				movie_history.movie_id = movie_history_sessions.movie_id
																	and				movie_history.premium_cinema = movie_history_sessions.premium_cinema) as number_of_playlists
										from						movie_history_sessions
										where					movie_history_sessions.complex_id in (select complex_id from data_translate_complex where data_provider_id = @data_provider_id)
										and						movie_history_sessions.session_time >= @process_time
										and						premium_cinema <> 'S'
										and						movie_id not in (3007,2630,246,1345)
										group by				complex_id,
																	screening_date, 
																	movie_id,
																	print_medium,
																	three_d_type,
																	premium_cinema) as temp_table
					inner join		complex				on temp_table.complex_id = complex.complex_id
					inner join		movie					on  temp_table.movie_id = movie.movie_id
					inner join		print_medium		on  temp_table.print_medium = print_medium.print_medium
					inner join		three_d				on  temp_table.three_d_type = three_d.three_d_type
					where			temp_table.number_of_playlists = 0
					group by		screening_date,
										complex_name,
										temp_table.complex_id,
										three_d_type_desc,
										print_medium_desc,
										long_name, 
										temp_table.movie_id,
										premium_cinema,
										no_sessions,
										case when premium_cinema = 'Y' then 'Premium' when  premium_cinema = 'L' then 'Premium Shared' else 'Normal' end) as temp_outer_table


select			@issues = @error_message1 + + char(10) + char(13) + @error_message

/*
  * Commit Transaction and Return
  */
  
commit transaction
return 0
GO
