/****** Object:  StoredProcedure [dbo].[p_cinetam_close_screening_date_weekend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_close_screening_date_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_close_screening_date_weekend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_close_screening_date_weekend] 	@screening_date			datetime,
																								@country_code				char(1)

as

declare		@error												int,
					@attendance_contributors		int,
					@attendance_processed			int,
					@attendance_status					char(1),
					@regional_indicator					char(1),
					@average										numeric(18,6),
					@programmed_average			numeric(18,6),
					@movie_id										int,
					@campaign_no							int,
					@complex_id									int,
					@attendance									int,
					@records										int,
					@cinelight_id									int,
					@showings										int,
					@package_id								int,
					@cinelight_count							int,
					@player_name								varchar(40),
					@days												int,
					@movio_data_exists					int,
					@kid_variable								numeric(18,6)
			
set nocount on

/*
 * Begin Transaction
 */

begin transaction

if @country_code = 'A'
	select @kid_variable = 0.118
else if @country_code = 'Z'
	select @kid_variable = 0.104


/*
 * Delete Exisiting CineTam Movie history
 */

delete		cinetam_movie_history_weekend
where		screening_date = @screening_date
and			country_code = @country_code

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_history_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end


/*
 * Phase 1 Insert CineTam Movie History for matching movies in the same week
 */ 

insert		into cinetam_movie_history_weekend
select		movie_history_weekend.movie_id,
				movie_history_weekend.complex_id,
				movie_history_weekend.screening_date,
				movie_history_weekend.occurence,
				movie_history_weekend.print_medium,
				movie_history_weekend.three_d_type,
				cinetam_movio_data_weekend.cinetam_demographics_id,
				movie_history_weekend.country,
				isnull(movie_history_weekend.certificate_group,0),
				isnull(((movie_history_weekend.attendance - (movie_history_weekend.attendance * (convert(numeric(38,18), isnull(child_tickets,0)) / (convert(numeric(38,18), isnull(adult_tickets,0)) + convert(numeric(38,18), isnull(child_tickets,0)))) * convert(numeric(38,18), movie_weighting))) * cinetam_movio_data_weekend.weighting),0) as split_attendance,
				0,
				cinetam_movio_data_weekend.weighting
from			movie_history_weekend,
				movie_weekly_ticket_split_weekend,
				cinetam_movio_data_weekend  
where		movie_history_weekend.screening_date = cinetam_movio_data_weekend.screening_date
and			movie_history_weekend.country = @country_code
and			cinetam_movio_data_weekend.country_code  = @country_code
and			movie_history_weekend.country = movie_weekly_ticket_split_weekend.country_code
and			movie_history_weekend.country = cinetam_movio_data_weekend.country_code
and			movie_weekly_ticket_split_weekend.country_code = cinetam_movio_data_weekend.country_code
and			movie_history_weekend.movie_id = cinetam_movio_data_weekend.movie_id
and			movie_history_weekend.movie_id = movie_weekly_ticket_split_weekend.movie_id
and			movie_history_weekend.screening_date = movie_weekly_ticket_split_weekend.screening_date
and			movie_history_weekend.screening_date = @screening_date
and			cinetam_movio_data_weekend.screening_date = @screening_date
and			movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and			movie_history_weekend.certificate_group in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and			(isnull(adult_tickets,0) + isnull(child_tickets,0)) <> 0


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end
        
insert		into cinetam_movie_history_weekend
select		movie_history_weekend.movie_id,
				movie_history_weekend.complex_id,
				movie_history_weekend.screening_date,
				movie_history_weekend.occurence,
				movie_history_weekend.print_medium,
				movie_history_weekend.three_d_type,
				cinetam_movio_data_weekend.cinetam_demographics_id,
				movie_history_weekend.country,
				null,
				isnull(((movie_history_weekend.attendance - (movie_history_weekend.attendance * (convert(numeric(38,18), isnull(child_tickets,0)) / (convert(numeric(38,18), isnull(adult_tickets,0)) + convert(numeric(38,18), isnull(child_tickets,0)))) * convert(numeric(38,18), movie_weighting))) * cinetam_movio_data_weekend.weighting),0) as split_attendance,
				0,
				cinetam_movio_data_weekend.weighting
from			movie_history_weekend,
				movie_weekly_ticket_split_weekend,
				cinetam_movio_data_weekend  
where		movie_history_weekend.screening_date = cinetam_movio_data_weekend.screening_date
and			movie_history_weekend.country =@country_code
and			cinetam_movio_data_weekend.country_code  = @country_code
and			movie_history_weekend.country = movie_weekly_ticket_split_weekend.country_code
and			movie_history_weekend.country = cinetam_movio_data_weekend.country_code
and			movie_weekly_ticket_split_weekend.country_code = cinetam_movio_data_weekend.country_code
and			movie_history_weekend.movie_id = cinetam_movio_data_weekend.movie_id
and			movie_history_weekend.movie_id = movie_weekly_ticket_split_weekend.movie_id
and			movie_history_weekend.screening_date = movie_weekly_ticket_split_weekend.screening_date
and			movie_history_weekend.screening_date = @screening_date
and			cinetam_movio_data_weekend.screening_date = @screening_date
and			movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and			movie_history_weekend.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and			(isnull(adult_tickets,0) + isnull(child_tickets,0)) <> 0

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end
        
/*
 * Phase 2 Insert CineTam Movie History for matching movies not in the same week
 */ 

insert	into cinetam_movie_history_weekend
select		movie_history_weekend.movie_id,
					movie_history_weekend.complex_id,
					movie_history_weekend.screening_date,
					movie_history_weekend.occurence,
					movie_history_weekend.print_medium,
					movie_history_weekend.three_d_type,
					cinetam_temp.cinetam_demographics_id,
					movie_history_weekend.country,
					movie_history_weekend.certificate_group,
					isnull(((movie_history_weekend.attendance - (movie_history_weekend.attendance * (convert(numeric(38,18), child_sum) / (convert(numeric(38,18), adult_sum) + convert(numeric(38,18), child_sum))) * convert(numeric(38,18), mov_wgt))) * cinetam_temp.wgt ),0) as split_attendance,
					0,
					cinetam_temp.wgt
from			movie_history_weekend,
				(	select	ctammovdat.movie_id, 
									cinetam_demographics_id,  
									sum(adult_tickets) as adult_sum, 
									sum(child_tickets) as child_sum, 
									min(movie_weighting)  as mov_wgt, 
									CAST(avg(ctammovdat.weighting) AS DECIMAL(19,17)) / max( tot_weight) AS wgt
					from			movie_weekly_ticket_split_weekend,
										cinetam_movio_data_weekend ctammovdat,
										(select		movie_id, 
															cast(sum(avg_weight) as  DECIMAL(19,17)) as tot_weight 
										from			(select		movie_id, 
																				cinetam_demographics_id, 
																				avg(weighting) as avg_weight 
															from			cinetam_movio_data_weekend 
															where		screening_date < @screening_date
															and				country_code = @country_code
															group by	movie_id, 
																				cinetam_demographics_id) as tmp_tbl 
										group by movie_id) as temp_table
					where			movie_weekly_ticket_split_weekend.screening_date = ctammovdat.screening_date 
					and				ctammovdat.screening_date < @screening_date
					and				ctammovdat.movie_id = temp_table.movie_id 
					and				movie_weekly_ticket_split_weekend.country_code = ctammovdat.country_code
					and				movie_weekly_ticket_split_weekend.country_code = @country_code
					and				ctammovdat.country_code = @country_code
					and				movie_weekly_ticket_split_weekend.movie_id = ctammovdat.movie_id 
					group by	ctammovdat.movie_id, cinetam_demographics_id) as cinetam_temp
where			movie_history_weekend.country = @country_code
and				movie_history_weekend.movie_id = cinetam_temp.movie_id
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and				movie_history_weekend.certificate_group in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history_weekend.movie_id not in (	select		movie_id 
																					from			cinetam_movie_history_weekend 
																					where		screening_date = @screening_date 
																					and				country_code = @country_code)
and			(isnull(adult_sum,0) + isnull(child_sum,0)) <> 0																					
union 
select		movie_history_weekend.movie_id,
					movie_history_weekend.complex_id,
					movie_history_weekend.screening_date,
					movie_history_weekend.occurence,
					movie_history_weekend.print_medium,
					movie_history_weekend.three_d_type,
					cinetam_temp.cinetam_demographics_id,
					movie_history_weekend.country,
					null,
					isnull(((movie_history_weekend.attendance - (movie_history_weekend.attendance * (convert(numeric(38,18), child_sum) / (convert(numeric(38,18), adult_sum) + convert(numeric(38,18), child_sum))) * convert(numeric(38,18), mov_wgt))) * cinetam_temp.wgt ),0) as split_attendance,
					0,
					cinetam_temp.wgt
from			movie_history_weekend,
				(	select	ctammovdat.movie_id, 
									cinetam_demographics_id,  
									sum(adult_tickets) as adult_sum, 
									sum(child_tickets) as child_sum, 
									min(movie_weighting)  as mov_wgt, 
									CAST(avg(ctammovdat.weighting) AS DECIMAL(19,17)) / max( tot_weight) AS wgt
					from			movie_weekly_ticket_split_weekend,
										cinetam_movio_data_weekend ctammovdat,
										(select		movie_id, 
															cast(sum(avg_weight) as  DECIMAL(19,17)) as tot_weight 
										from			(select		movie_id, 
																				cinetam_demographics_id, 
																				avg(weighting) as avg_weight 
															from			cinetam_movio_data_weekend 
															where		screening_date < @screening_date
															and				country_code = @country_code
															group by	movie_id, 
																				cinetam_demographics_id) as tmp_tbl 
										group by movie_id) as temp_table
					where		movie_weekly_ticket_split_weekend.screening_date = ctammovdat.screening_date 
					and				ctammovdat.screening_date < @screening_date
					and				ctammovdat.movie_id = temp_table.movie_id 
					and				movie_weekly_ticket_split_weekend.country_code = ctammovdat.country_code
					and				movie_weekly_ticket_split_weekend.country_code = @country_code
					and				ctammovdat.country_code = @country_code
					and				movie_weekly_ticket_split_weekend.movie_id = ctammovdat.movie_id 
					group by	ctammovdat.movie_id, cinetam_demographics_id) as cinetam_temp
where		movie_history_weekend.country = @country_code
and				movie_history_weekend.movie_id = cinetam_temp.movie_id
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and				movie_history_weekend.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history_weekend.movie_id not in (	select		movie_id 
																					from			cinetam_movie_history_weekend 
																					where		screening_date = @screening_date 
																					and				country_code = @country_code)
and			(isnull(adult_sum,0) + isnull(child_sum,0)) <> 0																					

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
* Phase 3 - Insert Splits for any movie that has never been in cinetam ticket purchase history
*/ 
       
insert			into cinetam_movie_history_weekend
select		movie_history_weekend.movie_id,
					movie_history_weekend.complex_id,
					movie_history_weekend.screening_date,
					movie_history_weekend.occurence,
					movie_history_weekend.print_medium,
					movie_history_weekend.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history_weekend.country,
					movie_history_weekend.certificate_group,
					isnull((movie_history_weekend.attendance - (movie_history_weekend.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					0,
					cinetam_demographics.roy_morgan_wgt
from			movie_history_weekend,
					cinetam_demographics,
					movie_country
where		movie_history_weekend.country = @country_code
and				movie_history_weekend.movie_id not  in (select movie_id from cinetam_movie_history_weekend where screening_date = @screening_date and country_code = @country_code)
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.certificate_group  in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and				movie_country.movie_id = movie_history_weekend.movie_id
and				movie_country.country_code = @country_code
and				classification_id not in (5,109,110,111,112)
union all
select		movie_history_weekend.movie_id,
					movie_history_weekend.complex_id,
					movie_history_weekend.screening_date,
					movie_history_weekend.occurence,
					movie_history_weekend.print_medium,
					movie_history_weekend.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history_weekend.country,
					null,
					isnull((movie_history_weekend.attendance - (movie_history_weekend.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					0,
					cinetam_demographics.roy_morgan_wgt
from			movie_history_weekend,
					cinetam_demographics,
					movie_country
where		movie_history_weekend.country = @country_code
and				movie_history_weekend.movie_id  not in (select movie_id from cinetam_movie_history_weekend where screening_date = @screening_date and country_code = @country_code)
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and				movie_country.movie_id = movie_history_weekend.movie_id
and				movie_country.country_code = @country_code
and				classification_id not in (5,109,110,111,112)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end        

insert			into cinetam_movie_history_weekend
select		movie_history_weekend.movie_id,
					movie_history_weekend.complex_id,
					movie_history_weekend.screening_date,
					movie_history_weekend.occurence,
					movie_history_weekend.print_medium,
					movie_history_weekend.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history_weekend.country,
					movie_history_weekend.certificate_group,
					isnull((movie_history_weekend.attendance - (movie_history_weekend.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					0,
					cinetam_demographics.roy_morgan_wgt
from			movie_history_weekend,
					cinetam_demographics,
					movie_country
where		movie_history_weekend.country = @country_code
and				movie_history_weekend.movie_id not  in (select movie_id from cinetam_movie_history_weekend where screening_date = @screening_date and country_code = @country_code)
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.certificate_group  in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and				movie_country.movie_id = movie_history_weekend.movie_id
and				movie_country.country_code = @country_code
and				classification_id  in (5,109,110,111,112)
union all
select		movie_history_weekend.movie_id,
					movie_history_weekend.complex_id,
					movie_history_weekend.screening_date,
					movie_history_weekend.occurence,
					movie_history_weekend.print_medium,
					movie_history_weekend.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history_weekend.country,
					null,
					isnull((movie_history_weekend.attendance - (movie_history_weekend.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					0,
					cinetam_demographics.roy_morgan_wgt
from			movie_history_weekend,
					cinetam_demographics,
					movie_country
where		movie_history_weekend.country = @country_code
and				movie_history_weekend.movie_id  not in (select movie_id from cinetam_movie_history_weekend where screening_date = @screening_date and country_code = @country_code)
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history_weekend.complex_id not in (select complex_id from cinetam_movio_complex_data_weekend where screening_date = @screening_date)
and				movie_country.movie_id = movie_history_weekend.movie_id
and				movie_country.country_code = @country_code
and				classification_id  in (5,109,110,111,112)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end        

/*
 * Delete Exisiting CINEads CineTAM
 */

delete	cinetam_movie_history_weekend
where	screening_date = @screening_date
and			country_code = @country_code
and			movie_id = 102

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_history_weekend for cineads. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Delete Under 18 tickets from resticted movies
 */

delete		cinetam_movie_history_weekend 
where		screening_date = @screening_date
and			country_code = @country_code
and			cinetam_demographics_id in (1,9)
and			movie_id in (select movie_id from movie_country where country_code = @country_code and classification_id in (5,112))

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_history_weekend for kids seeing under 18 movies. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Close Transaction & Return
 */

commit transaction
return 0
GO
