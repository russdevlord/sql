/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_market]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_post_campaign_report_market]
GO
/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_market]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_post_campaign_report_market]		@campaign_no								int,
												@screening_date								datetime,
												@product									int,
												@cinetam_reporting_demographics_id			int,
												@override_sold_demo							int,
												@inclusion_id								int,
												@market_breakdown							int

--with recompile

as

declare				@error										int,
					@inclusion_type								int,
					@multiple_demos								int,
					@product_desc								varchar(200),
					@cinetam_reporting_demographics_desc		varchar(30),
					@film_market_no_1							int,
					@film_market_desc_1							varchar(100)	,
					@actual_attendance_1						numeric(20,8),
					@film_market_no_2							int,
					@film_market_desc_2							varchar(100),
					@actual_attendance_2						numeric(20,8),
					@film_market_no_3							int,
					@film_market_desc_3							varchar(100),
					@actual_attendance_3						numeric(20,8),
					@sort_order									int,
					@total_attendance							numeric(20,8)

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on

create table #market
(
	product_desc				varchar(200)			not null,
	demo_desc					varchar(100)			not null,
	film_market_no				int						not null,
	film_market_desc			varchar(100)			not null,
	actual_attendance			numeric(20,8)			not null
)

create table #market_select
(
	product_desc				varchar(200)			not null,
	demo_desc					varchar(100)			not null,
	sort_order					int						not null,
	film_market_no_1			int						not null,
	film_market_desc_1			varchar(100)			not null,
	actual_attendance_1			numeric(20,8)			not null,
	film_market_no_2			int						null,
	film_market_desc_2			varchar(100)			null,
	actual_attendance_2			numeric(20,8)			null,
	film_market_no_3			int						null,
	film_market_desc_3			varchar(100)			null,
	actual_attendance_3			numeric(20,8)			null
)

create table #inclusions
(
	inclusion_id				int						not null
)
	

if @market_breakdown = 0
begin
	select			product_desc,
					demo_desc,
					1 as sort_order,
					film_market_no as film_market_no_1,
					film_market_desc as film_market_desc_1,
					actual_attendance as actual_attendance_1,	
					film_market_no as film_market_no_2,
					film_market_desc as film_market_desc_2,
					actual_attendance as actual_attendance_2,	
					film_market_no as film_market_no_3,
					film_market_desc as film_market_desc_3,
					actual_attendance as actual_attendance_3
	from			#market

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
	insert into		#market
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					film_market.film_market_no,
					film_market_desc,
					sum(attendance)
	from			v_film_campaign_pcr_attendance_digilite
	inner join		complex on v_film_campaign_pcr_attendance_digilite.complex_id = complex.complex_id
	inner join		film_market on complex.film_market_no = film_market.film_market_no
	inner join		#inclusions on v_film_campaign_pcr_attendance_digilite.package_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	group by		film_market.film_market_no,
					film_market_desc
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

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#market
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					film_market_no,
					film_market_desc,
					sum(attendance)
	from			(select			sum(attendance) as attendance,
									film_market.film_market_no,
									film_market_desc
					from			v_film_campaign_pcr_attendance_digilite 
					inner join		complex on v_film_campaign_pcr_attendance_digilite.complex_id = complex.complex_id
					inner join		film_market on complex.film_market_no = film_market.film_market_no
					where			v_film_campaign_pcr_attendance_digilite.campaign_no = @campaign_no
					and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
					and				v_film_campaign_pcr_attendance_digilite.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		film_market.film_market_no,
									film_market_desc
					union all
					select 			sum(attendance) as attendance,
									film_market.film_market_no,
									film_market_desc
					from			inclusion_cinetam_complex_attendance
					inner join		complex on inclusion_cinetam_complex_attendance.complex_id = complex.complex_id
					inner join		film_market on complex.film_market_no = film_market.film_market_no
					where			inclusion_cinetam_complex_attendance.campaign_no = @campaign_no
					and				inclusion_cinetam_complex_attendance.screening_date <= @screening_date
					and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		film_market.film_market_no,
									film_market_desc) as temp_summary_table
	group by		film_market_no,
					film_market_desc
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
	
	insert into		#market
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					film_market.film_market_no,
					film_market_desc,
					sum(attendance)
	from			inclusion_cinetam_complex_attendance
	inner join		complex on inclusion_cinetam_complex_attendance.complex_id = complex.complex_id
	inner join		film_market on complex.film_market_no = film_market.film_market_no
	inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
	where			inclusion_cinetam_complex_attendance.screening_date <= @screening_date
	and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	group by		film_market.film_market_no,
					film_market_desc
end

select			@total_attendance = sum(actual_attendance)
from			#market

declare			market_csr cursor static for
select			film_market_no,
				film_market_desc,
				actual_attendance
from			#market
order by		actual_attendance desc
for				read only

select @sort_order = 0

open market_csr
fetch market_csr into @film_market_no_1, @film_market_desc_1, @actual_attendance_1	
while(@@fetch_status = 0)
begin

	select			@film_market_no_2 = null, 
					@film_market_desc_2 = null, 
					@actual_attendance_2 = null, 
					@film_market_no_3 = null, 
					@film_market_desc_3 = null, 
					@actual_attendance_3 = null

	select @sort_order = @sort_order + 1					

	fetch market_csr into	@film_market_no_2, @film_market_desc_2,  @actual_attendance_2

	if @@fetch_status = 0
		fetch market_csr into	@film_market_no_3, @film_market_desc_3,  @actual_attendance_3

	select	@actual_attendance_1 = @actual_attendance_1 / @total_attendance,		
				@actual_attendance_2 = @actual_attendance_2 / @total_attendance,		
				@actual_attendance_3 = @actual_attendance_3 / @total_attendance

	if 	round(@actual_attendance_1, 3) = 0.000
		select	@film_market_desc_1 = null,
						@film_market_no_1 = null,
						@actual_attendance_1 = null
						
	if 	round(@actual_attendance_2, 3) = 0.000
		select	@film_market_desc_2 = null,
						@film_market_no_2 = null,
						@actual_attendance_2 = null

	if 	round(@actual_attendance_3, 3) = 0.000
		select	@film_market_desc_3 = null,
						@film_market_no_3 = null,
						@actual_attendance_3 = null					
					
	if not (@actual_attendance_1 is null )
		insert into #market_select values (	@product_desc, 
											@cinetam_reporting_demographics_desc, 
											@sort_order,
											@film_market_no_1,
											@film_market_desc_1, 
											@actual_attendance_1, 
											@film_market_no_2, 
											@film_market_desc_2, 
											@actual_attendance_2, 
											@film_market_no_3, 
											@film_market_desc_3, 
											@actual_attendance_3)

	fetch market_csr into	@film_market_no_1	, @film_market_desc_1, @actual_attendance_1	
end

select			product_desc,
				demo_desc,
				sort_order,
				film_market_no_1,
				film_market_desc_1,
				actual_attendance_1,	
				film_market_no_2,
				film_market_desc_2,
				actual_attendance_2,	
				film_market_no_3,
				film_market_desc_3,
				actual_attendance_3
from			#market_select
order by		sort_order

return 0
GO
