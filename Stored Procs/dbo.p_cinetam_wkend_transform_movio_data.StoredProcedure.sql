/****** Object:  StoredProcedure [dbo].[p_cinetam_wkend_transform_movio_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_wkend_transform_movio_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_wkend_transform_movio_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_cinetam_wkend_transform_movio_data]		@screening_date datetime, 
																													@country_code char(1)

as

declare		@error													int,
					@cinetam_demographics_id				int,
					@gender													char(1),
					@min_age												int,
					@max_age												int,
					@data_provider_id								int,
					@movie_weighting									numeric(38,30)
					
set nocount on

declare		cinetam_demographics_csr cursor for 
select			cinetam_demographics_id,
					gender,
					min_age,
					max_age
from			cinetam_demographics
order by		gender DESC,
					min_age
			
if @country_code = 'A'
begin
	select		@data_provider_id = 1,
					@movie_weighting = 0.35

end
else if @country_code = 'Z'
begin
	select		@data_provider_id = 4,
					@movie_weighting = 0.45
end			

begin transaction

delete			cinetam_wkend_movio_data
where			screening_date = @screening_date
and				country_code = @country_code

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

	insert	into	cinetam_wkend_movio_data
	select			@screening_date,
						@cinetam_demographics_id,
						movie_id,
						movio_wkend_data.country_code, 
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
	from			movio_wkend_data,
						data_translate_movie,
						cinetam_weightings
	where			data_translate_movie.data_provider_id = @data_provider_id
	and				movio_wkend_data.movie_code = data_translate_movie.movie_code
	and				session_time between @screening_date and  dateadd(ss, -1, dateadd(wk, 1, @screening_date))
	and				UPPER(LEFT(gender, 1)) = UPPER(@gender)
	and				real_age between @min_age and @max_age
	and				cinetam_weightings.cinetam_demographics_id = @cinetam_demographics_id
	and				cinetam_weightings.screening_date = @screening_date
	and				movio_wkend_data.country_code = @country_code
	and				movio_wkend_data.country_code = cinetam_weightings.country_code
	and				cinetam_weightings.country_code = @country_code
	group by	movie_id,
						cinetam_weightings.weighting,
						movio_wkend_data.country_code
						
						
	select @error = @@ERROR
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error Inserting movio data', 16, 1)
		return -1
	end

	fetch cinetam_demographics_csr into @cinetam_demographics_id, @gender, @min_age,@max_age
end

update	cinetam_wkend_movio_data
set			total_movie_calc_wgt = (select	SUM(cmd.calculated_weighting) 
																from		cinetam_wkend_movio_data cmd 
																where	cmd.screening_date = cinetam_wkend_movio_data.screening_date 
																and			country_code = @country_code
																and			cmd.movie_id = cinetam_wkend_movio_data.movie_id ),
				weighting							= convert(numeric(38,30),CONVERT(numeric(23,15), calculated_weighting) / convert(numeric(23,15),	(	select	SUM(cmd.calculated_weighting) 
																																																																	from		cinetam_wkend_movio_data cmd 
																																																																	where	country_code = @country_code
																																																																	and			cmd.screening_date = cinetam_wkend_movio_data.screening_date 
																																																																	and			cmd.movie_id = cinetam_wkend_movio_data.movie_id )))												
where		screening_date = @screening_date
and			country_code = @country_code

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

delete movie_wkend_ticket_split
where screening_date = @screening_date
and country_code = @country_code

select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Deleting old movie WeekEnd ticket data', 16, 1)
	return -1
end

insert into  movie_wkend_ticket_split
select		movie_id,
				@screening_date,
				country_code,
				isnull(sum(adult_tickets),0),
				isnull(sum(child_tickets),0),
				@movie_weighting
from		movio_wkend_data,
				data_translate_movie
where		data_translate_movie.data_provider_id  = @data_provider_id
and			movio_wkend_data.movie_code = data_translate_movie.movie_code
and			session_time between @screening_date and  dateadd(ss, -1, dateadd(DAY, 4, @screening_date))
and			real_age between 14 and 100
and			country_code = @country_code
group by	movie_id, country_code

select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Inserting movie Wekeend ticket data part 1', 16, 1)
	return -1
end

insert into  movie_wkend_ticket_split
select		movie_id,
			@screening_date,
			country,
			(select	isnull(sum(adult_tickets),0)
			from		movio_wkend_data,
							data_translate_movie
			where		data_translate_movie.data_provider_id in (1,4)
			and			movio_wkend_data.movie_code = data_translate_movie.movie_code
			and			movie_id = movie_history.movie_id
			and			movio_wkend_data.session_time <= dateadd(DAY, 4, @screening_date)
			and			real_age between 14 and 100
			and			movio_wkend_data.country_code = @country_code),
			(select	isnull(sum(child_tickets),0)
			from		movio_wkend_data,
							data_translate_movie
			where		data_translate_movie.data_provider_id in (1,4)
			and			movio_wkend_data.movie_code = data_translate_movie.movie_code
			and			movie_id = movie_history.movie_id
			and			movio_wkend_data.session_time <= dateadd(DAY, 4, @screening_date)
			and			real_age between 14 and 100
			and			movio_wkend_data.country_code = @country_code),
			@movie_weighting
from		movie_history
where		movie_id not in (select movie_id from movie_wkend_ticket_split where screening_date = @screening_date and movie_wkend_ticket_split.country_code = @country_code)
and			screening_date = @screening_date
and			movie_id in (select	distinct movie_id
						from		movio_wkend_data,
										data_translate_movie
						where		data_translate_movie.data_provider_id in (1,4)
						and			movio_wkend_data.movie_code = data_translate_movie.movie_code
						and			movie_id = movie_history.movie_id
						and			real_age between 14 and 100
						and			movio_wkend_data.country_code = @country_code)
and movie_history.country = @country_code						
group by	movie_id, country

select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Inserting movie weekly ticket data part 2', 16, 1)
	return -1
end

insert into  movie_wkend_ticket_split
select		movie_id,
			@screening_date,
			country,
			(select	isnull(sum(adult_tickets),0)
			from		movio_wkend_data,
							data_translate_movie
			where		data_translate_movie.data_provider_id in (1,4)
			and			movio_wkend_data.movie_code = data_translate_movie.movie_code
			and			session_time between @screening_date and  dateadd(ss, -1, dateadd(DAY, 4, @screening_date))
			and			real_age between 14 and 100
			and			movio_wkend_data.country_code = @country_code),
			(select	isnull(sum(child_tickets),0)
			from		movio_wkend_data,
							data_translate_movie
			where		data_translate_movie.data_provider_id in (1,4)
			and			movio_wkend_data.movie_code = data_translate_movie.movie_code
			and			session_time between @screening_date and  dateadd(ss, -1, dateadd(DAY, 4, @screening_date))
			and			real_age between 14 and 100
			and			movio_wkend_data.country_code = @country_code),
			@movie_weighting
from		movie_history
where		movie_id not in (select movie_id from movie_wkend_ticket_split where screening_date = @screening_date)
and			screening_date = @screening_date
and			movie_history.country = @country_code
group by	movie_id, country

select @error = @@ERROR
if @error <> 0
begin
	rollback transaction
	raiserror ('Error Inserting movie weekly ticket data part 3', 16, 1)
	return -1
end

commit transaction
return 0

GRANT EXECUTE ON dbo.p_cinetam_wkend_transform_movio_data TO public
GO
