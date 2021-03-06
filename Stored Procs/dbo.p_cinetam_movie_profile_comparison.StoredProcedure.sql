/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_profile_comparison]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_movie_profile_comparison]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_profile_comparison]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_movie_profile_comparison]		@country_code				char(1),
																							@aggregate_only			char(1),
																							@start_date					datetime,
																							@end_date					datetime,
																							@primary_movie			varchar(max),
																							@secondary_movies		varchar(max)
																							
as

declare			@error									int,
						@line_desc								varchar(200),
						@line_sort								int,
						@all_people_attendance		int,
						@m14_17								numeric(6,4),
						@m18_24								numeric(6,4),
						@m25_29								numeric(6,4),
						@m30_39								numeric(6,4),
						@m40_54								numeric(6,4),
						@m55_64								numeric(6,4),
						@m65_74								numeric(6,4),
						@m75_100								numeric(6,4),
						@f14_17									numeric(6,4),
						@f18_24								numeric(6,4),
						@f25_29								numeric(6,4),
						@f30_39								numeric(6,4),
						@f40_54								numeric(6,4),
						@f55_64								numeric(6,4),
						@f65_74								numeric(6,4),
						@f75_100								numeric(6,4),
						@under_14								numeric(6,4),
						@m14_17_att						int,
						@m18_24_att						int,
						@m25_29_att						int,
						@m30_39_att						int,
						@m40_54_att						int,
						@m55_64_att						int,
						@m65_74_att						int,
						@m75_100_att						int,
						@f14_17_att							int,
						@f18_24_att						int,
						@f25_29_att						int,
						@f30_39_att						int,
						@f40_54_att						int,
						@f55_64_att						int,
						@f65_74_att						int,
						@f75_100_att						int,
						@under_14_att						int,
						@over_14_att						int,
						@release_date						datetime	,
						@distributor_name				varchar(50),
						@category_desc					varchar(255),
						@classification_desc			varchar(50),
						@audience_demos					varchar(255),
						@loyalty_primary					numeric(6,4),
						@rows										int,
						@parm_orig							varchar(4000),
						@parm_type							varchar(3),
						@parm_string						varchar(10),
						@parm_int								int,
						@loyalty_tckts_primary		int,
						@loyalty_tckts						int,
						@csr_open								int,
						@cat_cnt								int,
						@cls_cnt								int

set nocount on

create table #primary_parameter 
(
	primary_param				varchar(4000)
)

create table #secondary_parameter 
(
	secondary_param			varchar(4000)
)

create table #primary_parameter_split 
(
	parm_value_int				int
)

create table #secondary_parameter_split 
(
	parm_type						varchar(3),
	parm_value_str				varchar(10),
	parm_value_int				int
)

create table #results
(
	line_desc							varchar(200)			null,
	line_sort								int							null,
	all_people_attendance		int							null,
	under_14							numeric(6,4)			null,
	m14_17								numeric(6,4)			null,
	m18_24								numeric(6,4)			null,
	m25_29								numeric(6,4)			null,
	m30_39								numeric(6,4)			null,
	m40_54								numeric(6,4)			null,
	m55_64								numeric(6,4)			null,
	m65_74								numeric(6,4)			null,
	m75_100								numeric(6,4)			null,
	f14_17								numeric(6,4)			null,
	f18_24								numeric(6,4)			null,
	f25_29								numeric(6,4)			null,
	f30_39								numeric(6,4)			null,
	f40_54								numeric(6,4)			null,
	f55_64								numeric(6,4)			null,
	f65_74								numeric(6,4)			null,
	f75_100								numeric(6,4)			null,
	release_date						datetime					null,
	distributor_name				varchar(50)			null,
	category_desc					varchar(255)			null,
	classification_desc			varchar(50)			null,
	audience_demos				varchar(255)			null,
	loyalty_primary					numeric(6,4)			null
)

create table #movio
(
	membership_id				varchar(50),
	movie_id							int
)

	

select @csr_open = 0

insert into #primary_parameter select * from dbo.f_multivalue_parameter(@primary_movie, ',')

declare		parm_csr  cursor static for
select			primary_param
from			#primary_parameter
order by		primary_param
for				read only	

open parm_csr
fetch parm_csr into @parm_orig
while(@@fetch_status = 0)
begin
	select		@parm_orig = ltrim(rtrim(@parm_orig))

	select	@parm_int = convert(int,@parm_orig)

	insert into 	#primary_parameter_split values (@parm_int)

	fetch parm_csr into @parm_orig
end	


close parm_csr
deallocate parm_csr

insert into #secondary_parameter select * from dbo.f_multivalue_parameter(@secondary_movies, ',')

declare		parm_csr  cursor static for
select			secondary_param
from			#secondary_parameter
order by		secondary_param
for				read only	

open parm_csr
fetch parm_csr into @parm_orig
while(@@fetch_status = 0)
begin
	select		@parm_type =  null,
					@parm_string = null,
					@parm_int = null

	select		@parm_orig = ltrim(rtrim(@parm_orig))

	select		@parm_type = left(@parm_orig, 3)
	
	if (@parm_type = 'Mov' or @parm_type = 'Cls')
	begin
		select	@parm_int = convert(int, right(@parm_orig, len(@parm_orig) - 3))
	end
	else	
	begin
		select	@parm_string = right(@parm_orig, len(@parm_orig) - 3)
	end
		
	insert into 	#secondary_parameter_split values (@parm_type, @parm_string, @parm_int)

	fetch parm_csr into @parm_orig
end	

close parm_csr
deallocate parm_csr

--if there is more than one primary parameter inside a header row
select @rows = count(*) from #primary_parameter_split

if	@rows > 1
begin	
	select		@line_sort = 1, 
					@line_desc = 'Selected Primary Movies', 
					@release_date  = null, 
					@distributor_name = '', 
					@category_desc = '', 
					@classification_desc = '', 
					@audience_demos = '', 
					@loyalty_primary = null

	select	@all_people_attendance = sum(attendance) from movie_history where country = @country_code and movie_id in (select parm_value_int from #primary_parameter_split)
	select	@m14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 1
	select	@m18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 2
	select	@m25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 3
	select	@m30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 4
	select	@m40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 5
	select	@m55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 6
	select	@m65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 7
	select	@m75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 8
	select	@f14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 9
	select	@f18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 10
	select	@f25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 11
	select	@f30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 12
	select	@f40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 13
	select	@f55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 14
	select	@f65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 15
	select	@f75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split) and cinetam_demographics_id = 16
	select @over_14_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id in (select parm_value_int from #primary_parameter_split)

	select @under_14_att = @all_people_attendance - @over_14_att

	select	@m14_17 = convert(numeric(20,10), @m14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m18_24 = convert(numeric(20,10), @m18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m25_29 = convert(numeric(20,10), @m25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m30_39 = convert(numeric(20,10), @m30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m40_54 = convert(numeric(20,10), @m40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m55_64 = convert(numeric(20,10), @m55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m65_74 = convert(numeric(20,10), @m65_74_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m75_100 =  convert(numeric(20,10), @m75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f14_17 =  convert(numeric(20,10), @f14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f18_24 = convert(numeric(20,10), @f18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f25_29 =convert(numeric(20,10),  @f25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f30_39 =  convert(numeric(20,10), @f30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f40_54 =  convert(numeric(20,10), @f40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f55_64 =  convert(numeric(20,10), @f55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f65_74 =  convert(numeric(20,10), @f65_74_att) /convert(numeric(20,10),  @all_people_attendance)
	select	@f75_100 = convert(numeric(20,10), @f75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select @under_14 = convert(numeric(20,10), @under_14_att) / convert(numeric(20,10), @all_people_attendance)

	insert into #results values (@line_desc,	@line_sort,	@all_people_attendance,	@under_14,	@m14_17,	@m18_24,	@m25_29,	@m30_39,	@m40_54,	@m55_64,	@m65_74,	@m75_100,	@f14_17,	@f18_24,	@f25_29,	@f30_39,	@f40_54,	@f55_64,	@f65_74,	@f75_100,	@release_date,	@distributor_name,	@category_desc,	@classification_desc,	@audience_demos,	@loyalty_primary)
	insert into #results values ('Primary Movies',	2,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null)	
end	

declare		parm_csr  cursor static for
select			movie_id, 
					10,
					long_name
from			movie, 
					#primary_parameter_split 
where			movie.movie_id = #primary_parameter_split.parm_value_int 
order by		movie_id
for				read only	

open parm_csr
select @csr_open = 1
fetch parm_csr into @parm_int, @line_sort, @line_desc
while(@@fetch_status = 0)
begin
	select		@release_date  = release_date,
					@distributor_name = distributor_name
	from		movie,
					movie_country,
					distributors
	where		movie.movie_id = movie_country.movie_id
	and			movie_country.country_code = @country_code
	and			movie_country.distributor_id = distributors.distributor_id
	and			movie.movie_id = @parm_int
	
	select @category_desc = dbo.f_movie_categories(@parm_int)
	
	select @classification_desc = classification_desc from movie, movie_country, classification where movie.movie_id = movie_country.movie_id and movie_country.classification_id = classification.classification_id and movie.movie_id = @parm_int and movie_country.country_code = @country_code
	
	select	@all_people_attendance = sum(attendance) from movie_history where country = @country_code and movie_id = @parm_int
	select	@m14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 1
	select	@m18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 2
	select	@m25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 3
	select	@m30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 4
	select	@m40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 5
	select	@m55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 6
	select	@m65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 7
	select	@m75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 8
	select	@f14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 9
	select	@f18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 10
	select	@f25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 11
	select	@f30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 12
	select	@f40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 13
	select	@f55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 14
	select	@f65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 15
	select	@f75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 16
	select @over_14_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int

	select @under_14_att = @all_people_attendance - @over_14_att

	select	@m14_17 = convert(numeric(20,10), @m14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m18_24 = convert(numeric(20,10), @m18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m25_29 = convert(numeric(20,10), @m25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m30_39 = convert(numeric(20,10), @m30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m40_54 = convert(numeric(20,10), @m40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m55_64 = convert(numeric(20,10), @m55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m65_74 = convert(numeric(20,10), @m65_74_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m75_100 =  convert(numeric(20,10), @m75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f14_17 =  convert(numeric(20,10), @f14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f18_24 = convert(numeric(20,10), @f18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f25_29 =convert(numeric(20,10),  @f25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f30_39 =  convert(numeric(20,10), @f30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f40_54 =  convert(numeric(20,10), @f40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f55_64 =  convert(numeric(20,10), @f55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f65_74 =  convert(numeric(20,10), @f65_74_att) /convert(numeric(20,10),  @all_people_attendance)
	select	@f75_100 = convert(numeric(20,10), @f75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select @under_14 = convert(numeric(20,10), @under_14_att) / convert(numeric(20,10), @all_people_attendance)
	
	insert into #results values (@line_desc,	@line_sort,	@all_people_attendance,	@under_14,	@m14_17,	@m18_24,	@m25_29,	@m30_39,	@m40_54,	@m55_64,	@m65_74,	@m75_100,	@f14_17,	@f18_24,	@f25_29,	@f30_39,	@f40_54,	@f55_64,	@f65_74,	@f75_100,	@release_date,	@distributor_name,	@category_desc,	@classification_desc,	@audience_demos,	@loyalty_primary)


	fetch parm_csr into @parm_int, @line_sort, @line_desc
end	

if @csr_open = 1
begin
	insert into #results values ('',	11,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null)	
	select @csr_open = 0
end	

close parm_csr
deallocate parm_csr

select			@cat_cnt = count(*)
from			#secondary_parameter_split 
where			#secondary_parameter_split.parm_type = 'Cat'

select			@cls_cnt = count(*)
from			#secondary_parameter_split 
where			#secondary_parameter_split.parm_type = 'Cls'

insert		into #movio 
select		distinct membership_id, 
				movie_id 
from		v_movio_data_demo_movie_fsd
where		country_code = @country_code
and			movie_id in (select parm_value_int from #primary_parameter_split )

insert		into #movio 
select		distinct membership_id, 
				movie_id 
from		v_movio_data_demo_movie_fsd
where		country_code = @country_code
and			movie_id in (select			movie_id
									from			movie, 
														#secondary_parameter_split 
									where			movie.movie_id = #secondary_parameter_split.parm_value_int 
									and				parm_type = 'Mov'
									union
									select			movie.movie_id
									from			movie,
														movie_history
									where			movie.movie_id = movie_history.movie_id
									and				country = @country_code 
									and				screening_date between @start_date and @end_date
									and				((@cat_cnt > 0 
									and				@cls_cnt > 0						
									and				movie.movie_id in (select			movie.movie_id
																						from			movie, 
																											target_categories,
																											#secondary_parameter_split 
																						where			movie.movie_id = target_categories.movie_id
																						and				movie_category_code = #secondary_parameter_split.parm_value_str
																						and				#secondary_parameter_split.parm_type = 'Cat')
									and				movie.movie_id in (select			movie.movie_id
																						from			movie, 
																											movie_country,
																											#secondary_parameter_split 
																						where			movie.movie_id = movie_country.movie_id
																						and				classification_id = #secondary_parameter_split.parm_value_int
																						and				#secondary_parameter_split.parm_type = 'Cls'))
									or					(@cat_cnt > 0 
									and				@cls_cnt = 0
									and				movie.movie_id in (select			movie.movie_id
																						from			movie, 
																											target_categories,
																											#secondary_parameter_split 
																						where			movie.movie_id = target_categories.movie_id
																						and				movie_category_code = #secondary_parameter_split.parm_value_str
																						and				#secondary_parameter_split.parm_type = 'Cat'))													
									or					(@cat_cnt = 0
									and				@cls_cnt > 0
									and				movie.movie_id in (select			movie.movie_id
																						from			movie, 
																											movie_country,
																											#secondary_parameter_split 
																						where			movie.movie_id = movie_country.movie_id
																						and				classification_id = #secondary_parameter_split.parm_value_int
																						and				#secondary_parameter_split.parm_type = 'Cls'))))

declare		parm_csr  cursor static for
select			movie_id, 
					70,
					long_name
from			movie, 
					#secondary_parameter_split 
where			movie.movie_id = #secondary_parameter_split.parm_value_int 
and				parm_type = 'Mov'
union
select			movie.movie_id,
					70,
					movie.long_name
from			movie,
					movie_history
where			movie.movie_id = movie_history.movie_id
and				country = @country_code 
and				screening_date between @start_date and @end_date
and				((@cat_cnt > 0 
and				@cls_cnt > 0						
and				movie.movie_id in (select			movie.movie_id
													from			movie, 
																		target_categories,
																		#secondary_parameter_split 
													where			movie.movie_id = target_categories.movie_id
													and				movie_category_code = #secondary_parameter_split.parm_value_str
													and				#secondary_parameter_split.parm_type = 'Cat')
and				movie.movie_id in (select			movie.movie_id
													from			movie, 
																		movie_country,
																		#secondary_parameter_split 
													where			movie.movie_id = movie_country.movie_id
													and				classification_id = #secondary_parameter_split.parm_value_int
													and				#secondary_parameter_split.parm_type = 'Cls'))
or					(@cat_cnt > 0 
and				@cls_cnt = 0
and				movie.movie_id in (select			movie.movie_id
													from			movie, 
																		target_categories,
																		#secondary_parameter_split 
													where			movie.movie_id = target_categories.movie_id
													and				movie_category_code = #secondary_parameter_split.parm_value_str
													and				#secondary_parameter_split.parm_type = 'Cat'))													
or					(@cat_cnt = 0
and				@cls_cnt > 0
and				movie.movie_id in (select			movie.movie_id
													from			movie, 
																		movie_country,
																		#secondary_parameter_split 
													where			movie.movie_id = movie_country.movie_id
													and				classification_id = #secondary_parameter_split.parm_value_int
													and				#secondary_parameter_split.parm_type = 'Cls')))													
order by		movie_id
for				read only	

open parm_csr
fetch parm_csr into @parm_int, @line_sort, @line_desc
while(@@fetch_status = 0)
begin
	select		@release_date  = release_date,
					@distributor_name = distributor_name
	from		movie,
					movie_country,
					distributors
	where		movie.movie_id = movie_country.movie_id
	and			movie_country.country_code = @country_code
	and			movie_country.distributor_id = distributors.distributor_id
	and			movie.movie_id = @parm_int
	
	select @category_desc = dbo.f_movie_categories(@parm_int)
	select @classification_desc = classification_desc from movie, movie_country, classification where movie.movie_id = movie_country.movie_id and movie_country.classification_id = classification.classification_id and movie.movie_id = @parm_int and movie_country.country_code = @country_code
	
	select		@loyalty_tckts_primary =  isnull(count(distinct membership_id),0)
	from		#movio
	where		movie_id in (select parm_value_int from #primary_parameter_split )
	and			membership_id in (select		distinct membership_id
													from		#movio
													where		movie_id = @parm_int)
	
	select		@loyalty_tckts	= isnull(count(distinct membership_id),0)
	from		#movio
	where		movie_id = @parm_int
	
	if @loyalty_tckts > 0 
		select @loyalty_primary = convert(numeric(20,10), @loyalty_tckts_primary) / convert(numeric(20,10), @loyalty_tckts)
	else
		select @loyalty_primary = 0.0
	
		
	select	@all_people_attendance = sum(attendance) from movie_history where country = @country_code and movie_id = @parm_int
	select	@m14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 1
	select	@m18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 2
	select	@m25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 3
	select	@m30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 4
	select	@m40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 5
	select	@m55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 6
	select	@m65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 7
	select	@m75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 8
	select	@f14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 9
	select	@f18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 10
	select	@f25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 11
	select	@f30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 12
	select	@f40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 13
	select	@f55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 14
	select	@f65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 15
	select	@f75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int and cinetam_demographics_id = 16
	select @over_14_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and movie_id = @parm_int

	select @under_14_att = @all_people_attendance - @over_14_att

	select	@m14_17 = convert(numeric(20,10), @m14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m18_24 = convert(numeric(20,10), @m18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m25_29 = convert(numeric(20,10), @m25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m30_39 = convert(numeric(20,10), @m30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m40_54 = convert(numeric(20,10), @m40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m55_64 = convert(numeric(20,10), @m55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m65_74 = convert(numeric(20,10), @m65_74_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m75_100 =  convert(numeric(20,10), @m75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f14_17 =  convert(numeric(20,10), @f14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f18_24 = convert(numeric(20,10), @f18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f25_29 =convert(numeric(20,10),  @f25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f30_39 =  convert(numeric(20,10), @f30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f40_54 =  convert(numeric(20,10), @f40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f55_64 =  convert(numeric(20,10), @f55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f65_74 =  convert(numeric(20,10), @f65_74_att) /convert(numeric(20,10),  @all_people_attendance)
	select	@f75_100 = convert(numeric(20,10), @f75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select @under_14 = convert(numeric(20,10), @under_14_att) / convert(numeric(20,10), @all_people_attendance)
	
	insert into #results values (@line_desc,	@line_sort,	@all_people_attendance,	@under_14,	@m14_17,	@m18_24,	@m25_29,	@m30_39,	@m40_54,	@m55_64,	@m65_74,	@m75_100,	@f14_17,	@f18_24,	@f25_29,	@f30_39,	@f40_54,	@f55_64,	@f65_74,	@f75_100,	@release_date,	@distributor_name,	@category_desc,	@classification_desc,	@audience_demos,	@loyalty_primary)

	fetch parm_csr into @parm_int, @line_sort, @line_desc
end	

close parm_csr
deallocate parm_csr

select @loyalty_primary = null
	
declare		parm_csr  cursor static for
select			movie_category_code, 
					30,
					movie_category_desc
from			movie_category,
					#secondary_parameter_split 
where			rtrim(convert(varchar(2), movie_category_code)) = #secondary_parameter_split.parm_value_str
and				#secondary_parameter_split.parm_type = 'Cat' 
order by		movie_category_desc
for				read only

open parm_csr
select @csr_open = 1
fetch parm_csr into @parm_string, @line_sort, @line_desc
while(@@fetch_status = 0)
begin
	select		@release_date  = null,
					@distributor_name = null,
					@category_desc = null,
					@classification_desc = null
					
	
	select	@all_people_attendance = sum(attendance) from movie_history where country = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string)
	select	@m14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 1
	select	@m18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 2
	select	@m25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 3
	select	@m30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 4
	select	@m40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 5
	select	@m55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 6
	select	@m65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 7
	select	@m75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 8
	select	@f14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 9
	select	@f18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 10
	select	@f25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 11
	select	@f30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 12
	select	@f40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 13
	select	@f55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 14
	select	@f65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 15
	select	@f75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string) and cinetam_demographics_id = 16
	select @over_14_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from target_categories where movie_category_code = @parm_string)

	select @under_14_att = @all_people_attendance - @over_14_att

	select	@m14_17 = convert(numeric(20,10), @m14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m18_24 = convert(numeric(20,10), @m18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m25_29 = convert(numeric(20,10), @m25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m30_39 = convert(numeric(20,10), @m30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m40_54 = convert(numeric(20,10), @m40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m55_64 = convert(numeric(20,10), @m55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m65_74 = convert(numeric(20,10), @m65_74_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m75_100 = convert(numeric(20,10), @m75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f14_17 =  convert(numeric(20,10), @f14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f18_24 = convert(numeric(20,10), @f18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f25_29 =convert(numeric(20,10),  @f25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f30_39 =  convert(numeric(20,10), @f30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f40_54 =  convert(numeric(20,10), @f40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f55_64 =  convert(numeric(20,10), @f55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f65_74 =  convert(numeric(20,10), @f65_74_att) /convert(numeric(20,10),  @all_people_attendance)
	select	@f75_100 = convert(numeric(20,10), @f75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select @under_14 = convert(numeric(20,10), @under_14_att) / convert(numeric(20,10), @all_people_attendance)
	
	insert into #results values (@line_desc,	@line_sort,	@all_people_attendance,	@under_14,	@m14_17,	@m18_24,	@m25_29,	@m30_39,	@m40_54,	@m55_64,	@m65_74,	@m75_100,	@f14_17,	@f18_24,	@f25_29,	@f30_39,	@f40_54,	@f55_64,	@f65_74,	@f75_100,	@release_date,	@distributor_name,	@category_desc,	@classification_desc,	@audience_demos,	@loyalty_primary)

	fetch parm_csr into @parm_string, @line_sort, @line_desc
end	

if @csr_open = 1
begin
	insert into #results values ('',	31,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null)	
	select @csr_open = 0
end	

close parm_csr
deallocate parm_csr

declare		parm_csr  cursor static for
select			classification_id, 
					40 + sequence_no,
					classification_desc
from			classification,
					#secondary_parameter_split 
where			classification_id = #secondary_parameter_split.parm_value_int
and				#secondary_parameter_split.parm_type = 'Cls' 
order by		sequence_no
for				read only

open parm_csr
select @csr_open = 1
fetch parm_csr into @parm_int, @line_sort, @line_desc
while(@@fetch_status = 0)
begin
	select		@release_date  = null,
					@distributor_name = null,
					@category_desc = null,
					@classification_desc = null
					
	
	select	@all_people_attendance = sum(attendance) from movie_history where country = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int)
	select	@m14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 1
	select	@m18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 2
	select	@m25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 3
	select	@m30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 4
	select	@m40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 5
	select	@m55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 6
	select	@m65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 7
	select	@m75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 8
	select	@f14_17_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 9
	select	@f18_24_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 10
	select	@f25_29_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 11
	select	@f30_39_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 12
	select	@f40_54_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 13
	select	@f55_64_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 14
	select	@f65_74_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 15
	select	@f75_100_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int) and cinetam_demographics_id = 16
	select @over_14_att = sum(attendance) from cinetam_movie_history where country_code = @country_code and screening_date between @start_date and @end_date and movie_id in (select movie_id from movie_country where classification_id = @parm_int)

	select @under_14_att = @all_people_attendance - @over_14_att

	select	@m14_17 = convert(numeric(20,10), @m14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m18_24 = convert(numeric(20,10), @m18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m25_29 = convert(numeric(20,10), @m25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m30_39 = convert(numeric(20,10), @m30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m40_54 = convert(numeric(20,10), @m40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m55_64 = convert(numeric(20,10), @m55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m65_74 = convert(numeric(20,10), @m65_74_att) / convert(numeric(20,10), @all_people_attendance)
	select	@m75_100 = convert(numeric(20,10), @m75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f14_17 =  convert(numeric(20,10), @f14_17_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f18_24 = convert(numeric(20,10), @f18_24_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f25_29 =convert(numeric(20,10),  @f25_29_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f30_39 =  convert(numeric(20,10), @f30_39_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f40_54 =  convert(numeric(20,10), @f40_54_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f55_64 =  convert(numeric(20,10), @f55_64_att) / convert(numeric(20,10), @all_people_attendance)
	select	@f65_74 =  convert(numeric(20,10), @f65_74_att) /convert(numeric(20,10),  @all_people_attendance)
	select	@f75_100 = convert(numeric(20,10), @f75_100_att) / convert(numeric(20,10), @all_people_attendance)
	select @under_14 = convert(numeric(20,10), @under_14_att) / convert(numeric(20,10), @all_people_attendance)
	
	insert into #results values (@line_desc,	@line_sort,	@all_people_attendance,	@under_14,	@m14_17,	@m18_24,	@m25_29,	@m30_39,	@m40_54,	@m55_64,	@m65_74,	@m75_100,	@f14_17,	@f18_24,	@f25_29,	@f30_39,	@f40_54,	@f55_64,	@f65_74,	@f75_100,	@release_date,	@distributor_name,	@category_desc,	@classification_desc,	@audience_demos,	@loyalty_primary)

	fetch parm_csr into @parm_int, @line_sort, @line_desc
end	

if @csr_open = 1
begin
	insert into #results values ('',	60,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null,	null)	
	select @csr_open = 0
end	

close parm_csr
deallocate parm_csr


select 			line_desc,
					line_sort,
					all_people_attendance,
					under_14,
					m14_17,
					m18_24,
					m25_29,
					m30_39,
					m40_54,
					m55_64,
					m65_74,
					m75_100,
					f14_17,
					f18_24,
					f25_29,
					f30_39,
					f40_54,
					f55_64,
					f65_74,
					f75_100,
					release_date,
					distributor_name,
					category_desc,
					classification_desc,
					audience_demos,
					loyalty_primary
from			#results
order by		line_sort, 
					line_desc

return 0
GO
