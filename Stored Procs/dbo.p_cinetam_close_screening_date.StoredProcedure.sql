/****** Object:  StoredProcedure [dbo].[p_cinetam_close_screening_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_close_screening_date]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_close_screening_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO





create proc [dbo].[p_cinetam_close_screening_date] 	@screening_date			datetime,
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
 * delete cinetam_movie_complex_estimates from 6 months ago
 */


/*delete		cinetam_movie_complex_estimates
where		screening_date <= dateadd(wk, -26, @screening_date)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_complex_estimates. Close denied.', 16, 1)
	rollback transaction
	return -1
end*/

/*
 * Delete Exisiting CineTam Movie history
 */

delete	cinetam_movie_history
where	screening_date = @screening_date
and			country_code = @country_code

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_history. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Complex Insertion Phase 1 Insert CineTam Movie History for matching movies in the same week
 */ 

insert		into cinetam_movie_history
select		movie_history.movie_id,
				movie_history.complex_id,
				movie_history.screening_date,
				movie_history.occurence,
				movie_history.print_medium,
				movie_history.three_d_type,
				cinetam_movio_complex_data.cinetam_demographics_id,
				movie_history.country,
				isnull(movie_history.certificate_group,0),
				isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), isnull(child_tickets,0)) / (convert(numeric(38,18), isnull(adult_tickets,0)) + convert(numeric(38,18), isnull(child_tickets,0)))) * convert(numeric(38,18), movie_weighting))) * cinetam_movio_complex_data.weighting),0) as split_attendance,
				cinetam_movio_complex_data.weighting
from		movie_history,
				movie_weekly_ticket_complex_split,
				cinetam_movio_complex_data  
where		movie_history.screening_date = cinetam_movio_complex_data.screening_date
and			movie_history.country = @country_code
and			cinetam_movio_complex_data.country_code  = @country_code
and			movie_history.country = movie_weekly_ticket_complex_split.country_code
and			movie_history.country = cinetam_movio_complex_data.country_code
and			movie_weekly_ticket_complex_split.country_code = cinetam_movio_complex_data.country_code
and			movie_history.movie_id = cinetam_movio_complex_data.movie_id
and			movie_history.movie_id = movie_weekly_ticket_complex_split.movie_id
and			movie_history.screening_date = movie_weekly_ticket_complex_split.screening_date
and			movie_history.screening_date = @screening_date
and			cinetam_movio_complex_data.screening_date = @screening_date
and			movie_history.certificate_group in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and			(isnull(adult_tickets,0) + isnull(child_tickets,0)) <> 0
and			movie_history.complex_id = movie_weekly_ticket_complex_split.complex_id
and			movie_history.complex_id = cinetam_movio_complex_data.complex_id


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end
        
insert		into cinetam_movie_history
select		movie_history.movie_id,
				movie_history.complex_id,
				movie_history.screening_date,
				movie_history.occurence,
				movie_history.print_medium,
				movie_history.three_d_type,
				cinetam_movio_complex_data.cinetam_demographics_id,
				movie_history.country,
				null,
				isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), isnull(child_tickets,0)) / (convert(numeric(38,18), isnull(adult_tickets,0)) + convert(numeric(38,18), isnull(child_tickets,0)))) * convert(numeric(38,18), movie_weighting))) * cinetam_movio_complex_data.weighting),0) as split_attendance,
				cinetam_movio_complex_data.weighting
from		movie_history,
				movie_weekly_ticket_complex_split,
				cinetam_movio_complex_data  
where		movie_history.screening_date = cinetam_movio_complex_data.screening_date
and			movie_history.country =@country_code
and			cinetam_movio_complex_data.country_code  = @country_code
and			movie_history.country = movie_weekly_ticket_complex_split.country_code
and			movie_history.country = cinetam_movio_complex_data.country_code
and			movie_weekly_ticket_complex_split.country_code = cinetam_movio_complex_data.country_code
and			movie_history.movie_id = cinetam_movio_complex_data.movie_id
and			movie_history.movie_id = movie_weekly_ticket_complex_split.movie_id
and			movie_history.screening_date = movie_weekly_ticket_complex_split.screening_date
and			movie_history.screening_date = @screening_date
and			cinetam_movio_complex_data.screening_date = @screening_date
and			movie_history.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and			(isnull(adult_tickets,0) + isnull(child_tickets,0)) <> 0
and			movie_history.complex_id = movie_weekly_ticket_complex_split.complex_id
and			movie_history.complex_id = cinetam_movio_complex_data.complex_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end
        
        
/*
 * Complex Insertion  Phase 2 Insert CineTam Movie History for matching movies not in the same week
 */ 

insert			into cinetam_movie_history
select			movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_temp.cinetam_demographics_id,
					movie_history.country,
					movie_history.certificate_group,
					isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), child_sum) / (convert(numeric(38,18), adult_sum) + convert(numeric(38,18), child_sum))) * convert(numeric(38,18), mov_wgt))) * cinetam_temp.wgt ),0) as split_attendance,
					cinetam_temp.wgt
from			movie_history,
				(	select	ctammovdat.movie_id, 
									cinetam_demographics_id,  
									sum(adult_tickets) as adult_sum, 
									sum(child_tickets) as child_sum, 
									min(movie_weighting)  as mov_wgt, 
									CAST(avg(ctammovdat.weighting) AS DECIMAL(19,17)) / max( tot_weight) AS wgt,
									movie_weekly_ticket_complex_split.complex_id
					from			movie_weekly_ticket_complex_split,
										cinetam_movio_complex_data ctammovdat,
										(select		complex_id, 
															movie_id, 
															cast(sum(avg_weight) as  DECIMAL(19,17)) as tot_weight 
										from			(select		movie_id, 
																				cinetam_demographics_id, 
																				complex_id,
																				avg(weighting) as avg_weight 
															from			cinetam_movio_complex_data 
															where		screening_date < @screening_date
															and				country_code = @country_code
															group by	movie_id,complex_id, 
																				cinetam_demographics_id) as tmp_tbl 
										group by complex_id, movie_id) as temp_table
					where		movie_weekly_ticket_complex_split.screening_date = ctammovdat.screening_date 
					and				ctammovdat.screening_date < @screening_date
					and				ctammovdat.movie_id = temp_table.movie_id 
					and				movie_weekly_ticket_complex_split.country_code = ctammovdat.country_code
					and				movie_weekly_ticket_complex_split.country_code = @country_code
					and				ctammovdat.country_code = @country_code
					and				movie_weekly_ticket_complex_split.movie_id = ctammovdat.movie_id 
					and				ctammovdat.complex_id = temp_table.complex_id
					and				movie_weekly_ticket_complex_split.complex_id = temp_table.complex_id
					and				movie_weekly_ticket_complex_split.complex_id = ctammovdat.complex_id
					group by	ctammovdat.movie_id, cinetam_demographics_id, movie_weekly_ticket_complex_split.complex_id) as cinetam_temp
where		movie_history.country = @country_code
and				movie_history.movie_id = cinetam_temp.movie_id
and				movie_history.complex_id = cinetam_temp.complex_id
and				movie_history.screening_date = @screening_date
and				movie_history.certificate_group in (select certificate_group_id from certificate_group where screening_date = @screening_date and complex_id = movie_history.complex_id)
and				movie_history.movie_id not in (	select		movie_id 
																					from			cinetam_movie_history 
																					where		screening_date = @screening_date 
																					and				country_code = @country_code
																					and				complex_id = movie_history.complex_id)
and			(isnull(adult_sum,0) + isnull(child_sum,0)) <> 0																					
union 
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_temp.cinetam_demographics_id,
					movie_history.country,
					movie_history.certificate_group,
					isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), child_sum) / (convert(numeric(38,18), adult_sum) + convert(numeric(38,18), child_sum))) * convert(numeric(38,18), mov_wgt))) * cinetam_temp.wgt ),0) as split_attendance,
					cinetam_temp.wgt
from			movie_history,
				(	select	ctammovdat.movie_id, 
									cinetam_demographics_id,  
									sum(adult_tickets) as adult_sum, 
									sum(child_tickets) as child_sum, 
									min(movie_weighting)  as mov_wgt, 
									CAST(avg(ctammovdat.weighting) AS DECIMAL(19,17)) / max( tot_weight) AS wgt,
									movie_weekly_ticket_complex_split.complex_id
					from			movie_weekly_ticket_complex_split,
										cinetam_movio_complex_data ctammovdat,
										(select		complex_id, 
															movie_id, 
															cast(sum(avg_weight) as  DECIMAL(19,17)) as tot_weight 
										from			(select		movie_id, 
																				cinetam_demographics_id, 
																				complex_id,
																				avg(weighting) as avg_weight 
															from			cinetam_movio_complex_data 
															where		screening_date < @screening_date
															and				country_code = @country_code
															group by	movie_id,complex_id, 
																				cinetam_demographics_id) as tmp_tbl 
										group by complex_id, movie_id) as temp_table
					where		movie_weekly_ticket_complex_split.screening_date = ctammovdat.screening_date 
					and				ctammovdat.screening_date < @screening_date
					and				ctammovdat.movie_id = temp_table.movie_id 
					and				movie_weekly_ticket_complex_split.country_code = ctammovdat.country_code
					and				movie_weekly_ticket_complex_split.country_code = @country_code
					and				ctammovdat.country_code = @country_code
					and				movie_weekly_ticket_complex_split.movie_id = ctammovdat.movie_id 
					and				ctammovdat.complex_id = temp_table.complex_id
					and				movie_weekly_ticket_complex_split.complex_id = temp_table.complex_id
					and				movie_weekly_ticket_complex_split.complex_id = ctammovdat.complex_id
					group by	ctammovdat.movie_id, cinetam_demographics_id, movie_weekly_ticket_complex_split.complex_id) as cinetam_temp
where		movie_history.country = @country_code
and				movie_history.movie_id = cinetam_temp.movie_id
and				movie_history.complex_id = cinetam_temp.complex_id
and				movie_history.screening_date = @screening_date
and				movie_history.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date and complex_id = movie_history.complex_id)
and				movie_history.movie_id not in (	select		movie_id 
																					from			cinetam_movie_history 
																					where		screening_date = @screening_date 
																					and				country_code = @country_code
																					and				complex_id = movie_history.complex_id)
and			(isnull(adult_sum,0) + isnull(child_sum,0)) <> 0																					


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Phase 1 Insert CineTam Movie History for matching movies in the same week
 */ 

insert		into cinetam_movie_history
select	movie_history.movie_id,
				movie_history.complex_id,
				movie_history.screening_date,
				movie_history.occurence,
				movie_history.print_medium,
				movie_history.three_d_type,
				cinetam_movio_data.cinetam_demographics_id,
				movie_history.country,
				isnull(movie_history.certificate_group,0),
				isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), isnull(child_tickets,0)) / (convert(numeric(38,18), isnull(adult_tickets,0)) + convert(numeric(38,18), isnull(child_tickets,0)))) * convert(numeric(38,18), movie_weighting))) * cinetam_movio_data.weighting),0) as split_attendance,
				cinetam_movio_data.weighting
from		movie_history,
				movie_weekly_ticket_split,
				cinetam_movio_data  
where	movie_history.screening_date = cinetam_movio_data.screening_date
and			movie_history.country = @country_code
and			cinetam_movio_data.country_code  = @country_code
and			movie_history.country = movie_weekly_ticket_split.country_code
and			movie_history.country = cinetam_movio_data.country_code
and			movie_weekly_ticket_split.country_code = cinetam_movio_data.country_code
and			movie_history.movie_id = cinetam_movio_data.movie_id
and			movie_history.movie_id = movie_weekly_ticket_split.movie_id
and			movie_history.screening_date = movie_weekly_ticket_split.screening_date
and			movie_history.screening_date = @screening_date
and			cinetam_movio_data.screening_date = @screening_date
and			movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and			movie_history.certificate_group in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and			(isnull(adult_tickets,0) + isnull(child_tickets,0)) <> 0


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end
        
insert		into cinetam_movie_history
select	movie_history.movie_id,
				movie_history.complex_id,
				movie_history.screening_date,
				movie_history.occurence,
				movie_history.print_medium,
				movie_history.three_d_type,
				cinetam_movio_data.cinetam_demographics_id,
				movie_history.country,
				null,
				isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), isnull(child_tickets,0)) / (convert(numeric(38,18), isnull(adult_tickets,0)) + convert(numeric(38,18), isnull(child_tickets,0)))) * convert(numeric(38,18), movie_weighting))) * cinetam_movio_data.weighting),0) as split_attendance,
				cinetam_movio_data.weighting
from		movie_history,
				movie_weekly_ticket_split,
				cinetam_movio_data  
where	movie_history.screening_date = cinetam_movio_data.screening_date
and			movie_history.country =@country_code
and			cinetam_movio_data.country_code  = @country_code
and			movie_history.country = movie_weekly_ticket_split.country_code
and			movie_history.country = cinetam_movio_data.country_code
and			movie_weekly_ticket_split.country_code = cinetam_movio_data.country_code
and			movie_history.movie_id = cinetam_movio_data.movie_id
and			movie_history.movie_id = movie_weekly_ticket_split.movie_id
and			movie_history.screening_date = movie_weekly_ticket_split.screening_date
and			movie_history.screening_date = @screening_date
and			cinetam_movio_data.screening_date = @screening_date
and			movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and			movie_history.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
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

insert	into cinetam_movie_history
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_temp.cinetam_demographics_id,
					movie_history.country,
					movie_history.certificate_group,
					isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), child_sum) / (convert(numeric(38,18), adult_sum) + convert(numeric(38,18), child_sum))) * convert(numeric(38,18), mov_wgt))) * cinetam_temp.wgt ),0) as split_attendance,
					cinetam_temp.wgt
from			movie_history,
				(	select	ctammovdat.movie_id, 
									cinetam_demographics_id,  
									sum(adult_tickets) as adult_sum, 
									sum(child_tickets) as child_sum, 
									min(movie_weighting)  as mov_wgt, 
									CAST(avg(ctammovdat.weighting) AS DECIMAL(19,17)) / max( tot_weight) AS wgt
					from			movie_weekly_ticket_split,
										cinetam_movio_data ctammovdat,
										(select		movie_id, 
															cast(sum(avg_weight) as  DECIMAL(19,17)) as tot_weight 
										from			(select		movie_id, 
																				cinetam_demographics_id, 
																				avg(weighting) as avg_weight 
															from			cinetam_movio_data 
															where		screening_date < @screening_date
															and				country_code = @country_code
															group by	movie_id, 
																				cinetam_demographics_id) as tmp_tbl 
										group by movie_id) as temp_table
					where		movie_weekly_ticket_split.screening_date = ctammovdat.screening_date 
					and				ctammovdat.screening_date < @screening_date
					and				ctammovdat.movie_id = temp_table.movie_id 
					and				movie_weekly_ticket_split.country_code = ctammovdat.country_code
					and				movie_weekly_ticket_split.country_code = @country_code
					and				ctammovdat.country_code = @country_code
					and				movie_weekly_ticket_split.movie_id = ctammovdat.movie_id 
					group by	ctammovdat.movie_id, cinetam_demographics_id) as cinetam_temp
where		movie_history.country = @country_code
and				movie_history.movie_id = cinetam_temp.movie_id
and				movie_history.screening_date = @screening_date
and				movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and				movie_history.certificate_group in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history.movie_id not in (	select		movie_id 
																					from			cinetam_movie_history 
																					where		screening_date = @screening_date 
																					and				country_code = @country_code)
and			(isnull(adult_sum,0) + isnull(child_sum,0)) <> 0																					
union 
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_temp.cinetam_demographics_id,
					movie_history.country,
					null,
					isnull(((movie_history.attendance - (movie_history.attendance * (convert(numeric(38,18), child_sum) / (convert(numeric(38,18), adult_sum) + convert(numeric(38,18), child_sum))) * convert(numeric(38,18), mov_wgt))) * cinetam_temp.wgt ),0) as split_attendance,
					cinetam_temp.wgt
from			movie_history,
				(	select	ctammovdat.movie_id, 
									cinetam_demographics_id,  
									sum(adult_tickets) as adult_sum, 
									sum(child_tickets) as child_sum, 
									min(movie_weighting)  as mov_wgt, 
									CAST(avg(ctammovdat.weighting) AS DECIMAL(19,17)) / max( tot_weight) AS wgt
					from			movie_weekly_ticket_split,
										cinetam_movio_data ctammovdat,
										(select		movie_id, 
															cast(sum(avg_weight) as  DECIMAL(19,17)) as tot_weight 
										from			(select		movie_id, 
																				cinetam_demographics_id, 
																				avg(weighting) as avg_weight 
															from			cinetam_movio_data 
															where		screening_date < @screening_date
															and				country_code = @country_code
															group by	movie_id, 
																				cinetam_demographics_id) as tmp_tbl 
										group by movie_id) as temp_table
					where		movie_weekly_ticket_split.screening_date = ctammovdat.screening_date 
					and				ctammovdat.screening_date < @screening_date
					and				ctammovdat.movie_id = temp_table.movie_id 
					and				movie_weekly_ticket_split.country_code = ctammovdat.country_code
					and				movie_weekly_ticket_split.country_code = @country_code
					and				ctammovdat.country_code = @country_code
					and				movie_weekly_ticket_split.movie_id = ctammovdat.movie_id 
					group by	ctammovdat.movie_id, cinetam_demographics_id) as cinetam_temp
where		movie_history.country = @country_code
and				movie_history.movie_id = cinetam_temp.movie_id
and				movie_history.screening_date = @screening_date
and				movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and				movie_history.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history.movie_id not in (	select		movie_id 
																					from			cinetam_movie_history 
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
       
insert			into cinetam_movie_history
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history.country,
					movie_history.certificate_group,
					isnull((movie_history.attendance - (movie_history.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					cinetam_demographics.roy_morgan_wgt
from			movie_history,
					cinetam_demographics,
					movie_country
where		movie_history.country = @country_code
and				movie_history.movie_id not  in (select movie_id from cinetam_movie_history where screening_date = @screening_date and country_code = @country_code)
and				movie_history.screening_date = @screening_date
and				movie_history.certificate_group  in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and				movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = @country_code
and				classification_id not in (5,109,110,111,112)
union all
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history.country,
					null,
					isnull((movie_history.attendance - (movie_history.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					cinetam_demographics.roy_morgan_wgt
from			movie_history,
					cinetam_demographics,
					movie_country
where		movie_history.country = @country_code
and				movie_history.movie_id  not in (select movie_id from cinetam_movie_history where screening_date = @screening_date and country_code = @country_code)
and				movie_history.screening_date = @screening_date
and				movie_history.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and				movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = @country_code
and				classification_id not in (5,109,110,111,112)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end        

insert			into cinetam_movie_history
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history.country,
					movie_history.certificate_group,
					isnull((movie_history.attendance - (movie_history.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					cinetam_demographics.roy_morgan_wgt
from			movie_history,
					cinetam_demographics,
					movie_country
where		movie_history.country = @country_code
and				movie_history.movie_id not  in (select movie_id from cinetam_movie_history where screening_date = @screening_date and country_code = @country_code)
and				movie_history.screening_date = @screening_date
and				movie_history.certificate_group  in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and				movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = @country_code
and				classification_id  in (5,109,110,111,112)
union all
select		movie_history.movie_id,
					movie_history.complex_id,
					movie_history.screening_date,
					movie_history.occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					cinetam_demographics.cinetam_demographics_id,
					movie_history.country,
					null,
					isnull((movie_history.attendance - (movie_history.attendance * @kid_variable))  * roy_morgan_wgt, 0) as split_attendance,
					cinetam_demographics.roy_morgan_wgt
from			movie_history,
					cinetam_demographics,
					movie_country
where		movie_history.country = @country_code
and				movie_history.movie_id  not in (select movie_id from cinetam_movie_history where screening_date = @screening_date and country_code = @country_code)
and				movie_history.screening_date = @screening_date
and				movie_history.certificate_group not in (select certificate_group_id from certificate_group where screening_date = @screening_date)
and				movie_history.complex_id not in (select complex_id from cinetam_movio_complex_data where screening_date = @screening_date)
and				movie_country.movie_id = movie_history.movie_id
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
 * Delete cinetam_complex_date_settings
 */ 

delete		cinetam_complex_date_settings 
where		dbo.f_next_attendance_screening_date(@screening_date)  = screening_date
and			complex_id in (select complex_id from v_cinetam_movie_history_reporting_demos where country = @country_code and screening_date = @screening_date)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_complex_date_settings. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Insert next year's Cinetam Complex Date Settings
 */
 
insert into cinetam_complex_date_settings
select		v_ctam_hist.complex_id, 
					dbo.f_next_attendance_screening_date(v_ctam_hist.screening_date) as next_year_screening,
					v_ctam_hist.cinetam_reporting_demographics_id, 
					convert(numeric(10,8), convert(numeric(16,8), sum(v_ctam_hist.attendance))  / convert(numeric(16,8), (select sum(attendance) from v_cinetam_movie_history_reporting_demos where screening_date = v_ctam_hist.screening_date and cinetam_reporting_demographics_id = v_ctam_hist.cinetam_reporting_demographics_id))) as attendance_pecent,
					1,
					1,
					(select movie_target from complex where complex_id = v_ctam_hist.complex_id)
from		v_cinetam_movie_history_reporting_demos v_ctam_hist
where       v_ctam_hist.screening_date = @screening_date
and				country = @country_code
and cinetam_reporting_demographics_id <> 0
group by	complex_id, 
			screening_date, 
			cinetam_reporting_demographics_id
order by 	cinetam_reporting_demographics_id,
            complex_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Failed to Insert Date Settings For Next Year. Close denied.', 16, 1)
	rollback transaction
	return -1
end

insert into cinetam_complex_date_settings
select		v_ctam_hist.complex_id, 
					dbo.f_next_attendance_screening_date(v_ctam_hist.screening_date) as next_year_screening,
					0, 
					convert(numeric(10,8), convert(numeric(16,8), sum(v_ctam_hist.attendance))  / convert(numeric(16,8), (select sum(attendance) from movie_history where screening_date = v_ctam_hist.screening_date))) as attendance_pecent,
					1,
					1,
					(select movie_target from complex where complex_id = v_ctam_hist.complex_id)
from		movie_history v_ctam_hist
where       v_ctam_hist.screening_date = @screening_date
and				country = @country_code
group by	complex_id, 
			screening_date
order by 	complex_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Failed to Insert Date Settings For Next Year. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Delete Exisiting CINEads CineTAM
 */

delete	cinetam_movie_history
where	screening_date = @screening_date
and			country_code = @country_code
and			movie_id = 102

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_history for cineads. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Delete Under 18 tickets from resticted movies
 */

delete	cinetam_movie_history 
where	screening_date = @screening_date
and			country_code = @country_code
and			cinetam_demographics_id in (1,9)
and			movie_id in (select movie_id from movie_country where country_code = @country_code and classification_id in (5,112))

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete cinetam_movie_history for kids seeing under 18 movies. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 *
 */

insert			into availability_demo_matching 
select			v_availability_demo_matching.complex_id,
				v_availability_demo_matching.screening_date,
				v_availability_demo_matching.cinetam_reporting_demographics_id,
				v_availability_demo_matching.attendance_share
from			v_availability_demo_matching 
where			v_availability_demo_matching.screening_date not in (select screening_date from availability_demo_matching)
and				screening_date > '1-jan-2016'

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not create demographic matching history. Close denied.', 16, 1)
	rollback transaction
	return -1
end	

       
/*
 * Close Transaction & Return
 */

commit transaction

return 0
GO
