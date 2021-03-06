/****** Object:  StoredProcedure [dbo].[p_movie_history_from_sessions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_history_from_sessions]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_history_from_sessions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_movie_history_from_sessions]		@data_provider_id				int,
														@screening_date					datetime	

as

declare			@error									int,
				@count									int,
				@movie_history_count				int

set nocount on

/*
 ****NOTES****
	Movie history status
	C = Current playlist
	N = New Playlist
	R = Removed Playlist
*/

select			@movie_history_count = count(*)
from			movie_history
inner join		v_data_translate_complex_unique on movie_history.complex_id = v_data_translate_complex_unique.complex_id
where			data_provider_id = @data_provider_id
and				screening_date = @screening_date
and				movie_id <> 102
and				certificate_group is not null
and				movie_history.complex_id in (	select			movie_history_sessions.complex_id 
												from			movie_history_sessions 
												inner join		v_data_translate_complex_unique on movie_history_sessions.complex_id = v_data_translate_complex_unique.complex_id 	
												where			movie_history_sessions.screening_date = @screening_date
												and				data_provider_id = @data_provider_id) 

/*
 * Begin Transaction
 */

begin transaction

/*
 * Check and make sure there are no zero session cutover records set them to 35 as a default if there are any
 */

update			complex_date
set				session_cutover = 35
from			v_data_translate_complex_unique 
where			data_provider_id = @data_provider_id
and				screening_date = @screening_date
and				isnull(session_cutover,0) = 0
and				complex_date.complex_id = v_data_translate_complex_unique.complex_id


select @error = @@error
if @error <> 0
begin
	raiserror ('Error - could not update session cutover values that have not been set', 16, 1)
	rollback transaction
	return -1
end

/*
 * Insert current sessions programming into temp table
 */
 
 create table #movie_history
(
   movie_id					int						not null,
   complex_id				int						not null,
   screening_date			datetime				not null,
   occurence				smallint				not null,
   print_medium				char(1)					not null,
   three_d_type				int						not null,
   altered					char(1)					not null,
   advertising_open			char(1)					not null,
   source					char(1)					not null,
   start_date				datetime				null,
   premium_cinema			char(1)					not null,
   show_category			char(1)					not null,
   movie_print_medium		char(1)					not null,
   sessions_scheduled		smallint				not null,
   country					char(1)					not null,
   status					char(1)					not null
)


insert into		#movie_history
select			movie_id,
				complex_id,
				screening_date,
				row_number() over(partition by movie_id, complex_id, screening_date/*, print_medium,three_d_type*/ order by three_d_type, case when premium_cinema = 'N' then 1 when premium_cinema = 'Y' then 2 else 3 end) as occurence,
				print_medium,
				three_d_type,
				altered,
				advertising_open,
				source,
				start_date,
				premium_cinema,
				show_category,
				movie_print_medium,
				round(case when no_playlists = 0 then sessions_scheduled else sessions_scheduled / no_playlists end, 0) as sessions_scheduled,
				country_code,
				status
from			(select			movie_id, 
								movie_history_sessions.complex_id, 
								movie_history_sessions.screening_date, 
								print_medium,
								three_d_type,
								'N' as altered,
								case when premium_cinema = 'S' then 'S' else case when count(movie_id) < complex_date.session_threshold  then 'N' else 'Y' end end as advertising_open,
								'D' as source,
								convert(datetime, convert(date, min(session_time))) as start_date,
								premium_cinema,
								case when premium_cinema = 'S' then 'S' else 'U' end as show_category,
								print_medium as movie_print_medium,
								count(movie_id) as sessions_scheduled,
								country_code,
								'C' as status, --current
								(count(movie_id) / session_cutover) + case when count(movie_id) % session_cutover = 0 then 0 else 1 end as no_playlists
				from			movie_history_sessions 
				inner join		v_data_translate_complex_unique on movie_history_sessions.complex_id = v_data_translate_complex_unique.complex_id
				inner join		complex_date on movie_history_sessions.complex_id = complex_date.complex_id and movie_history_sessions.screening_date = complex_date.screening_date
				inner join		complex on movie_history_sessions.complex_id = complex.complex_id
				inner join		branch on complex.branch_code = branch.branch_code
				where			movie_history_sessions.screening_date = @screening_date
				and				data_provider_id = @data_provider_id
				group by		movie_id, 
								movie_history_sessions.complex_id, 
								movie_history_sessions.screening_date,
								complex_date.session_threshold,
								premium_cinema,
								print_medium,
								three_d_type,
								country_code,
								session_cutover) as session_temp
cross join		(SELECT TOP 20 ROW_NUMBER() OVER(ORDER BY (SELECT 1)) FROM sys.columns) row_multiplier (rownumbers)
where			row_multiplier.rownumbers <= session_temp.no_playlists
order by		session_temp.complex_id, 
				session_temp.screening_date,
				session_temp.movie_id, 
				session_temp.print_medium,
				session_temp.three_d_type,
				session_temp.country_code,
				session_temp.premium_cinema

if @data_provider_id = 2
begin
	delete			#movie_history
	where			premium_cinema = 'S'
end


/*
 * Compare records of movie history table - insert new, set removed to removed and new to new
 */

 --print @movie_history_count
 if @movie_history_count = 0
 begin

	delete			movie_history
	from			v_data_translate_complex_unique
	where			data_provider_id = @data_provider_id
	and				screening_date = @screening_date
	and				movie_history.complex_id = v_data_translate_complex_unique.complex_id
	and				movie_id <> 102
	and				certificate_group is null
	and				status = 'C'
	and				movie_history.complex_id in (	select			movie_history_sessions.complex_id 
																		from				movie_history_sessions 
																		inner join		v_data_translate_complex_unique on movie_history_sessions.complex_id = v_data_translate_complex_unique.complex_id 	
																		where			movie_history_sessions.screening_date = @screening_date
																		and				data_provider_id = @data_provider_id) 

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error - could not delete existing movie programming data', 16, 1)
		rollback transaction
		return -1
	end
	
	insert into movie_history
	(
		movie_id,
		complex_id,
		screening_date,
		occurence,
		print_medium,
		three_d_type,
		altered,
		advertising_open,
		source,
		start_date,
		premium_cinema,
		show_category,
		movie_print_medium,
		sessions_scheduled,
		country,
		status
	)
	select			movie_id,
						complex_id,
						screening_date,
						occurence,
						print_medium,
						three_d_type,
						altered,
						advertising_open,
						source,
						start_date,
						premium_cinema,
						show_category,
						movie_print_medium,
						sessions_scheduled,
						country,
						status
	from				#movie_history	

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error - could not insert new movie programming data', 16, 1)
		rollback transaction
		return -1
	end
 end 
 else
 begin
	/*insert new movies - status = 'C' if certificates have not been generated and 'N' */
	insert into		movie_history
	(
		movie_id,
		complex_id,
		screening_date,
		occurence,
		print_medium,
		three_d_type,
		altered,
		advertising_open,
		source,
		start_date,
		premium_cinema,
		show_category,
		movie_print_medium,
		sessions_scheduled,
		country,
		status
	)
	select				#movie_history.movie_id,
							#movie_history.complex_id,
							#movie_history.screening_date,
							#movie_history.occurence,
							#movie_history.print_medium,
							#movie_history.three_d_type,
							#movie_history.altered,
							#movie_history.advertising_open,
							#movie_history.source,
							#movie_history.start_date,
							#movie_history.premium_cinema,
							#movie_history.show_category,
							#movie_history.movie_print_medium,
							#movie_history.sessions_scheduled,
							#movie_history.country,
							'N'
	from					#movie_history
	left outer join	(select				movie_id,
													movie_history.complex_id,
													screening_date,
													occurence,
													print_medium,
													three_d_type
								from				movie_history
								inner join		v_data_translate_complex_unique on movie_history.complex_id = v_data_translate_complex_unique.complex_id
								where			data_provider_id = @data_provider_id
								and				screening_date = @screening_date
								and				movie_id <> 102) as movie_history_tmp
	on						#movie_history.movie_id = movie_history_tmp.movie_id
	and					#movie_history.complex_id = movie_history_tmp.complex_id
	and					#movie_history.screening_date = movie_history_tmp.screening_date
	and					#movie_history.occurence = movie_history_tmp.occurence
	and					#movie_history.print_medium = movie_history_tmp.print_medium
	and					#movie_history.three_d_type = movie_history_tmp.three_d_type
	where				movie_history_tmp.movie_id is null


	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error - could not insert new movie programming data', 16, 1)
		rollback transaction
		return -1
	end

	/*set removed movie status*/
	update				movie_history
	set					movie_history.status = 'R'
	from					movie_history
	inner join			v_data_translate_complex_unique on movie_history.complex_id = v_data_translate_complex_unique.complex_id
	left outer join	#movie_history 
	on						movie_history.movie_id = #movie_history.movie_id
	and					movie_history.complex_id = #movie_history.complex_id
	and					movie_history.screening_date = #movie_history.screening_date
	and					movie_history.occurence = #movie_history.occurence
	and					movie_history.print_medium = #movie_history.print_medium
	and					movie_history.three_d_type = #movie_history.three_d_type
	where				#movie_history.movie_id is null
	and					#movie_history.complex_id  is null
	and					#movie_history.screening_date is null
	and					#movie_history.occurence is null
	and					#movie_history.print_medium is null
	and					#movie_history.three_d_type is null
	and					movie_history.screening_date = @screening_date
	and					data_provider_id = @data_provider_id
	and					movie_history.movie_id <> 102
	and					movie_history.complex_id in (	select			movie_history_sessions.complex_id 
																			from				movie_history_sessions 
																			inner join		v_data_translate_complex_unique on movie_history_sessions.complex_id = v_data_translate_complex_unique.complex_id 	
																			where			movie_history_sessions.screening_date = @screening_date
																			and				data_provider_id = @data_provider_id) 
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error - could not update status on removed programming data', 16, 1)
		rollback transaction
		return -1
	end

	delete			movie_history
	from				v_data_translate_complex_unique 
	where			movie_history.complex_id = v_data_translate_complex_unique.complex_id
	and				data_provider_id = @data_provider_id
	and				screening_date = @screening_date
	and				movie_id <> 102
	and				certificate_group is null
	and				status = 'R'
	and				movie_history.complex_id in (	select			movie_history_sessions.complex_id 
																		from				movie_history_sessions 
																		inner join		v_data_translate_complex_unique on movie_history_sessions.complex_id = v_data_translate_complex_unique.complex_id 	
																		where			movie_history_sessions.screening_date = @screening_date
																		and				data_provider_id = @data_provider_id) 

	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error - could not delete removed programming data', 16, 1)
		rollback transaction
		return -1
	end
 end

 update			movie_history
set				advertising_open = 'Y'
from			movie_history
inner join		v_data_translate_complex_unique on movie_history.complex_id = v_data_translate_complex_unique.complex_id
where			data_provider_id = @data_provider_id
and				screening_date = @screening_date
and				movie_id <> 102
and				premium_cinema <> 'N'
and				movie_history.complex_id in (	select			movie_history_sessions.complex_id 
												from			movie_history_sessions 
												inner join		v_data_translate_complex_unique on movie_history_sessions.complex_id = v_data_translate_complex_unique.complex_id 	
												where			movie_history_sessions.screening_date = @screening_date
												and				data_provider_id = @data_provider_id) 


commit transaction

--select * from #movie_history
return 0
GO
