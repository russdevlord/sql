/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_movie]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_post_campaign_report_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_movie]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_post_campaign_report_movie]		@campaign_no							int,
												@screening_date							datetime,
												@product								int,
												@cinetam_reporting_demographics_id		int,
												@override_sold_demo						int,
												@inclusion_id							int,
												@movie_breakdown						int
																				
--with recompile

as

declare		@error										int,
			@inclusion_type								int,
			@multiple_demos								int,
			@product_desc								varchar(200),
			@cinetam_reporting_demographics_desc		varchar(30),
			@movie_id_1									int,
			@long_name_1								varchar(100)	,
			@actual_attendance_1						numeric(20,8),
			@movie_id_2									int,
			@long_name_2								varchar(100),
			@actual_attendance_2						numeric(20,8),
			@movie_id_3									int,
			@long_name_3								varchar(100),
			@actual_attendance_3						numeric(20,8),
			@sort_order									int,
			@total_attendance							numeric(20,8)

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on

create table #movie
(
	product_desc			varchar(200)		not null,
	demo_desc				varchar(100)		not null,
	movie_id				int					not null,
	long_name				varchar(100)		not null,
	actual_attendance		numeric(20,8)		not null
)

create table #movie_select
(
	product_desc			varchar(200)		not null,
	demo_desc				varchar(100)		not null,
	sort_order				int					not null,
	movie_id_1				int					not null,
	long_name_1				varchar(100)		not null,
	actual_attendance_1		numeric(20,8)		not null,
	movie_id_2				int					null,
	long_name_2				varchar(100)		null,
	actual_attendance_2		numeric(20,8)		null,
	movie_id_3				int					null,
	long_name_3				varchar(100)		null,
	actual_attendance_3		numeric(20,8)		null
)

create table #inclusions
(
	inclusion_id			int					not null
)
	

if @movie_breakdown = 0 or @product = 5
begin
	select			product_desc,
					demo_desc,
					1 as sort_order,
					movie_id as movie_id_1,
					long_name as long_name_1,
					actual_attendance as actual_attendance_1,	
					movie_id as movie_id_2,
					long_name as long_name_2,
					actual_attendance as actual_attendance_2,	
					movie_id as movie_id_3,
					long_name as long_name_3,
					actual_attendance as actual_attendance_3
	from			#movie

	return 0
end

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


if @product = 8
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

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#movie
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					movie_id,
					long_name,
					sum(attendance)
	from			(select			sum(attendance) as attendance,
									inclusion_cinetam_complex_attendance.movie_id,
									long_name
					from			inclusion_cinetam_complex_attendance
					inner join		movie on inclusion_cinetam_complex_attendance.movie_id = movie.movie_id
					where			inclusion_cinetam_complex_attendance.campaign_no = @campaign_no
					and				inclusion_cinetam_complex_attendance.screening_date <= @screening_date
					and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		inclusion_cinetam_complex_attendance.movie_id,
									long_name) as temp_summary_table
	group by		movie_id,
					long_name
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
	
	insert into		#movie
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					inclusion_cinetam_complex_attendance.movie_id,
					long_name,
					sum(attendance)
	from			inclusion_cinetam_complex_attendance
	inner join		movie on inclusion_cinetam_complex_attendance.movie_id = movie.movie_id
	inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
	where			inclusion_cinetam_complex_attendance.screening_date <= @screening_date
	and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	group by		inclusion_cinetam_complex_attendance.movie_id,
					long_name
end

select			@total_attendance = sum(actual_attendance)
from			#movie

declare			movie_csr cursor static for
select			movie_id,
				long_name,
				actual_attendance
from			#movie
order by		actual_attendance desc
for				read only

select @sort_order = 0

open movie_csr
fetch movie_csr into	@movie_id_1	, @long_name_1, @actual_attendance_1	
while(@@fetch_status = 0)
begin

	select			@movie_id_2 = null, 
					@long_name_2 = null, 
					@actual_attendance_2 = null, 
					@movie_id_3 = null, 
					@long_name_3 = null, 
					@actual_attendance_3 = null

	select @sort_order = @sort_order + 1					

	fetch movie_csr into	@movie_id_2, @long_name_2,  @actual_attendance_2

	if @@fetch_status = 0
		fetch movie_csr into	@movie_id_3, @long_name_3,  @actual_attendance_3

	select	@actual_attendance_1 = @actual_attendance_1 / @total_attendance,		
				@actual_attendance_2 = @actual_attendance_2 / @total_attendance,		
				@actual_attendance_3 = @actual_attendance_3 / @total_attendance

	if 	round(@actual_attendance_1, 3) = 0.000
		select	@long_name_1 = null,
						@movie_id_1 = null,
						@actual_attendance_1 = null
						
	if 	round(@actual_attendance_2, 3) = 0.000
		select	@long_name_2 = null,
						@movie_id_2 = null,
						@actual_attendance_2 = null

	if 	round(@actual_attendance_3, 3) = 0.000
		select	@long_name_3 = null,
						@movie_id_3 = null,
						@actual_attendance_3 = null					
					
	if not (@actual_attendance_1 is null )
		insert into #movie_select values (	@product_desc, 
											@cinetam_reporting_demographics_desc, 
											@sort_order,
											@movie_id_1,
											@long_name_1, 
											@actual_attendance_1, 
											@movie_id_2, 
											@long_name_2, 
											@actual_attendance_2, 
											@movie_id_3, 
											@long_name_3, 
											@actual_attendance_3)

	fetch movie_csr into	@movie_id_1	, @long_name_1, @actual_attendance_1	
end

select			product_desc,
				demo_desc,
				sort_order,
				movie_id_1,
				long_name_1,
				actual_attendance_1,	
				movie_id_2,
				long_name_2,
				actual_attendance_2,	
				movie_id_3,
				long_name_3,
				actual_attendance_3
from			#movie_select
order by		sort_order

return 0
GO
