USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_close_campaigns_weekend]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_cinetam_close_campaigns_weekend] 	

				@mode int
				,@arg_screening_date		datetime
				--@country_code char(1)
as

declare		@error												int
			
set nocount on

declare		@screening_date		datetime
					
declare		screening_date_csr cursor for				
select			distinct screening_date 
from			cinetam_movie_history_weekend 
where			isnull(attendance,0) <> 0 
and				screening_date >= '10-may-2012'
--and						screening_date between '5-sep-2019' and '9-jan-2020'
--and			country = @country_code
and				((@mode = 1
and				screening_date not in (select distinct screening_date from cinetam_campaign_actuals_weekend))-- where country_code = @country_code))
or					(@mode = 2
and				screening_date = @arg_screening_date)
or					(@mode = 3))
order by		screening_date DESC

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@FETCH_STATUS=0)
begin

    print 'PROCESSING'
	print @screening_date

	/*
	 * Begin Transaction
	 */

	begin transaction

	/*
	 * Delete CineTam Campaign actuals
	 */

	delete	cinetam_campaign_actuals_weekend
	where	screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete cinetam_campaign_actuals_weekend. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	cinetam_campaign_complex_actuals_weekend
	where	screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete cinetam_campaign_complex_actuals_weekend. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	cinetam_attendance_campaign_tracking_weekend
	where	screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete cinetam_attendance_campaign_tracking_weekend. Close denied.', 16, 1)
		rollback transaction
		return -1
	end
	

	/*
	 * Generate Campaign Level CineTam 
	 */

	insert into	cinetam_campaign_actuals_weekend
	(	campaign_no, cinetam_demographics_id, screening_date, attendance
	)
	select 			film_campaign.campaign_no,
						cinetam_movie_history_weekend.cinetam_demographics_id,
						cinetam_movie_history_weekend.screening_date,
						sum(cinetam_movie_history_weekend.attendance) as attendance
	from			film_campaign,
						movie_history_weekend,
						v_certificate_item_distinct,
						campaign_spot,
						cinetam_movie_history_weekend
	where			film_campaign.campaign_no = campaign_spot.campaign_no
	and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
	and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
	and				movie_history_weekend.attendance is not null
	and				movie_history_weekend.attendance > 0 
	and				movie_history_weekend.country = cinetam_movie_history_weekend.country_code 
	and				campaign_spot.screening_date = @screening_date
	and				movie_history_weekend.screening_date = @screening_date
	and				movie_history_weekend.complex_id = cinetam_movie_history_weekend.complex_id
	and				movie_history_weekend.movie_id = cinetam_movie_history_weekend.movie_id
	and				movie_history_weekend.screening_date = cinetam_movie_history_weekend.screening_date
	and				movie_history_weekend.occurence = cinetam_movie_history_weekend.occurence
	and				movie_history_weekend.print_medium = cinetam_movie_history_weekend.print_medium
	and				movie_history_weekend.three_d_type = cinetam_movie_history_weekend.three_d_type
	group by 	film_campaign.campaign_no,
						cinetam_movie_history_weekend.cinetam_demographics_id,
						cinetam_movie_history_weekend.screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Generate Campaign Actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	/*
	 * Generate Campaign & Complex Level CineTam 
	 */

/*
	insert into	cinetam_campaign_complex_actuals_weekend
	(campaign_no, complex_id, movie_id, cinetam_demographics_id, screening_date, attendance)
	select 		film_campaign.campaign_no,
						movie_history_weekend.complex_id,
						movie_history_weekend.movie_id,
						cinetam_movie_history_weekend.cinetam_demographics_id,
						cinetam_movie_history_weekend.screening_date,
						sum(cinetam_movie_history_weekend.attendance) as attendance
	from			film_campaign,
						movie_history_weekend,
						v_certificate_item_distinct,
						campaign_spot,
						cinetam_movie_history_weekend
	where			film_campaign.campaign_no = campaign_spot.campaign_no
	and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
	and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
	and				movie_history_weekend.attendance is not null
	and				movie_history_weekend.attendance > 0 
	and				campaign_spot.screening_date = @screening_date
	and				movie_history_weekend.screening_date = @screening_date
	and				movie_history_weekend.complex_id = cinetam_movie_history_weekend.complex_id
	and				movie_history_weekend.movie_id = cinetam_movie_history_weekend.movie_id
	and				movie_history_weekend.screening_date = cinetam_movie_history_weekend.screening_date
	and				movie_history_weekend.occurence = cinetam_movie_history_weekend.occurence
	and				movie_history_weekend.print_medium = cinetam_movie_history_weekend.print_medium
	and				movie_history_weekend.three_d_type = cinetam_movie_history_weekend.three_d_type
	group by 	film_campaign.campaign_no,
						movie_history_weekend.complex_id,
						movie_history_weekend.movie_id,
						cinetam_movie_history_weekend.cinetam_demographics_id,
						cinetam_movie_history_weekend.screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Generate Campaign Actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	update			cinetam_campaign_actuals_weekend
	set					unique_transactions = temp_table.movio_unique_transactions,
							unique_people = temp_table.movio_unique_people
	from				(	select 				v_cinetam_campaign_post_analysis_weekend.campaign_no,
														v_movio_data_post_analysis_weekend.screening_date,
														v_cinetam_campaign_post_analysis_weekend.cinetam_demographics_id, 
														sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
														sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
								from				v_movio_data_post_analysis_weekend,
														v_cinetam_campaign_post_analysis_weekend,
														cinetam_campaign_settings
								where				v_movio_data_post_analysis_weekend.country_code = 'A'
								and					v_cinetam_campaign_post_analysis_weekend.country_code = 'A'
								and					v_movio_data_post_analysis_weekend.country_code = v_cinetam_campaign_post_analysis_weekend.country_code
								and					v_cinetam_campaign_post_analysis_weekend.campaign_no = cinetam_campaign_settings.campaign_no
								and					v_movio_data_post_analysis_weekend.cinetam_demographics_id = v_cinetam_campaign_post_analysis_weekend.cinetam_demographics_id
								and					v_movio_data_post_analysis_weekend.complex_id = v_cinetam_campaign_post_analysis_weekend.complex_id
								and					v_movio_data_post_analysis_weekend.movie_code = v_cinetam_campaign_post_analysis_weekend.movie_code
								and					v_movio_data_post_analysis_weekend.screening_date = v_cinetam_campaign_post_analysis_weekend.screening_date
								and					v_movio_data_post_analysis_weekend.screening_date = @screening_date
										group by		v_cinetam_campaign_post_analysis_weekend.campaign_no,
														v_movio_data_post_analysis_weekend.screening_date,
														v_cinetam_campaign_post_analysis_weekend.cinetam_demographics_id) as temp_table
	where	cinetam_campaign_actuals_weekend.campaign_no = temp_table.campaign_no
	and			cinetam_campaign_actuals_weekend.screening_date = temp_table.screening_date
	and			cinetam_campaign_actuals_weekend.cinetam_demographics_id = temp_table.cinetam_demographics_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update actual unique trans aus. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	update			cinetam_campaign_actuals_weekend
	set					unique_transactions = temp_table.movio_unique_transactions,
							unique_people = temp_table.movio_unique_people
	from				(	select 			v_cinetam_campaign_post_analysis_weekend.campaign_no,
														v_movio_data_post_analysis_weekend.screening_date,
														v_cinetam_campaign_post_analysis_weekend.cinetam_demographics_id, 
														sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
														sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
								from				v_movio_data_post_analysis_weekend,
														v_cinetam_campaign_post_analysis_weekend,
														cinetam_campaign_settings
								where			v_movio_data_post_analysis_weekend.country_code = 'Z'
								and					v_cinetam_campaign_post_analysis_weekend.country_code = 'Z'
								and					v_movio_data_post_analysis_weekend.country_code = v_cinetam_campaign_post_analysis_weekend.country_code
								and					v_cinetam_campaign_post_analysis_weekend.campaign_no = cinetam_campaign_settings.campaign_no
								and					v_movio_data_post_analysis_weekend.cinetam_demographics_id = v_cinetam_campaign_post_analysis_weekend.cinetam_demographics_id
								and					v_movio_data_post_analysis_weekend.complex_id = v_cinetam_campaign_post_analysis_weekend.complex_id
								and					v_movio_data_post_analysis_weekend.movie_code = v_cinetam_campaign_post_analysis_weekend.movie_code
								and					v_movio_data_post_analysis_weekend.screening_date = v_cinetam_campaign_post_analysis_weekend.screening_date
								and					v_movio_data_post_analysis_weekend.screening_date = @screening_date
										group by		v_cinetam_campaign_post_analysis_weekend.campaign_no,
														v_movio_data_post_analysis_weekend.screening_date,
														v_cinetam_campaign_post_analysis_weekend.cinetam_demographics_id) as temp_table
	where	cinetam_campaign_actuals_weekend.campaign_no = temp_table.campaign_no
	and			cinetam_campaign_actuals_weekend.screening_date = temp_table.screening_date
	and			cinetam_campaign_actuals_weekend.cinetam_demographics_id = temp_table.cinetam_demographics_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update actual unique trans nz. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	insert into		cinetam_attendance_campaign_tracking_weekend
	select				campaign_spot.campaign_no, 
							cinetam_movie_history_weekend.screening_date, 
							campaign_spot.spot_type, 
							cinetam_demographics_id,
							isnull(sum(attendance),0) as attendance,
							count(distinct spot_id)
	from 				cinetam_movie_history_weekend,
							v_certificate_item_distinct,
							campaign_spot
	where				cinetam_movie_history_weekend.certificate_group_id = v_certificate_item_distinct.certificate_group
	and					v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
	and					cinetam_movie_history_weekend.screening_date = @screening_date
	and					campaign_spot.screening_date = cinetam_movie_history_weekend.screening_date
	group by			campaign_spot.campaign_no, 
							cinetam_movie_history_weekend.screening_date, 
							campaign_spot.spot_type, 
							cinetam_demographics_id
							
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update cinetam_attendance_campaign_tracking. Close denied.', 16, 1)
		rollback transaction
		return -1
	end
*/	
	/*
	 * Commit & Return
	 */

	commit transaction
	fetch screening_date_csr into @screening_date
end

return 0
GO
