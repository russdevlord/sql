/****** Object:  StoredProcedure [dbo].[p_cinetam_close_campaigns]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_close_campaigns]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_close_campaigns]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_cinetam_close_campaigns] 	

				@mode int
				,@arg_screening_date		datetime
				--@country_code char(1)
as

declare		@error												int
			
set nocount on



declare		@screening_date		datetime
					
declare				screening_date_csr cursor for				
select				distinct screening_date 
from					cinetam_movie_history 
where				isnull(attendance,0) <> 0 
and						screening_date > '1-jan-2012'
--and						country = @country_code
and						((@mode = 1
and						screening_date not in (select distinct screening_date from cinetam_campaign_actuals))-- where country_code = @country_code))
or						(@mode = 2
and						screening_date = @arg_screening_date)
or						(@mode = 3))
order by screening_date DESC

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

	delete	cinetam_campaign_actuals
	where	screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete cinetam_campaign_actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	cinetam_campaign_complex_actuals
	where	screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete cinetam_campaign_complex_actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	cinetam_attendance_campaign_tracking
	where	screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete cinetam_attendance_campaign_tracking. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	inclusion_cinetam_attendance
	where	screening_date = @screening_date
	
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete inclusion_cinetam_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	inclusion_cinetam_complex_attendance
	where screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete inclusion_cinetam_complex_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end	

	delete	cinetam_cinelight_attendance
	where	screening_date = @screening_date
	
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete inclusion_cinetam_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	delete	cinetam_cinelight_complex_attendance
	where screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Delete inclusion_cinetam_complex_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end	

	/*
	 * Generate Campaign Level CineTam 
	 */

	insert into	cinetam_campaign_actuals
	(	campaign_no, cinetam_demographics_id, screening_date, attendance
	)
	select 		film_campaign.campaign_no,
						cinetam_movie_history.cinetam_demographics_id,
						cinetam_movie_history.screening_date,
						sum(cinetam_movie_history.attendance) as attendance
	from			film_campaign,
						movie_history,
						v_certificate_item_distinct,
						campaign_spot,
						cinetam_movie_history
	where			film_campaign.campaign_no = campaign_spot.campaign_no
	and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
	and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
	and				movie_history.attendance is not null
	and				movie_history.attendance > 0 
	and				movie_history.country = cinetam_movie_history.country_code 
	and				campaign_spot.screening_date = @screening_date
	and				movie_history.screening_date = @screening_date
	and				movie_history.complex_id = cinetam_movie_history.complex_id
	and				movie_history.movie_id = cinetam_movie_history.movie_id
	and				movie_history.screening_date = cinetam_movie_history.screening_date
	and				movie_history.occurence = cinetam_movie_history.occurence
	and				movie_history.print_medium = cinetam_movie_history.print_medium
	and				movie_history.three_d_type = cinetam_movie_history.three_d_type
	group by 	film_campaign.campaign_no,
						cinetam_movie_history.cinetam_demographics_id,
						cinetam_movie_history.screening_date

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

	insert into	cinetam_campaign_complex_actuals
	(campaign_no, complex_id, movie_id, cinetam_demographics_id, screening_date, attendance)
	select 		film_campaign.campaign_no,
						movie_history.complex_id,
						movie_history.movie_id,
						cinetam_movie_history.cinetam_demographics_id,
						cinetam_movie_history.screening_date,
						sum(cinetam_movie_history.attendance) as attendance
	from			film_campaign,
						movie_history,
						v_certificate_item_distinct,
						campaign_spot,
						cinetam_movie_history
	where		film_campaign.campaign_no = campaign_spot.campaign_no
	and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
	and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
	and				movie_history.attendance is not null
	and				movie_history.attendance > 0 
	and				campaign_spot.screening_date = @screening_date
	and				movie_history.screening_date = @screening_date
	and				movie_history.complex_id = cinetam_movie_history.complex_id
	and				movie_history.movie_id = cinetam_movie_history.movie_id
	and				movie_history.screening_date = cinetam_movie_history.screening_date
	and				movie_history.occurence = cinetam_movie_history.occurence
	and				movie_history.print_medium = cinetam_movie_history.print_medium
	and				movie_history.three_d_type = cinetam_movie_history.three_d_type
	group by 	film_campaign.campaign_no,
						movie_history.complex_id,
						movie_history.movie_id,
						cinetam_movie_history.cinetam_demographics_id,
						cinetam_movie_history.screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Generate Campaign Actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	update			cinetam_campaign_actuals
	set					unique_transactions = temp_table.movio_unique_transactions,
							unique_people = temp_table.movio_unique_people
	from				(	select 			v_cinetam_campaign_post_analysis.campaign_no,
														v_movio_data_post_analysis.screening_date,
														v_cinetam_campaign_post_analysis.cinetam_demographics_id, 
														sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
														sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
								from				v_movio_data_post_analysis,
														v_cinetam_campaign_post_analysis,
														cinetam_campaign_settings
								where			v_movio_data_post_analysis.country_code = 'A'
								and					v_cinetam_campaign_post_analysis.country_code = 'A'
								and					v_movio_data_post_analysis.country_code = v_cinetam_campaign_post_analysis.country_code
								and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
								and					v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
								and					v_movio_data_post_analysis.complex_id = v_cinetam_campaign_post_analysis.complex_id
								and					v_movio_data_post_analysis.movie_code = v_cinetam_campaign_post_analysis.movie_code
								and					v_movio_data_post_analysis.screening_date = v_cinetam_campaign_post_analysis.screening_date
								and					v_movio_data_post_analysis.screening_date = @screening_date
										group by		v_cinetam_campaign_post_analysis.campaign_no,
														v_movio_data_post_analysis.screening_date,
														v_cinetam_campaign_post_analysis.cinetam_demographics_id) as temp_table
	where	cinetam_campaign_actuals.campaign_no = temp_table.campaign_no
	and			cinetam_campaign_actuals.screening_date = temp_table.screening_date
	and			cinetam_campaign_actuals.cinetam_demographics_id = temp_table.cinetam_demographics_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update actual unique trans aus. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	update			cinetam_campaign_actuals
	set					unique_transactions = temp_table.movio_unique_transactions,
							unique_people = temp_table.movio_unique_people
	from				(	select 			v_cinetam_campaign_post_analysis.campaign_no,
														v_movio_data_post_analysis.screening_date,
														v_cinetam_campaign_post_analysis.cinetam_demographics_id, 
														sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
														sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
								from				v_movio_data_post_analysis,
														v_cinetam_campaign_post_analysis,
														cinetam_campaign_settings
								where			v_movio_data_post_analysis.country_code = 'Z'
								and					v_cinetam_campaign_post_analysis.country_code = 'Z'
								and					v_movio_data_post_analysis.country_code = v_cinetam_campaign_post_analysis.country_code
								and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
								and					v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
								and					v_movio_data_post_analysis.complex_id = v_cinetam_campaign_post_analysis.complex_id
								and					v_movio_data_post_analysis.movie_code = v_cinetam_campaign_post_analysis.movie_code
								and					v_movio_data_post_analysis.screening_date = v_cinetam_campaign_post_analysis.screening_date
								and					v_movio_data_post_analysis.screening_date = @screening_date
										group by		v_cinetam_campaign_post_analysis.campaign_no,
														v_movio_data_post_analysis.screening_date,
														v_cinetam_campaign_post_analysis.cinetam_demographics_id) as temp_table
	where	cinetam_campaign_actuals.campaign_no = temp_table.campaign_no
	and			cinetam_campaign_actuals.screening_date = temp_table.screening_date
	and			cinetam_campaign_actuals.cinetam_demographics_id = temp_table.cinetam_demographics_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update actual unique trans nz. Close denied.', 16, 1)
		rollback transaction
		return -1
	end


	insert into		cinetam_attendance_campaign_tracking
	select				campaign_spot.campaign_no, 
							cinetam_movie_history.screening_date, 
							campaign_spot.spot_type, 
							cinetam_demographics_id,
							isnull(sum(attendance),0) as attendance,
							count(distinct spot_id)
	from 				cinetam_movie_history,
							v_certificate_item_distinct,
							campaign_spot
	where				cinetam_movie_history.certificate_group_id = v_certificate_item_distinct.certificate_group
	and					v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
	and					cinetam_movie_history.screening_date = @screening_date
	and					campaign_spot.screening_date = cinetam_movie_history.screening_date
	group by			campaign_spot.campaign_no, 
							cinetam_movie_history.screening_date, 
							campaign_spot.spot_type, 
							cinetam_demographics_id
							
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update cinetam_attendance_campaign_tracking. Close denied.', 16, 1)
		rollback transaction
		return -1
	end
	

	insert into inclusion_cinetam_attendance 
	select inclusion_id,
				campaign_no,
				screening_date,
				cinetam_reporting_demographics_id,
				movie_id,
				isnull(attendance,0) 
	from v_inclusion_cinetam_attendance 
	where screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update inclusion_cinetam_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	insert into 	inclusion_cinetam_complex_attendance 
	select inclusion_id,
				campaign_no,
				screening_date,
				complex_id,
				cinetam_reporting_demographics_id,
				movie_id,
				isnull(attendance,0) 
	from v_inclusion_cinetam_complex_attendance 
	where screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update inclusion_cinetam_complex_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	insert into	cinetam_cinelight_attendance
	select			package_id,
						campaign_no,
						cinelight_table.screening_date,
						0,
						sum(demo_attendance)
	from				(select			package_id,
											campaign_no,
											complex_id,
											screening_date
						from				cinelight_spot
						inner join		cinelight on cinelight_spot.cinelight_id = cinelight.cinelight_id
						where			screening_date = @screening_date
						and				spot_status = 'X'
						group by		package_id,
											campaign_no,
											complex_id,
											screening_date) as cinelight_table
	inner join		(select			complex_id,
											screening_date,
											SUM(attendance) as demo_attendance
						from				movie_history
						where			screening_date = @screening_date
						group by		complex_id,
											screening_date) as cinetam_attendance 
	on					cinelight_table.screening_date = cinetam_attendance.screening_date
	and				cinelight_table.complex_id = cinetam_attendance.complex_id
	group by		package_id,
						campaign_no,
						cinelight_table.screening_date
					
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update cinetam_cinelight_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	insert into	cinetam_cinelight_complex_attendance
	select			package_id,
						campaign_no,
						cinelight_table.screening_date,
						cinelight_table.complex_id,
						0,
						sum(demo_attendance)
	from				(select			package_id,
											campaign_no,
											complex_id,
											screening_date
						from				cinelight_spot
						inner join		cinelight on cinelight_spot.cinelight_id = cinelight.cinelight_id
						where			screening_date = @screening_date
						and				spot_status = 'X'
						group by		package_id,
											campaign_no,
											complex_id,
											screening_date) as cinelight_table
	inner join		(select			complex_id,
											screening_date,
											SUM(attendance) as demo_attendance
						from				movie_history
						where			screening_date = @screening_date
						group by		complex_id,
											screening_date) as cinetam_attendance 
	on					cinelight_table.screening_date = cinetam_attendance.screening_date
	and				cinelight_table.complex_id = cinetam_attendance.complex_id
	group by		package_id,
						campaign_no,
						cinelight_table.screening_date,
						cinelight_table.complex_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update cinetam_cinelight_complex_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end


	insert into	cinetam_cinelight_attendance
	select			package_id,
						campaign_no,
						cinelight_table.screening_date,
						cinetam_reporting_demographics_id,
						sum(demo_attendance)
	from				(select			package_id,
											campaign_no,
											complex_id,
											screening_date
						from				cinelight_spot
						inner join		cinelight on cinelight_spot.cinelight_id = cinelight.cinelight_id
						where			screening_date = @screening_date
						and				spot_status = 'X'
						group by		package_id,
											campaign_no,
											complex_id,
											screening_date) as cinelight_table
	inner join		(select			complex_id,
											screening_date,
											cinetam_reporting_demographics_id,
											SUM(attendance) as demo_attendance
						from				cinetam_movie_history
						inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
						where			screening_date = @screening_date
						group by		complex_id,
											screening_date,
											cinetam_reporting_demographics_id) as cinetam_attendance 
	on					cinelight_table.screening_date = cinetam_attendance.screening_date
	and				cinelight_table.complex_id = cinetam_attendance.complex_id
	where			cinetam_attendance.cinetam_reporting_demographics_id <> 0
	group by		package_id,
						campaign_no,
						cinelight_table.screening_date,
						cinetam_reporting_demographics_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update cinetam_cinelight_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	insert into	cinetam_cinelight_complex_attendance
	select			package_id,
						campaign_no,
						cinelight_table.screening_date,
						cinelight_table.complex_id,
						cinetam_reporting_demographics_id,
						sum(demo_attendance)
	from				(select			package_id,
											campaign_no,
											complex_id,
											screening_date
						from				cinelight_spot
						inner join		cinelight on cinelight_spot.cinelight_id = cinelight.cinelight_id
						where			screening_date = @screening_date
						and				spot_status = 'X'
						group by		package_id,
											campaign_no,
											complex_id,
											screening_date) as cinelight_table
	inner join		(select			complex_id,
											screening_date,
											cinetam_reporting_demographics_id,
											SUM(attendance) as demo_attendance
						from				cinetam_movie_history
						inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
						where			screening_date = @screening_date
						group by		complex_id,
											screening_date,
											cinetam_reporting_demographics_id) as cinetam_attendance 
	on					cinelight_table.screening_date = cinetam_attendance.screening_date
	and				cinelight_table.complex_id = cinetam_attendance.complex_id
	where			cinetam_attendance.cinetam_reporting_demographics_id <> 0
	group by		package_id,
						campaign_no,
						cinelight_table.screening_date,
						cinelight_table.complex_id,
						cinetam_reporting_demographics_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update cinetam_cinelight_complex_attendance. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	update			film_screening_dates 
	set				cinetam_status = 'Y'
	where			screening_date = @arg_screening_date
	
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Update film_screening_dates. Close denied.', 16, 1)
		rollback transaction
		return -1
	end
		
	/*
	 * Commit & Return
	 */

	commit transaction
	fetch screening_date_csr into @screening_date
end

return 0
GO
