/****** Object:  StoredProcedure [dbo].[p_pda_package_instruction_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pda_package_instruction_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_pda_package_instruction_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_pda_package_instruction_summary]		@campaign_no	int

as

declare		@error							int,
			@followed_movies				varchar(800),
			@preferred_movies				varchar(800),
			@restricted_movies				varchar(800),
			@restricted_audiences			varchar(800),
			@movie_categories_prefer		varchar(800),
			@movie_categories_restrict		varchar(800),
			@restricted_classifications		varchar(800),
			@makeups_owing					int,
			@makeups_performed				int,
			@spot_count						int,
			@average_rate					money,
			@short_name						varchar(30),
			@package_id						int,
			@instruction_type 				int,
			@min_age						int,
			@max_age						int

set nocount on

create table #packages
(
	package_id					int				null,
	package_desc				varchar(100)	null,
	product_category_desc		varchar(100)	null,
	start_date					datetime		null,
	used_by_date				datetime		null,
    media_product_id        	smallint     	null,
    package_code            	char(1)       	null,
    campaign_package_status 	char(1)       	null,
    rate                    	money         	null,
    charge_rate             	money         	null,
    print_ratio             	char(1)       	null,
    prints                  	smallint      	null,
    capacity_prints         	smallint      	null,
    alloc_prints            	smallint      	null,
    duration                	smallint      	null,
    capacity_duration       	smallint      	null,
    alloc_duration          	smallint      	null,
    screening_position      	tinyint       	null,
    screening_trailers      	char(1)       	null,
    school_holidays         	tinyint       	null,
    follow_film             	char(1)       	null,
    movie_mix               	char(1)       	null,
    movie_bands             	char(1)       	null,
    movie_band_variable     	smallint     	null,
    certificate_priority    	smallint      	null,
    client_clash            	char(1)       	null,
    movie_brief             	varchar(100) 	null,
    ins_complete            	char(1)       	null,
    makeups_owing           	smallint      	null,
    makeups_performed       	smallint      	null,
    average_rate            	money         	null,
    spot_count              	int           	null,
    band_id                	 	int           	null,
    allow_product_clashing  	char(1)       	null,
    follow_film_restricted  	char(1)       	null,
    client_diff_product     	char(1)      	null,
    revenue_source          	char(1)       	null,
    premium_screen_type     	char(1)       	null,
    all_movies              	char(1)       	null,
    cinema_exclusive        	char(1)       	null,
	followed_movies				varchar(800)	null,
	preferred_movies			varchar(800)	null,
	restricted_movies			varchar(800)	null,
	restricted_audiences		varchar(800)	null,
	movie_categories_prefer		varchar(800)	null,
	movie_categories_restrict	varchar(800)	null,
	restricted_classifications 	varchar(800)	null,
	allow_market_makeups		char(1)			null,
	allow_package_clashing		char(1)			null
)	

insert into #packages
(
	package_id,
	package_desc,
	product_category_desc,
    media_product_id,
    package_code,
    start_date,
    used_by_date,
    campaign_package_status,
    rate,
    charge_rate,
    print_ratio,
    prints,
    capacity_prints,
    alloc_prints,
    duration,
    capacity_duration,
    alloc_duration,
    screening_position,
    screening_trailers,
    school_holidays,
    follow_film,
    movie_mix,
    movie_bands,
    movie_band_variable,
    certificate_priority,
    client_clash,
    movie_brief,
    ins_complete,
    makeups_owing,
    makeups_performed,
    average_rate,
    spot_count,
    band_id,
    allow_product_clashing,
    follow_film_restricted,
    client_diff_product,
    revenue_source,
    premium_screen_type,
    all_movies,
    cinema_exclusive,
	allow_market_makeups,
	allow_package_clashing
) select 	package_id,
	package_desc,
	product_category_desc,
    media_product_id,
    package_code,
    (case campaign_package.start_date when null then film_campaign.start_date else campaign_package.start_date end) as start_date,
    used_by_date,
    campaign_package_status,
    rate,
    charge_rate,
    print_ratio,
    prints,
    capacity_prints,
    alloc_prints,
    duration,
    capacity_duration,
    alloc_duration,
    screening_position,
    screening_trailers,
    school_holidays,
    follow_film,
    movie_mix,
    movie_bands,
    movie_band_variable,
    certificate_priority,
    client_clash,
    'Movie Brief: ' + movie_brief,
    ins_complete,
    makeups_owing,
    makeups_performed,
    average_rate,
    spot_count,
    band_id,
    allow_product_clashing,
    follow_film_restricted,
    client_diff_product,
    revenue_source,
    premium_screen_type,
    all_movies,
    cinema_exclusive,
	allow_market_makeups,
	allow_pack_clashing
from 	campaign_package, product_category, film_campaign
where 	campaign_package.campaign_no = @campaign_no
and		campaign_package.product_category = product_category.product_category_id
and		film_campaign.campaign_no = campaign_package.campaign_no

declare 	package_csr cursor forward_only static for
select		package_id
from		#packages
order by 	package_id
for			read only




open package_csr
fetch package_csr into @package_id
while(@@fetch_status=0)
begin

	select 	@followed_movies = '',
			@preferred_movies = '',
			@restricted_movies = '',
			@restricted_audiences = '',
			@movie_categories_prefer = '',
			@movie_categories_restrict = '',
			@restricted_classifications = '',
			@makeups_performed = 0,
			@makeups_owing = 0,
			@spot_count = 0,
			@average_rate = 0.0

	declare 	follow_csr cursor forward_only static for
	select 		short_name,
				instruction_type
	from		movie,
				movie_screening_instructions
	where		package_id = @package_id
	and			movie.movie_id = movie_screening_instructions.movie_id
	order by 	sequence_no

	open follow_csr
	fetch follow_csr into @short_name, @instruction_type
	while(@@fetch_status = 0 )
	begin

		if @instruction_type = 1
		begin
			if @followed_movies = ''
				select @followed_movies = @followed_movies + @short_name
			else	
				select @followed_movies = @followed_movies + ', ' + @short_name

		end	

		if @instruction_type = 2
		begin
			if @preferred_movies = ''  
				select @preferred_movies = @preferred_movies + @short_name
			else
				select @preferred_movies = @preferred_movies + ', ' + @short_name
		end	

		if @instruction_type = 3
		begin
			if @restricted_movies = ''
				select @restricted_movies = @restricted_movies + @short_name
			else
				select @restricted_movies = @restricted_movies + ', ' + @short_name
		end	

		fetch follow_csr into @short_name, @instruction_type
	end 
	
	deallocate follow_csr

	declare 	movie_category_csr cursor forward_only static for
	select 		movie_category_desc,
				instruction_type
	from		movie_category,
				campaign_category
	where		package_id = @package_id
	and			movie_category.movie_category_code = campaign_category.movie_category_code
	order by 	movie_category.movie_category_code

	open movie_category_csr
	fetch movie_category_csr into @short_name, @instruction_type
	while(@@fetch_status = 0 )
	begin

		if @instruction_type = 2
		begin
			if @movie_categories_prefer = ''
				select @movie_categories_prefer = @movie_categories_prefer + @short_name
			else
				select @movie_categories_prefer = @movie_categories_prefer + ', ' + @short_name
		end	

		if @instruction_type = 3
		begin
			if @movie_categories_restrict = ''
				select @movie_categories_restrict = @movie_categories_restrict + @short_name
			else
				select @movie_categories_restrict = @movie_categories_restrict + ', ' + @short_name
		end	

		fetch movie_category_csr into @short_name, @instruction_type
	end 
	
	deallocate movie_category_csr

	declare 	audience_profile_csr cursor forward_only static for
	select 		convert(varchar(30), (sex + ' ' + convert(varchar(3), min_age) + ' - ' + convert(varchar(3), max_age))),
				instruction_type
	from		audience_profile,
				campaign_audience
	where		package_id = @package_id
	and			audience_profile.audience_profile_code = campaign_audience.audience_profile_code
	order by 	min_age ASC, sex DESC


	open audience_profile_csr
	fetch audience_profile_csr into @short_name, @instruction_type
	while(@@fetch_status = 0 )
	begin

		if @instruction_type = 2
		begin
			if @restricted_audiences = ''
				select @restricted_audiences = @restricted_audiences + @short_name
			else
				select @restricted_audiences = @restricted_audiences + ', ' + @short_name
		end	

		fetch audience_profile_csr into @short_name, @instruction_type
	end 
	
	deallocate audience_profile_csr

	declare 	movie_classification_csr cursor forward_only static for
	select 		country_code + ' - ' + classification_code,
				instruction_type
	from		classification,
				campaign_classification
	where		package_id = @package_id
	and			classification.classification_id = campaign_classification.classification_id
	order by 	country_code,sequence_no


	open movie_classification_csr
	fetch movie_classification_csr into @short_name, @instruction_type
	while(@@fetch_status = 0 )
	begin

		if @instruction_type = 2
		begin
			if @restricted_classifications = ''
				select @restricted_classifications = @restricted_classifications + @short_name
			else
				select @restricted_classifications = @restricted_classifications + ', ' + @short_name
		end	

		fetch movie_classification_csr into @short_name, @instruction_type
	end 
	
	deallocate movie_classification_csr

	select 	@makeups_performed = count(spot_id)
	from	campaign_spot
	where 	package_id = @package_id 
	and		(spot_type = 'M'
	or		spot_type = 'V')


	select 	@makeups_owing = count(spot_id)
	from	campaign_spot
	where 	package_id = @package_id 
	and		spot_type <> 'G'
	and		spot_type <> 'Y'
	and		(spot_status = 'U'
	or		spot_status = 'N')

	select 	@spot_count = count(spot_id),
			@average_rate = avg(isnull(charge_rate,0))
	from	campaign_spot
	where 	package_id = @package_id 
	and		spot_type <> 'M'
	and		spot_type <> 'V'

	if @followed_movies = ''
		select @followed_movies = 'None'
	if 	@preferred_movies = ''
		select @preferred_movies = 'None'
	if 	@restricted_movies = ''
		select @restricted_movies = 'None'
	if 	@restricted_audiences = ''
		select @restricted_audiences = 'None'
	if 	@movie_categories_prefer = ''
		select @movie_categories_prefer = 'None'
	if 	@movie_categories_restrict = ''
		select @movie_categories_restrict = 'None'
	if 	@restricted_classifications = ''
		select @restricted_classifications = 'None'

	update  #packages
	set		followed_movies = @followed_movies,
			preferred_movies = @preferred_movies,
			restricted_movies = @restricted_movies,
			restricted_audiences = @restricted_audiences,
			movie_categories_prefer = @movie_categories_prefer,
			movie_categories_restrict = @movie_categories_restrict,
			restricted_classifications = @restricted_classifications,
			makeups_owing = @makeups_owing,
		    makeups_performed = @makeups_performed,
		    average_rate = @average_rate,
		    spot_count = @spot_count

	where	package_id = @package_id 

	fetch package_csr into @package_id
end

select package_id,
	package_desc,
	product_category_desc,
	start_date,
	used_by_date,
    media_product_id,
    package_code,
    campaign_package_status,
    rate,
    charge_rate,
    print_ratio,
    prints,
    capacity_prints,
    alloc_prints,
    duration,
    capacity_duration,
    alloc_duration,
    screening_position,
    screening_trailers,
    school_holidays,
    follow_film,
    movie_mix,
    movie_bands,
    movie_band_variable,
    certificate_priority,
    client_clash,
    movie_brief,
    ins_complete,
    makeups_owing,
    makeups_performed,
    average_rate,
    spot_count,
    band_id,
    allow_product_clashing,
    follow_film_restricted,
    client_diff_product,
    revenue_source,
    premium_screen_type,
    all_movies,
    cinema_exclusive,
	followed_movies,
	preferred_movies,
	restricted_movies,
	restricted_audiences,
	movie_categories_prefer,
	movie_categories_restrict,
	restricted_classifications,
	allow_market_makeups,
	allow_package_clashing
from #packages

return 0
GO
