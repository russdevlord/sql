/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_post_campaign_report_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_post_campaign_report_summary]		@campaign_no									int,
												@screening_date									datetime,
												@product										int,
												@cinetam_reporting_demographics_id				int,
												@override_sold_demo								int,
												@inclusion_id									int
																				
--with recompile

as

declare				@error									int,
					@inclusion_type							int,
					@multiple_demos							int,
					@product_desc							varchar(200),
					@cinetam_reporting_demographics_desc	varchar(50)

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on

create table #summary
(
	product_desc				varchar(200)			not null,
	demo_desc					varchar(100)				not null,
	inclusion_desc				varchar(200)			not null,
	target_attendance			numeric(20,8)			not null,
	actual_attendance			numeric(20,8)			not null,
	campaign_desc				varchar(108)				not null,
	client_name					varchar(100)				not null,
	client_product_desc			varchar(100)				not null,
	agency_name					varchar(100)				not null,
	spend						numeric(20,8)			not null,
	start_date					datetime					not null,
	end_date					datetime					not null
)

create table #targets
(
	screening_date		datetime					not null,
	target_attendance	numeric(20,8)			not null
)
	
create table #inclusions
(
	inclusion_id		int			not null
)
	

/*
 * Products:
 * 1 Follow Film
 * 2 MAP
 * 3 TAP
 * 4 Roadblock 
 * 5 Digilite
 * 6 CineAsia
 * 7 First Run
 * 8 Campaign Summary
 */

if @product = 1 -- follow film
begin
	select @inclusion_type = 29
	select @product_desc = 'Follow Film'
end
else if @product = 2 -- MAP
begin
	select @inclusion_type = 32
	select @product_desc = 'MAP'
end
else if @product = 3 -- TAP
begin
	select @inclusion_type = 24
	select @product_desc = 'TAP'
end
else if @product = 4  -- Roadblock
begin
	select @inclusion_type = 30
	select @product_desc = 'Roadblock'
end
else if @product = 5 -- Digilite
begin
	select @product_desc = 'Digilite'
end
else if @product = 6 -- Cineasia
begin
	select @inclusion_type = 30
	select @product_desc = 'Access Asia'
end
else if @product = 7 --First Run
begin
	select @inclusion_type = 31
	select @product_desc = 'First Run'
end
else if @product = 8 -- Summary
begin
	select @product_desc = 'Entire Campaign Summary'
end

if @product = 5
begin
	if @override_sold_demo = 0
	begin
		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from			inclusion
		inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
		where			inclusion.campaign_no = @campaign_no

		if @multiple_demos > 1 and @override_sold_demo = 0
		begin
			select @cinetam_reporting_demographics_id  = 0
		end
		else
		begin
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			where			inclusion.campaign_no = @campaign_no
		end
	end

	select			@cinetam_reporting_demographics_id = ISNULL(@cinetam_reporting_demographics_id, 0)

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#inclusions
	select			package_id
	from			cinelight_package
	where			campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				cinelight_package.package_id = @inclusion_id)

	--digilite
	insert into		#summary
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					case when @inclusion_id is null then 'Consolidated Digilites' else package_code + ' - ' + package_desc end,
					0,
					sum(attendance),
					convert(varchar(6), v_film_campaign_pcr_details.campaign_no) + ' - ' + product_desc,
					client_name,
					client_product_desc,
					agency_name,
					sum(charge_rate_sum),
					min(v_film_campaign_pcr_attendance_digilite.screening_date),
					max(v_film_campaign_pcr_attendance_digilite.screening_date)
	from			v_film_campaign_pcr_details	
	inner join		v_film_campaign_pcr_attendance_digilite on v_film_campaign_pcr_details.campaign_no = v_film_campaign_pcr_attendance_digilite.campaign_no
	inner join		v_film_campaign_pcr_digilite_details on v_film_campaign_pcr_attendance_digilite.package_id = v_film_campaign_pcr_digilite_details.package_id  
	and				v_film_campaign_pcr_attendance_digilite.complex_id = v_film_campaign_pcr_digilite_details.complex_id 
	and				v_film_campaign_pcr_attendance_digilite.screening_date = v_film_campaign_pcr_digilite_details.screening_date
	inner join		#inclusions on v_film_campaign_pcr_attendance_digilite.package_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_details.campaign_no = @campaign_no
	and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	group by		v_film_campaign_pcr_details.campaign_no,
					product_desc,
					client_name,
					client_product_desc,
					agency_name,
					case when @inclusion_id is null then 'Consolidated Digilites' else package_code + ' - ' + package_desc end
end
else if @product = 8
begin
	if @override_sold_demo = 0
	begin

		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from			inclusion
		inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
		where			inclusion.campaign_no = @campaign_no

		if @multiple_demos > 1 and @override_sold_demo = 0
		begin
			select @cinetam_reporting_demographics_id  = 0
		end
		else
		begin
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			where			inclusion.campaign_no = @campaign_no
		end
	end
	
	insert into		#targets
	select			screening_date,
					sum(target_attendance)
	from			(select			screening_date,
									sum(original_target_attendance) as target_attendance
					from			v_film_campaign_pcr_inclusion_details
					inner join		inclusion_follow_film_targets on v_film_campaign_pcr_inclusion_details.inclusion_id = inclusion_follow_film_targets.inclusion_id
					where			v_film_campaign_pcr_inclusion_details.campaign_no = @campaign_no
					and				inclusion_follow_film_targets.screening_date <= @screening_date	
					and				inclusion_follow_film_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		screening_date
					union all
					select			screening_date,
									sum(original_target_attendance) as target_attendance
					from			v_film_campaign_pcr_inclusion_details
					inner join		inclusion_cinetam_targets on v_film_campaign_pcr_inclusion_details.inclusion_id = inclusion_cinetam_targets.inclusion_id
					where			v_film_campaign_pcr_inclusion_details.campaign_no = @campaign_no
					and				inclusion_cinetam_targets.screening_date <= @screening_date	
					and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		screening_date) as target_table
	group by		screening_date

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#summary
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					'Entire Campaign Summary',
					(select			isnull(sum(target_attendance),0)
					from				#targets),
					sum(attendance),
					campaign_desc,
					client_name, 
					client_product_desc, 
					agency_name,
					sum(charge_rate_sum) as charge_rate_sum,
					min(min_date),
					max(max_date)
	from			(select			sum(attendance) as attendance,
									convert(varchar(6), v_film_campaign_pcr_details.campaign_no) + ' - ' + product_desc as campaign_desc,
									client_name,
									client_product_desc,
									agency_name,
									sum(charge_rate_sum) as charge_rate_sum,
									min(v_film_campaign_pcr_attendance_digilite.screening_date) as min_date,
									max(v_film_campaign_pcr_attendance_digilite.screening_date) as max_date
					from			v_film_campaign_pcr_details	
					inner join		v_film_campaign_pcr_attendance_digilite on v_film_campaign_pcr_details.campaign_no = v_film_campaign_pcr_attendance_digilite.campaign_no
					inner join		v_film_campaign_pcr_digilite_details on v_film_campaign_pcr_attendance_digilite.package_id = v_film_campaign_pcr_digilite_details.package_id  and v_film_campaign_pcr_attendance_digilite.complex_id = v_film_campaign_pcr_digilite_details.complex_id and v_film_campaign_pcr_attendance_digilite.screening_date = v_film_campaign_pcr_digilite_details.screening_date
					where			v_film_campaign_pcr_details.campaign_no = @campaign_no
					and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
					and				v_film_campaign_pcr_attendance_digilite.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		v_film_campaign_pcr_details.campaign_no,
									product_desc,
									client_name,
									client_product_desc,
									agency_name
					union all
					select 			sum(temp_inclusion_cinetam_attendance.attendance) as attendance,
									convert(varchar(6), v_film_campaign_pcr_details.campaign_no) + ' - ' + product_desc as campaign_desc,
									client_name,
									client_product_desc,
									agency_name,
									sum(charge_rate_sum) as charge_rate_sum,
									min(min_date) as min_date,
									max(max_date) as max_date
					from			v_film_campaign_pcr_details	
					inner join		(select			campaign_no,
													min(screening_date) as min_date,
													max(screening_date) as max_date,
													inclusion_cinetam_attendance.inclusion_id,
													SUM(attendance) as attendance
									from			inclusion_cinetam_attendance
									where			inclusion_cinetam_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
									and				inclusion_cinetam_attendance.screening_date <= @screening_date
									group by		campaign_no,
													inclusion_cinetam_attendance.inclusion_id) as temp_inclusion_cinetam_attendance on v_film_campaign_pcr_details.campaign_no = temp_inclusion_cinetam_attendance.campaign_no 
					inner join		v_film_campaign_pcr_inclusion_details on temp_inclusion_cinetam_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
					where			v_film_campaign_pcr_details.campaign_no = @campaign_no
					group by		v_film_campaign_pcr_details.campaign_no,
									product_desc,
									client_name,
									client_product_desc,
									agency_name) as temp_summary_table
		group by	campaign_desc,
					client_name, 
					client_product_desc, 
					agency_name
end
else
begin
	insert into		#inclusions
	select			inclusion_id
	from			v_film_campaign_pcr_inclusion_details
	where			campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				v_film_campaign_pcr_inclusion_details.inclusion_id = @inclusion_id)
	and				inclusion_type = @inclusion_type
	and				(@product in (1,2,3,5,7,8)
	or				(@product = 4
	and				cineasia_count = 0)
	or				(@product = 6
	and				cineasia_count > 0))

	if @override_sold_demo = 0
	begin
		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from			inclusion_cinetam_settings 
		inner join		#inclusions on inclusion_cinetam_settings.inclusion_id = #inclusions.inclusion_id

		if @multiple_demos > 1 and @override_sold_demo = 0
		begin
			select @cinetam_reporting_demographics_id  = 0
		end
		else
		begin
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion_cinetam_settings
			inner join		#inclusions on inclusion_cinetam_settings.inclusion_id = #inclusions.inclusion_id
		end
	end

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#targets
	select			screening_date,
					sum(target_attendance)
	from			(select			screening_date,
									sum(original_target_attendance) as target_attendance
					from			inclusion_follow_film_targets 
					inner join		#inclusions on inclusion_follow_film_targets.inclusion_id = #inclusions.inclusion_id
					where			inclusion_follow_film_targets.screening_date <= @screening_date
					and				inclusion_follow_film_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		screening_date
					union all
					select			screening_date,
									sum(original_target_attendance) as target_attendance
					from			inclusion_cinetam_targets
					inner join		#inclusions on inclusion_cinetam_targets.inclusion_id = #inclusions.inclusion_id
					where			inclusion_cinetam_targets.screening_date <= @screening_date
					and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		screening_date) as target_table
	group by		screening_date

	insert into		#summary
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					case when @inclusion_id is null then 'Consolidated ' + @product_desc else v_film_campaign_pcr_inclusion_details.inclusion_desc end,
					(select			isnull(sum(target_attendance),0)
					from			#targets),
					sum(attendance),
					convert(varchar(6), v_film_campaign_pcr_details.campaign_no) + ' - ' + product_desc,
					client_name,
					client_product_desc,
					agency_name,
					sum(charge_rate_sum),
					min(min_date),
					max(max_date)
	from			v_film_campaign_pcr_details	
	inner join		(select			inclusion_cinetam_attendance.campaign_no,
									inclusion_cinetam_attendance.inclusion_id,
									min(screening_date) as min_date,
									max(screening_date) as max_date,
									SUM(attendance) as attendance
					from			inclusion_cinetam_attendance
					inner join		#inclusions on inclusion_cinetam_attendance.inclusion_id = #inclusions.inclusion_id
					where			inclusion_cinetam_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
					and				inclusion_cinetam_attendance.screening_date <= @screening_date
					group by		inclusion_cinetam_attendance.campaign_no,
									inclusion_cinetam_attendance.inclusion_id) as temp_inclusion_cinetam_attendance on v_film_campaign_pcr_details.campaign_no = temp_inclusion_cinetam_attendance.campaign_no 
	inner join		v_film_campaign_pcr_inclusion_details on temp_inclusion_cinetam_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
	group by		v_film_campaign_pcr_details.campaign_no,
					product_desc,
					client_name,
					client_product_desc,
					agency_name,
					case when @inclusion_id is null then 'Consolidated ' + @product_desc else v_film_campaign_pcr_inclusion_details.inclusion_desc end
end

select * from #summary

return 0
GO
