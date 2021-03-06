/****** Object:  StoredProcedure [dbo].[p_certificate_warning]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_warning]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_warning]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_certificate_warning]		@complex_id				int,
												@screening_date			datetime

as

declare			@error						int


create table #warnings
(	
	warning_message			varchar(max)
)


--package start date
insert into	#warnings
select			'Package Has Not Started: ' + convert(varchar(6), campaign_spot.campaign_no) + ' - Package: ' + package_code 
from			campaign_spot with (nolock)
inner join		campaign_package with (nolock) on campaign_spot.package_id = campaign_package.package_id
where			spot_status = 'A'
and				campaign_spot.complex_id =@complex_id
and				screening_date = @screening_date
and				isnull(start_date, screening_date) > @screening_date
group by		campaign_spot.campaign_no,
				package_code


--package expired
insert into	#warnings
select			'Package Has Expired: ' + convert(varchar(6), campaign_spot.campaign_no) + ' - Package: ' + package_code 
from			campaign_spot with (nolock)
inner join		campaign_package with (nolock) on campaign_spot.package_id = campaign_package.package_id
where			spot_status = 'A'
and				campaign_spot.complex_id =@complex_id
and				screening_date = @screening_date
and				isnull(used_by_date, screening_date) < @screening_date
group by		campaign_spot.campaign_no,
				package_code

--package not started
insert into	#warnings
select			'Package Has Not Started: ' + convert(varchar(6), campaign_spot.campaign_no) + ' - Package: ' + package_code 
from			campaign_spot with (nolock) 
inner join		campaign_package with (nolock) on campaign_spot.package_id = campaign_package.package_id
where			spot_status = 'A'
and				campaign_spot.complex_id =@complex_id
and				screening_date = @screening_date
and				campaign_package.start_date > @screening_date
group by		campaign_spot.campaign_no,
				package_code

--prints not active
insert into	#warnings
select			'Prints Not Active: ' + convert(varchar(6), campaign_spot.campaign_no) + ' - Film Print: ' + convert(varchar(8), film_print.print_name) + ' - ' + film_print.print_name
from			campaign_spot with (nolock) 
inner join		print_package with (nolock) on campaign_spot.package_id = print_package.package_id
inner join		film_print on print_package.print_id = film_print.print_id
where			spot_status = 'A'
and				campaign_spot.complex_id =@complex_id
and				screening_date = @screening_date
and				print_status <> 'A'
group by		campaign_spot.campaign_no,
				film_print.print_id,
				film_print.print_name

--prints not at site
insert into	#warnings
select			'Prints Not At Site: ' + convert(varchar(6), campaign_spot.campaign_no) + ' - Film Print: ' + convert(varchar(8), film_print.print_name) + ' - ' + film_print.print_name
from			campaign_spot with (nolock) 
inner join		print_package with (nolock) on campaign_spot.package_id = print_package.package_id
inner join		print_package_medium with (nolock) on print_package.print_package_id = print_package_medium.print_package_id
inner join		print_package_three_d with (nolock) on print_package.print_package_id = print_package_three_d.print_package_id
inner join		film_print with (nolock) on print_package.print_id = film_print.print_id
where			spot_status = 'A'
and				campaign_spot.complex_id =@complex_id
and				screening_date = @screening_date
and				film_print.print_id not in (	select 			print_id
												from 			print_transactions
												where			campaign_no = campaign_spot.campaign_no
												and				print_id = film_print.print_id 
												and				complex_id = @complex_id 
												and				ptran_status = 'C'
												and				print_medium = print_package_medium.print_medium
												and				three_d_type = print_package_three_d.three_d_type
												group by		print_id
												having			IsNull(sum(cinema_qty),0) > 0)
group by		campaign_spot.campaign_no,
				film_print.print_id,
				film_print.print_name

--no package		
insert into	#warnings
select			'Missing Package: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id =@complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_spot.inclusion_id not in (select inclusion_id from inclusion_cinetam_package)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc

--targets generated FF TAP MM
insert into	#warnings
select			'Missing MAP or RB or TAP Targets: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id =@complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type in (24,32)
and				inclusion_spot.inclusion_id not in (select inclusion_id from inclusion_cinetam_targets where inclusion_cinetam_targets.complex_id = inclusion_cinetam_settings.complex_id and inclusion_cinetam_targets.screening_date = inclusion_spot.screening_date)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc


insert into	#warnings
select			'Missing FF Targets: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id =@complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type in (29)
and				inclusion_spot.inclusion_id not in (select inclusion_id from inclusion_follow_film_targets where inclusion_follow_film_targets.complex_id = inclusion_cinetam_settings.complex_id and inclusion_follow_film_targets.screening_date = inclusion_spot.screening_date)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc

--pacakge with too many restrictions on TAP MAP
insert into	#warnings
select			'MAP or TAP Package with too many Classification Restrictions: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion_cinetam_package with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id = @complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id in (	select			package_id
															from			(select				package_id 
																			from					campaign_classification
																			where				package_id = inclusion_cinetam_package.package_id 
																			and					instruction_type = 2) as temp_table 
															group by		package_id 
															having			COUNT(package_id) > 2)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc

insert into	#warnings
select			'MAP or TAP Package with too many Genre Restrictions: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion_cinetam_package with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id = @complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id in (	select			package_id
															from			(select				package_id 
																			from					campaign_category 
																			where				package_id = inclusion_cinetam_package.package_id 
																			and					instruction_type = 3
																			and					movie_category_code <> 'CA'
																			and					movie_category_code <> 'B') as temp_table 
															group by		package_id 
															having			COUNT(package_id) > 3)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc

insert into	#warnings
select			'MAP or TAP Package with too many Genre Preferences: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion_cinetam_package with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id = @complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id in (	select			package_id
															from			(select				package_id 
																			from				campaign_category 
																			where				package_id = inclusion_cinetam_package.package_id 
																			and					instruction_type = 2) as temp_table 
															group by		package_id 
															having			COUNT(package_id) > 3)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc

insert into	#warnings
select			'MAP or TAP Package with too many Title Restrictions: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from			inclusion_spot with (nolock) 
inner join		inclusion with (nolock) on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_cinetam_settings with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion_cinetam_package with (nolock) on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
where			spot_status = 'A'
and				inclusion_cinetam_settings.complex_id = @complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id in (	select			package_id
															from			(select				package_id
																			from					movie_screening_instructions
																			inner join			movie on movie_screening_instructions.movie_id = movie.movie_id 
																			where				instruction_type = 3 
																			and					package_id = inclusion_cinetam_package.package_id
																			group by			package_id, 
																								case when RIGHT(long_name, 3) = ' 3D' then LEFT(long_name, len(long_name) - 3) else long_name end) as temp_table
															group by		package_id
															having			COUNT(package_id) > 3)
group by		inclusion.campaign_no,
				inclusion.inclusion_id,
				inclusion.inclusion_desc

--movie estimates missing
insert into	#warnings
select			'Movie Missing Estimates: ' + long_name
from			movie_history with (nolock) 
inner join		movie with (nolock) on movie_history.movie_id = movie.movie_id
where			complex_id =@complex_id
and				screening_date = @screening_date
and				movie_history.movie_id <> 102
and				movie_history.movie_id not in (	select			movie_id 
												from			cinetam_movie_complex_estimates 
												where			complex_id =@complex_id
												and				screening_date = @screening_date
												)

insert into	#warnings
select			'Movie Missing Category: ' + long_name
from			movie_history with (nolock) 
inner join		movie with (nolock) on movie_history.movie_id = movie.movie_id
where			complex_id =@complex_id
and				screening_date = @screening_date
and				movie_history.movie_id <> 102
and				movie_history.movie_id not in (	select			movie_id 
												from			target_categories )


select * from	
#warnings

return 0
GO
