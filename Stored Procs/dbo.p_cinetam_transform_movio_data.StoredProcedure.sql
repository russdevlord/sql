/****** Object:  StoredProcedure [dbo].[p_cinetam_transform_movio_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_transform_movio_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_transform_movio_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_cinetam_transform_movio_data]		@screening_date		datetime,
																									@country_code			char(1)

as

declare		@error														int,
					@cinetam_demographics_id					int,
					@gender														char(1),
					@min_age													int,
					@max_age													int,
					@data_provider_id									int,
					@movie_weighting										numeric(38,30)
					
set nocount on

declare		cinetam_demographics_csr cursor for 
select			cinetam_demographics_id,
					gender,
					min_age,
					max_age
from			cinetam_demographics
order by	gender DESC,
					min_age
					
if @country_code = 'A'
begin
	select	@data_provider_id = 1,
			@movie_weighting = 0.1--@movie_weighting = 0.42 13.58%

end
else if @country_code = 'Z'
begin
	select	@data_provider_id = 4,
			@movie_weighting = 0.05 --@movie_weighting = 0.45 12.58%
end

/*
 * Begin Transaction
 */ 					

begin transaction

/*
 * Delete Any Existing Data
 */
  
delete	cinetam_movio_data
where	screening_date = @screening_date
and			country_code = @country_code


select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Deleting old movio data', 16, 1)
	return -1
end

open cinetam_demographics_csr
fetch cinetam_demographics_csr into @cinetam_demographics_id, @gender, @min_age,@max_age
while(@@FETCH_STATUS=0)
begin

	insert			into cinetam_movio_data
	select		@screening_date,
						@cinetam_demographics_id,
						movie_id,
						movio_data.country_code, 
						(cinetam_weightings.weighting * SUM(unique_transactions)),
						cinetam_weightings.weighting,
						SUM(unique_transactions),
						(select	SUM(unique_transactions) 
						from		movio_data md,data_translate_movie dtm  
						where	md.real_age between 14 and 100 
						and			dtm.data_provider_id = @data_provider_id 
						and			(UPPER(LEFT(gender, 1)) = 'F' 
						or			UPPER(LEFT(gender, 1))  = 'M')
						and			md.session_time between @screening_date and  dateadd(ss, -1, dateadd(wk, 1, @screening_date)) 
						and			md.movie_code = dtm.movie_code 
						and			dtm.movie_id = data_translate_movie.movie_id
						and			country_code = @country_code),
						0.0,
						0.0,
						0.0
	from			movio_data,
						data_translate_movie,
						cinetam_weightings
	where		data_translate_movie.data_provider_id = @data_provider_id
	and				movio_data.movie_code = data_translate_movie.movie_code
	and				session_time between @screening_date and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))
	and				UPPER(LEFT(gender, 1)) = UPPER(@gender)
	and				real_age between @min_age and @max_age
	and				cinetam_weightings.cinetam_demographics_id = @cinetam_demographics_id
	and				cinetam_weightings.screening_date = @screening_date
	and				movio_data.country_code = @country_code
	and				movio_data.country_code = cinetam_weightings.country_code
	and				cinetam_weightings.country_code = @country_code
	group by	movie_id,
						cinetam_weightings.weighting,
						movio_data.country_code
	
	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movio data', 16, 1)
		return -1
	end

	fetch cinetam_demographics_csr into @cinetam_demographics_id, @gender, @min_age,@max_age
end

update	cinetam_movio_data
set			total_movie_calc_wgt = (select	SUM(cmd.calculated_weighting) 
																from		cinetam_movio_data cmd 
																where	cmd.screening_date = cinetam_movio_data.screening_date 
																and			country_code = @country_code
																and			cmd.movie_id = cinetam_movio_data.movie_id ),
				weighting							= convert(numeric(38,30),CONVERT(numeric(23,15), calculated_weighting) / convert(numeric(23,15),	(	select	SUM(cmd.calculated_weighting) 
																																																																	from		cinetam_movio_data cmd 
																																																																	where	country_code = @country_code
																																																																	and			cmd.screening_date = cinetam_movio_data.screening_date 
																																																																	and			cmd.movie_id = cinetam_movio_data.movie_id )))												
where		screening_date = @screening_date
and				country_code = @country_code

select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Updating total weights in translated movio data', 16, 1)
	return -1
end

/*
 * Store Weekly Movie Adult/Child Ticket splits
 */

delete	movie_weekly_ticket_split
where	screening_date = @screening_date
and			country_code = @country_code

select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Deleting old movie weekly ticket data', 16, 1)
	return -1
end

/*if @country_code = 'A'
begin*/
	insert into		movie_weekly_ticket_split
	select				mh_movies.movie_id,
							@screening_date,
							isnull(sum(movie_weekly_ticket_split.adult_tickets),0),
							isnull(sum(movie_weekly_ticket_split.child_tickets),0),
							@movie_weighting,
							@country_code
	from					(select			distinct	movie_id ,
												country
							from				movie_history 
							where			country = @country_code
							and				screening_date = @screening_date) as mh_movies
	inner join			v_cinetam_matched_movie		on mh_movies.movie_id = v_cinetam_matched_movie.current_movie_id 
																			and mh_movies.country = v_cinetam_matched_movie.country_code
	inner join			movie_weekly_ticket_split		on v_cinetam_matched_movie.matched_movie_id = movie_weekly_ticket_split.movie_id 
																			and v_cinetam_matched_movie.country_code = movie_weekly_ticket_split.country_code 
																			and dateadd(wk, datediff(wk, v_cinetam_matched_movie.current_release_date, @screening_date), matched_release_date) = movie_weekly_ticket_split.screening_date
	group by			mh_movies.movie_id
	having				isnull(sum(movie_weekly_ticket_split.adult_tickets),0) + isnull(sum(movie_weekly_ticket_split.child_tickets),0) <> 0

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 1', 16, 1)
		return -1
	end

	insert into  movie_weekly_ticket_split
	select		movie_id,
						@screening_date,
				 		(select		isnull(sum(adult_tickets / 10000),0)
						from			movie_weekly_ticket_split
						where		movie_id = movie_history.movie_id
						and			country_code = @country_code
						and			movie_weekly_ticket_split.screening_date <= dateadd(wk, 1, @screening_date)),
						(select		isnull(sum(child_tickets / 10000),0)
						from			movie_weekly_ticket_split
						where		movie_id = movie_history.movie_id
						and			country_code = @country_code
						and			movie_weekly_ticket_split.screening_date <= dateadd(wk, 1, @screening_date)),
						@movie_weighting,
						country
		from			movie_history
		where		movie_id not in (select movie_id from movie_weekly_ticket_split where screening_date = @screening_date and country_code = @country_code)
		and			screening_date = @screening_date
		and			country = @country_code
		and			movie_id in (select	distinct movie_id
												from		movio_data,
																data_translate_movie
												where	data_translate_movie.data_provider_id = @data_provider_id
												and			movio_data.movie_code = data_translate_movie.movie_code
												and			movie_id = movie_history.movie_id
												and			country_code = @country_code
												and			real_age between 14 and 100)
		group by	movie_id, country

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 2', 16, 1)
		return -1
	end

	insert into	movie_weekly_ticket_split
	select			movie_id,
						@screening_date,
 						(select		isnull(sum(adult_tickets/10000),0)
						from			movie_weekly_ticket_split
						where		country_code = @country_code
						and			movie_weekly_ticket_split.screening_date between dateadd(wk, -51, @screening_date) and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))),
 						(select		isnull(sum(child_tickets/10000),0)
						from			movie_weekly_ticket_split
						where		country_code = @country_code
						and			movie_weekly_ticket_split.screening_date between dateadd(wk, -51, @screening_date) and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))),
						@movie_weighting,
						country
		from		movie_history
		where	movie_id not in (select movie_id from movie_weekly_ticket_split where screening_date = @screening_date and country_code = @country_code)
		and			screening_date = @screening_date
		and			country = @country_code
		group by	movie_id, country

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 3', 16, 1)
		return -1
	end
/*end
else
begin
	insert into		movie_weekly_ticket_split
	select				movie_id,
							@screening_date,
							isnull(sum(adult_tickets),0),
							isnull(sum(child_tickets),0),
							@movie_weighting,
							country_code
		from				movio_data,
							data_translate_movie
		where			data_translate_movie.data_provider_id = @data_provider_id
		and				movio_data.country_code = @country_code
		and				movio_data.movie_code = data_translate_movie.movie_code
		and				session_time between @screening_date and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))
		and				real_age between 14 and 100
		group by	movie_id, country_code

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 1', 16, 1)
		return -1
	end

	insert into  movie_weekly_ticket_split
	select		movie_id,
						@screening_date,
						(select	isnull(sum(adult_tickets),0)
						from		movio_data,
										data_translate_movie
						where	data_translate_movie.data_provider_id = @data_provider_id
						and			movio_data.movie_code = data_translate_movie.movie_code
						and			movie_id = movie_history.movie_id
						and			country_code = @country_code
						and			movio_data.session_time <= dateadd(wk, 1, @screening_date)
						and			real_age between 14 and 100),
						(select	isnull(sum(child_tickets),0)
						from		movio_data,
										data_translate_movie
						where	data_translate_movie.data_provider_id = @data_provider_id
						and			movio_data.movie_code = data_translate_movie.movie_code
						and			movie_id = movie_history.movie_id
						and			country_code = @country_code
						and			movio_data.session_time <= dateadd(wk, 1, @screening_date)
						and			real_age between 14 and 100),
						@movie_weighting,
						country
		from		movie_history
		where	movie_id not in (select movie_id from movie_weekly_ticket_split where screening_date = @screening_date and country_code = @country_code)
		and			screening_date = @screening_date
		and			country = @country_code
		and			movie_id in (select	distinct movie_id
												from		movio_data,
																data_translate_movie
												where	data_translate_movie.data_provider_id = @data_provider_id
												and			movio_data.movie_code = data_translate_movie.movie_code
												and			movie_id = movie_history.movie_id
												and			country_code = @country_code
												and			real_age between 14 and 100)
		group by	movie_id, country

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 2', 16, 1)
		return -1
	end

	insert into  movie_weekly_ticket_split
	select		movie_id,
						@screening_date,
						(select	sum(adult_tickets)
						from		movio_data
						where	country_code = @country_code
						and			session_time between dateadd(wk, -51, @screening_date) and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))
						and			real_age between 14 and 100),
						(select	sum(child_tickets)
						from		movio_data
						where	country_code = @country_code
						and			session_time between  dateadd(wk, -51, @screening_date) and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))
						and			real_age between 14 and 100),
						@movie_weighting,
						country
		from		movie_history
		where	movie_id not in (select movie_id from movie_weekly_ticket_split where screening_date = @screening_date and country_code = @country_code)
		and			screening_date = @screening_date
		and			country = @country_code
		group by	movie_id, country

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 3', 16, 1)
		return -1
	end
end*/

if @country_code = 'Z'
begin
	update movie_weekly_ticket_split
	set	child_tickets = child_tickets * 0.7
	where screening_date = @screening_date
	and country_code = @country_code

	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movie weekly ticket data part 3', 16, 1)
		return -1
	end
end

commit transaction
return 0
GO
