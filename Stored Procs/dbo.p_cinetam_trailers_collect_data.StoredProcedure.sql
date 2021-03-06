/****** Object:  StoredProcedure [dbo].[p_cinetam_trailers_collect_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_trailers_collect_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_trailers_collect_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_cinetam_trailers_collect_data]		@screening_date		datetime,
																									@country_code		char(1)

as
			
declare			@error				int

/*
 * Begin Transaction
 */
 
begin transaction

delete		cinetam_trailers_screening_history
where		screening_date = @screening_date 
and			complex_id in (select complex_id from complex, branch where complex.branch_code = branch.branch_code and country_code = @country_code)

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to insert rows', 16, 1)
	return -1
end

/*
 * Step 1 - Pull information from log
 */

insert into		cinetam_trailers_screening_history 
						(screening_date, 
						complex_id, 
						external_complex_id, 
						movie_movie_id, 
						movie_uuid, 
						trailer_movie_id, 
						trailer_uuid, plays)
select				@screening_date, 
						movies.complex_id, 
						movies.external_complex_id, 
						movies.movie_id, 
						movies.uuid, 
						trailers.movie_id, 
						trailers.uuid, 
						count(trailers.actual_start_time)
from				(select		movie.movie_id, 
											long_name, 
											complex.complex_id, 
											complex_name, 
											v_cinetam_movie_info.uuid, 
											external_complex_id, 
											v_cinetam_movie_info.title, 
											v_cinetam_movie_info.cinema_id, 
											v_cinetam_movie_info.ip_addr, 
											v_cinetam_movie_info.start_date, 
											v_cinetam_movie_info.frame_mins, 
											v_cinetam_movie_info.actual_start_time
						from			movie,
											complex,
											cinetam_trailers_complex_xref cplxxref,
											cinetam_trailers_movie,
											[hoysydsqlint.hoyts.net.au].[DigiCineMgmt].[dbo].[v_cinetam_movie_info] as v_cinetam_movie_info
						where			movie.movie_id = cinetam_trailers_movie.movie_id
						and				complex.complex_id = cplxxref.complex_id
						and				v_cinetam_movie_info.uuid = cinetam_trailers_movie.uuid
						and				cplxxref.country_code = @country_code
						and				cplxxref.external_complex_id = v_cinetam_movie_info.complex_id
						and				v_cinetam_movie_info.start_date between @screening_date and dateadd(wk, 1, @screening_date)) as movies,
						(select		movie.movie_id, 
											long_name, 
											complex.complex_id, 
											complex_name, 
											v_cinetam_trailer_info.uuid, 
											external_complex_id, 
											v_cinetam_trailer_info.title, 
											v_cinetam_trailer_info.cinema_id, 
											v_cinetam_trailer_info.ip_addr, 
											v_cinetam_trailer_info.start_date, 
											v_cinetam_trailer_info.frame_mins, 
											v_cinetam_trailer_info.actual_start_time
						from			movie,
											complex,
											cinetam_trailers_complex_xref cplxxref,
											cinetam_trailers_trailers,
											[hoysydsqlint.hoyts.net.au].[DigiCineMgmt].[dbo].[v_cinetam_trailer_info] v_cinetam_trailer_info
						where			movie.movie_id = cinetam_trailers_trailers.movie_id
						and				complex.complex_id = cplxxref.complex_id
						and				cplxxref.country_code = @country_code
						and				v_cinetam_trailer_info.uuid = cinetam_trailers_trailers.uuid
						and				cplxxref.external_complex_id = v_cinetam_trailer_info.complex_id
						and				v_cinetam_trailer_info.start_date between @screening_date and dateadd(wk, 1, @screening_date)) as trailers
where				trailers.actual_start_time between dateadd(mi, -40, movies.actual_start_time) and movies.actual_start_time
and					trailers.cinema_id = movies.cinema_id
group by			movies.complex_id, movies.external_complex_id, movies.movie_id, movies.uuid, trailers.movie_id, trailers.uuid

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to insert rows', 16, 1)
	return -1
end

/*
 * Nsert ad infor for things like the google trailers
 */

insert into		cinetam_trailers_screening_history 
						(screening_date, 
						complex_id, 
						external_complex_id, 
						movie_movie_id, 
						movie_uuid, 
						trailer_movie_id, 
						trailer_uuid, plays)
select				@screening_date, 
						movies.complex_id, 
						movies.external_complex_id, 
						movies.movie_id, 
						movies.uuid, 
						trailers.movie_id, 
						trailers.uuid, 
						count(trailers.actual_start_time)
from				(select		movie.movie_id, 
											long_name, 
											complex.complex_id, 
											complex_name, 
											v_cinetam_movie_info.uuid, 
											external_complex_id, 
											v_cinetam_movie_info.title, 
											v_cinetam_movie_info.cinema_id, 
											v_cinetam_movie_info.ip_addr, 
											v_cinetam_movie_info.start_date, 
											v_cinetam_movie_info.frame_mins, 
											v_cinetam_movie_info.actual_start_time
						from			movie,
											complex,
											cinetam_trailers_complex_xref cplxxref,
											cinetam_trailers_movie,
											[hoysydsqlint.hoyts.net.au].[DigiCineMgmt].[dbo].[v_cinetam_movie_info] as v_cinetam_movie_info
						where			movie.movie_id = cinetam_trailers_movie.movie_id
						and				complex.complex_id = cplxxref.complex_id
						and				v_cinetam_movie_info.uuid = cinetam_trailers_movie.uuid
						and				cplxxref.country_code = @country_code
						and				cplxxref.external_complex_id = v_cinetam_movie_info.complex_id
						and				v_cinetam_movie_info.start_date between @screening_date and dateadd(wk, 1, @screening_date)) as movies,
						(select		movie.movie_id, 
											long_name, 
											complex.complex_id, 
											complex_name, 
											v_cinetam_ads_info.uuid, 
											external_complex_id, 
											v_cinetam_ads_info.title, 
											v_cinetam_ads_info.cinema_id, 
											v_cinetam_ads_info.ip_addr, 
											v_cinetam_ads_info.start_date, 
											v_cinetam_ads_info.frame_mins, 
											v_cinetam_ads_info.actual_start_time
						from			movie,
											complex,
											cinetam_trailers_complex_xref cplxxref,
											cinetam_trailers_trailers,
											[hoysydsqlint.hoyts.net.au].[DigiCineMgmt].[dbo].[v_cinetam_ads_info] v_cinetam_ads_info
						where			movie.movie_id = cinetam_trailers_trailers.movie_id
						and				complex.complex_id = cplxxref.complex_id
						and				cplxxref.country_code = @country_code
						and				v_cinetam_ads_info.uuid = cinetam_trailers_trailers.uuid
						and				cplxxref.external_complex_id = v_cinetam_ads_info.complex_id
						and				v_cinetam_ads_info.start_date between @screening_date and dateadd(wk, 1, @screening_date)) as trailers
where				trailers.actual_start_time between dateadd(mi, -40, movies.actual_start_time) and movies.actual_start_time
and					trailers.cinema_id = movies.cinema_id
group by			movies.complex_id, movies.external_complex_id, movies.movie_id, movies.uuid, trailers.movie_id, trailers.uuid

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to insert rows', 16, 1)
	return -1
end

/*
 * step 2 update table with session information
 */
 
update		cinetam_trailers_screening_history 
set				movie_sessions = temp_table.sessions_scheduled
from			(select			complex_id, 
											screening_date, 
											movie_id, 
											sum(sessions_scheduled) as sessions_scheduled 
					from				movie_history 
					where			country = @country_code
					group by			complex_id, 
											screening_date, 
											movie_id) as temp_table
where			temp_table.screening_date = cinetam_trailers_screening_history.screening_date
and				temp_table.complex_id = cinetam_trailers_screening_history.complex_id
and				temp_table.movie_id = cinetam_trailers_screening_history.movie_movie_id
and				temp_table.screening_date = @screening_date
 
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to update sessions', 16, 1)
	return -1
end

/*
 * Step 3 set attendance_multiplier
 */
 
update		cinetam_trailers_screening_history
set				attendance_multiplier = case  when plays / movie_sessions >= 1 then 1 else round(plays / movie_sessions, 0) end
where			screening_date = @screening_date
and				movie_sessions <> 0

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to update attendance multiplier', 16, 1)
	return -1
end

update		cinetam_trailers_screening_history
set				attendance_multiplier = 1
where			screening_date = @screening_date
and				isnull(movie_sessions,0) = 0

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to update attendance multiplier', 16, 1)
	return -1
end

update cinetam_trailers_movie
set	framecount = cplduration,
		edit_rate = cpleditrate,
		discover_date = cpldiscoverdate
from [hoysydsqlint.hoyts.net.au].[DigiCineMgmt].[dbo].cpl as cpl
where cinetam_trailers_movie.uuid = cpl.cpluuidstring

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to update movie times', 16, 1)
	return -1
end


update cinetam_trailers_trailers
set	framecount = cplduration,
		edit_rate = cpleditrate,
		discover_date = cpldiscoverdate
from [hoysydsqlint.hoyts.net.au].[DigiCineMgmt].[dbo].cpl as cpl
where cinetam_trailers_trailers.uuid = cpl.cpluuidstring


select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error failed to update trailer times', 16, 1)
	return -1
end


commit transaction
return 0
GO
