/****** Object:  StoredProcedure [dbo].[p_movie_history_create_sessions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_history_create_sessions]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_history_create_sessions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_movie_history_create_sessions]		@session_id			int

as

declare		@error							int,
			@movie_id						int,
			@complex_id						int,
			@screening_date					datetime,
			@session_time					datetime,
			@print_medium					char(1),
			@three_d_type					char(1),
			@premium_cinema					char(1),
			@is3d							varchar(10),
			@islux							varchar(10),
			@provider_id					int

begin transaction

insert into		movie_history_sessions
select			movie_history_session_import.movie_id,
				movie_history_session_import.complex_id,
				movie_history_session_import.weekcommencing as screening_date,
				'D' as print_medium,
				case when upper(movie_history_session_import.is3d) = upper('TRUE') then 2 else 1 end as three_d_type,
				movie_history_session_import.sessiondate as session_time,
				case cinema_category.cinema_category_code 
					when 'C' then 'N'
					when 'G' then 'Y'
					when 'L' then 'Y'
					when 'N' then 'N'
				end as premium
from			movie_history_session_import
inner join		complex_pos_to_physical on movie_history_session_import.complex_id = complex_pos_to_physical.complex_id
and				movie_history_session_import.screen = complex_pos_to_physical.pos_screen_id
inner join		cinema on complex_pos_to_physical.complex_id = cinema.complex_id
and				complex_pos_to_physical.cinema_no = cinema.cinema_no
inner join		cinema_category on cinema.cinema_category = cinema_category.cinema_category_code
where			session_id = @session_id
and				cinema_category in ('N', 'L', 'C', 'G')
group by		movie_history_session_import.movie_id,
				movie_history_session_import.complex_id,
				movie_history_session_import.weekcommencing,
				case when upper(movie_history_session_import.is3d) = upper('TRUE') then 2 else 1 end,
				movie_history_session_import.sessiondate,
				case cinema_category.cinema_category_code 
					when 'C' then 'N'
					when 'G' then 'Y'
					when 'L' then 'Y'
					when 'N' then 'N'
				end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to insert session information', 16, 1)
	rollback transaction
	return -1
end

insert into		movie_history_sessions_log
select			movie_history_session_import.movie_id,
				movie_history_session_import.complex_id,
				movie_history_session_import.weekcommencing as screening_date,
				'D' as print_medium,
				case when upper(movie_history_session_import.is3d) = upper('TRUE') then 2 else 1 end as three_d_type,
				movie_history_session_import.sessiondate as session_time,
				case cinema_category.cinema_category_code 
					when 'C' then 'N'
					when 'G' then 'Y'
					when 'L' then 'Y'
					when 'N' then 'N'
				end as premium,
				'inserted' as status,
				getdate() as logged_date
from			movie_history_session_import
inner join		complex_pos_to_physical on movie_history_session_import.screen = complex_pos_to_physical.pos_screen_id
inner join		cinema on complex_pos_to_physical.complex_id = cinema.complex_id
and				complex_pos_to_physical.cinema_no = cinema.cinema_no
inner join		cinema_category on cinema.cinema_category = cinema_category.cinema_category_code
where			session_id = @session_id
and				cinema_category in ('N', 'L', 'C', 'G')
group by		movie_history_session_import.movie_id,
				movie_history_session_import.complex_id,
				movie_history_session_import.weekcommencing,
				case when upper(movie_history_session_import.is3d) = upper('TRUE') then 2 else 1 end,
				movie_history_session_import.sessiondate,
				case cinema_category.cinema_category_code 
					when 'C' then 'N'
					when 'G' then 'Y'
					when 'L' then 'Y'
					when 'N' then 'N'
				end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to insert session log information', 16, 1)
	rollback transaction
	return -1
end

delete			movie_history_session_import
where			session_id = @session_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to session log information', 16, 1)
	rollback transaction
	return -1
end

commit transaction

return 0
GO
