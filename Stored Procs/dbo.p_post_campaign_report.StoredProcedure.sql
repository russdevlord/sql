/****** Object:  StoredProcedure [dbo].[p_post_campaign_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_post_campaign_report]
GO
/****** Object:  StoredProcedure [dbo].[p_post_campaign_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_post_campaign_report]		@campaign_no														int,
																@screening_date													datetime,
																@products															varchar(1000),
																@cinetam_reporting_demographics_id				int,
																@override_sold_demo											int,
																@consolidate_inclusions										int,
																@movie_breakdown												int,
																@weekly_breakdown											int,
																@graph																	int,
																@market_breakdown											int,
																@include_randf													int

--with recompile

as

declare				@follow_film				int,
						@map							int,
						@tap							int,
						@roadblock					int,
						@digilite						int,
						@cineasia						int,
						@first_run					int,
						@summary					int

set nocount on
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

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

 create table #products                
(                
	product			int     not null                
)    

create table #subreports
(
	campaign_no														int,
	screening_date												datetime,
	product															int,
	cinetam_reporting_demographics_id				int,
	override_sold_demo											int,
	consolidate_inclusions										int,
	inclusion_id														int,
	movie_breakdown												int,
	weekly_breakdown											int,
	graph																int,
	market_breakdown											int,
	include_randf													int,
	sort																	int,
	sort_text															varchar(100)
)

 if len(@products) > 0                
	insert into #products                
	select * from dbo.f_multivalue_parameter(@products,',')             

select	@follow_film = count(product)
from		#products
where	product = 1

select	@map = count(product)
from		#products
where	product = 2

select	@tap = count(product)
from		#products
where	product = 3

select	@roadblock = count(product)
from		#products
where	product = 4

select	@digilite = count(product)
from		#products
where	product = 5

select	@cineasia = count(product)
from		#products
where	product = 6

select	@first_run = count(product)
from		#products
where	product = 7

select	@summary = count(product)
from		#products
where	product = 8

if @follow_film = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			inclusion.campaign_no	,
							@screening_date,
							1,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							inclusion.inclusion_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							100,
							inclusion_desc
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 29
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.campaign_no,
							inclusion.inclusion_id,
							inclusion_desc
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			inclusion.campaign_no,
							@screening_date,
							1,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							100,
							''
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 29
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.campaign_no
	end
end

if @map = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			@campaign_no	,
							@screening_date,
							2,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							inclusion.inclusion_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							200,
							inclusion_desc
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 32
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.inclusion_id,
							inclusion_desc
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			inclusion.campaign_no,
							@screening_date,
							2,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							200,
							''
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 32
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.campaign_no
	end
end

if @tap = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			@campaign_no,
							@screening_date,
							3,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							inclusion.inclusion_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							300,
							inclusion_desc
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 24
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.inclusion_id,
							inclusion_desc
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			inclusion.campaign_no,
							@screening_date,
							3,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							300,
							''
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 24
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.campaign_no
	end
end

if @roadblock = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			@campaign_no	,
							@screening_date,
							4,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							inclusion.inclusion_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							400,
							inclusion_desc
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 30
		and				inclusion.campaign_no = @campaign_no
		and				inclusion.inclusion_id not in (select inclusion_id from inclusion_cinetam_package where package_id in (select package_id from campaign_category where movie_category_code in ('B', 'CA') and instruction_type = 2))
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.inclusion_id,
							inclusion_desc
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			@campaign_no	,
							@screening_date,
							4,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							400,
							''
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 30
		and				inclusion.campaign_no = @campaign_no
		and				inclusion.inclusion_id not in (select inclusion_id from inclusion_cinetam_package where package_id in (select package_id from campaign_category where movie_category_code in ('B', 'CA') and instruction_type = 2))
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.campaign_no
	end
end

if @digilite = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			@campaign_no	,
							@screening_date,
							5,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							cinelight_package.package_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							500,
							package_code
		from				cinelight_package
		inner join		cinelight_spot on cinelight_package.package_id = cinelight_spot.package_id
		where			cinelight_package.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		cinelight_package.package_id,
							package_code
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			cinelight_package.campaign_no,
							@screening_date,
							5,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							500,
							''
		from				cinelight_package
		inner join		cinelight_spot on cinelight_package.package_id = cinelight_spot.package_id
		where			cinelight_package.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		cinelight_package.campaign_no
	end
end

if @cineasia = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			@campaign_no	,
							@screening_date,
							6,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							inclusion.inclusion_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							600,
							inclusion_desc
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 30
		and				inclusion.campaign_no = @campaign_no
		and				inclusion.inclusion_id in (select inclusion_id from inclusion_cinetam_package where package_id in (select package_id from campaign_category where movie_category_code in ('B', 'CA') and instruction_type = 2))
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.inclusion_id,
							inclusion_desc
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			inclusion.campaign_no,
							@screening_date,
							6,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							600,
							''
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 30
		and				inclusion.campaign_no = @campaign_no
		and				inclusion.inclusion_id in (select inclusion_id from inclusion_cinetam_package where package_id in (select package_id from campaign_category where movie_category_code in ('B', 'CA') and instruction_type = 2))
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		group by		inclusion.campaign_no
	end
end

if @first_run = 1
begin
	if @consolidate_inclusions = 0
	begin
		insert into	#subreports 
		select			@campaign_no	,
							@screening_date,
							7,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							inclusion.inclusion_id,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							700,
							inclusion_desc
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 31
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		and				inclusion.inclusion_id in (select inclusion_id from inclusion_campaign_spot_xref where inclusion_id =  inclusion.inclusion_id )
		group by		inclusion.inclusion_id,
							inclusion_desc
	end
	else if @consolidate_inclusions = 1
	begin 
		insert into	#subreports 
		select			inclusion.campaign_no,
							@screening_date,
							7,
							@cinetam_reporting_demographics_id,
							@override_sold_demo,
							@consolidate_inclusions,
							null,
							@movie_breakdown,
							@weekly_breakdown,
							@graph	,
							@market_breakdown,
							@include_randf,
							700,
							''
		from				inclusion
		inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
		where			inclusion_type = 31
		and				inclusion.campaign_no = @campaign_no
		and				screening_date <= @screening_date
		and				spot_status = 'X'
		and				inclusion.inclusion_id in (select inclusion_id from inclusion_campaign_spot_xref where inclusion_id =  inclusion.inclusion_id )
		group by		inclusion.campaign_no
	end
end

if @summary = 1
begin
	insert into #subreports values
	(
	@campaign_no	,
	@screening_date,
	8,
	@cinetam_reporting_demographics_id,
	@override_sold_demo,
	@consolidate_inclusions,
	null,
	@movie_breakdown,
	@weekly_breakdown,
	@graph	,
	@market_breakdown,
	@include_randf,
	1000,
	''
	)
end

 select * from #subreports order by sort asc, sort_text asc

 return 0
GO
