/****** Object:  StoredProcedure [dbo].[p_mycampaign_movie_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mycampaign_movie_list]
GO
/****** Object:  StoredProcedure [dbo].[p_mycampaign_movie_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        PROC	[dbo].[p_mycampaign_movie_list]		@arg_country_code	char(1),
												@arg_movie_id		int,
												@arg_package_id		int,
												@arg_revision_no		int,
												@arg_screening_date	datetime
as

declare		@error					int,
			@long_name				varchar(50),
			@short_name				varchar(20),
			@movie_id				int,
			@country_code			char(1),
			@release_date			datetime,
			@classification_code	char(5),
			@movie_category_desc	varchar(30),
			@target_audience_desc	varchar(30),
			@target_audiences_desc	varchar(100),
			@follow_film			char(1),
			@follow_film_restricted	char(1),
			@score					int,
			@count					int,
			@movie_age_addition		int,
			@movie_age_offset		int,
			@movie_age				int,
			@classification			char(5),
			@three_d_type_pack		int,
			@digital_pack			int,
			@three_d_type_movie		int,
			@three_d_modifier		int,
			@dimension_preference	int,	--DYI 2012-07-26
			@dim_pref_vs_movie 		int		--DYI 2012-07-26


set nocount on

/*
 * Create Temp Table
 */

create table	#mycampaign_list
(
	long_name				varchar(50) 	null,
	short_name				varchar(20) 	null,
	movie_id				int 			null,
	country_code			char(1) 		null,
	release_date			datetime 		null,
	classification_code		char(5) 		null,
	movie_category_desc 	varchar(30) 	null,
	target_audiences_desc	varchar(100) 	null,
	score					int 			null,
	three_d_modifier		int				null,
	dimension_pref_score	int				NULL		--DYI 2012-07-26
)


/*
 * Declare Cursor
 */

SELECT		@follow_film = follow_film,
			@follow_film_restricted = follow_film_restricted,
			@dimension_preference = dimension_preference
FROM		campaign_package_ins_rev
WHERE		package_id = @arg_package_id 
and			revision_no = @arg_revision_no

/*
 * Load Package 3D & Digital
 */

select 	@three_d_type_pack 	= count(print_package.print_package_id)
from	print_package,
		print_package_three_d
where	print_package.print_package_id = print_package_three_d.print_package_id
and		print_package.package_id = @arg_package_id
and		three_d_type > 1

select 	@digital_pack = count(print_medium)
from	print_package,
		print_package_medium
where	print_package.print_package_id = print_package_medium.print_package_id
and		print_package.package_id = @arg_package_id
and		print_medium = 'D'
            
declare		campaign_csr cursor forward_only static for
SELECT		movie.long_name,   
			movie.short_name,   
			movie.movie_id,
			movie_country.country_code,
			movie_country.release_date,
			classification_code,
			(SELECT 	max(movie_category.movie_category_desc)
			FROM		movie_category,
						target_categories  
			WHERE		( movie_category.movie_category_code = target_categories.movie_category_code ) and  
						( ( target_categories.movie_id = movie.movie_id ) ) )  category_desc
FROM		movie,
			movie_country,
			classification
WHERE		((movie_country.active = 'Y' AND
			@arg_movie_id is null	) or
			@arg_movie_id = movie.movie_id	) and
			movie.movie_id = movie_country.movie_id	AND
			movie_country.classification_id = classification.classification_id AND
			(	movie_country.country_code = @arg_country_code
			or isnull(@arg_country_code, '') = '')
ORDER BY	movie.long_name ASC 


open		campaign_csr
fetch		campaign_csr
into		@long_name,
			@short_name,
			@movie_id,
			@country_code,
			@release_date,
			@classification_code,
			@movie_category_desc
while(@@fetch_status=0)
begin

	select @target_audiences_desc = '' 

	declare		movie_csr cursor forward_only static for
	SELECT		'['+audience_profile.audience_profile_code+'] '+ cast(min_age as varchar(2)) + '-'+cast(max_age as varchar(2))  
	FROM		audience_profile,   
			target_audience  
	WHERE		(	target_audience.audience_profile_code = audience_profile.audience_profile_code ) and  
			(	( target_audience.movie_id = @movie_id ) )    
	
    	open		movie_csr
    	fetch		movie_csr
	into		@target_audience_desc
	while(@@fetch_status=0)
    	begin
		select @target_audiences_desc = isnull(@target_audiences_desc, '') + @target_audience_desc + ', '
		fetch movie_csr into @target_audience_desc
	end
    
	if len(@target_audiences_desc) > 0
		select @target_audiences_desc = substring(@target_audiences_desc, 1, len(@target_audiences_desc) - 1)

	deallocate  movie_csr

        insert into	#mycampaign_list
        		(long_name,
			short_name,
			movie_id,
			country_code,
			release_date,
			classification_code,
			movie_category_desc,
			target_audiences_desc,
			score)
	values		(@long_name,
			@short_name,
			@movie_id,
			@country_code,
			@release_date,
			@classification_code,
			@movie_category_desc,
			@target_audiences_desc,
			@score)

fetch		campaign_csr
into		@long_name,
		@short_name,
		@movie_id,
		@country_code,
		@release_date,
		@classification_code,
		@movie_category_desc

end

deallocate campaign_csr

if @follow_film = 'Y' and @follow_film_restricted = 'Y'
begin

	declare 	movie_csr cursor static for
	select 		msi.movie_id,
				1,
				0,
				''
	from 		movie_screening_ins_rev msi,
				#mycampaign_list list
	where 		list.movie_id = msi.movie_id and
				msi.package_id = @arg_package_id and 
				msi.instruction_type = 1
	order by 	msi.sequence_no desc
	for 		read only
	
end
else
begin
	declare 	movie_csr cursor static for
	select 		distinct movie.movie_id,
				mc.classification_id,
				mc.movie_release_offset,
				movie.long_name
	from 		movie,
				movie_country mc,
				#mycampaign_list list
	where 		list.movie_id = movie.movie_id and
				movie.movie_id = mc.movie_id and
				mc.country_code = @arg_country_code
	order by 	movie.movie_id asc
	for 		read only
end

/*
 * Open Cursor
 */

open movie_csr
fetch movie_csr into @movie_id, @classification, @movie_age_offset, @long_name
while(@@fetch_status = 0)
begin
	/*
	 * Getting scores based on @arg_package_id
	 */
	select		@score = 0

	if @follow_film_restricted = 'Y' and @follow_film_restricted = 'Y'
		select @score = 2

	else
	begin
		/*
		 * Check Classification Restrictions
		 */
	
		select	@count = count(campaign_classification_rev.classification_id)
		  from	campaign_classification_rev, movie_country
		 where	package_id = @arg_package_id and
			instruction_type = 3 and
			campaign_classification_rev.classification_id = @classification and
			campaign_classification_rev.classification_id = movie_country.classification_id and
			movie_country.country_code = @arg_country_code and
			campaign_classification_rev.revision_no = @arg_revision_no and
			movie_country.movie_id = @movie_id

		if(@count > 0)
			select @score = -1

		/*
		 * Check Must Not Screen Movie Instructions
		 */
		
		if(@score != -1)
		begin
	
			select	@count = count(movie_id)
			from	movie_screening_ins_rev
			 where	package_id = @arg_package_id and
				movie_id = @movie_id and
				revision_no = @arg_revision_no and
				instruction_type = 3
		
			if(@count > 0)
				select @score = -1
	
		end
	
		/*
		 * Check Must Not Screen Movie Categories
		 */
	
		if(@score != -1)
		begin
	
			select	@count = count(movie_category_code)
			  from	campaign_category_rev
			 where	package_id = @arg_package_id and
				instruction_type = 3 and
				revision_no = @arg_revision_no and
				movie_category_code in (	select	movie_category_code
									from	target_categories
									where	movie_id = @movie_id )
	
			if(@count > 0)
				select @score = -1
		end
	
		/*
		 * Calculate Audience Profile Score
		 */
	
		if(@score != -1)
		begin
	
			select 	@count = count(package_id)
			  from 	campaign_audience_rev
			 where 	package_id = @arg_package_id and
				instruction_type = 2 and
				revision_no = @arg_revision_no and
				audience_profile_code in (	select	audience_profile_code
									from	target_audience
									where	movie_id = @movie_id	)
	
			if (@count > 0)
				select @score = @score + (5 * @count)
	
		end
	
		/*
		 * Get Movie Category Score
		 */
	
		if(@score != -1)
		begin
	
			select 	@count = count(package_id)
			  from 	campaign_category_rev
			 where 	package_id = @arg_package_id and
				instruction_type = 2 and
				revision_no = @arg_revision_no and
				movie_category_code in (	select	movie_category_code
									from	target_categories
									where	movie_id = @movie_id )
			if (@count > 0)
				select @score = @score + 5 --5 Points regardless of the number of matches on category
	
		end
	end
	/*
	 * movie age multiplier
	 */

	select @movie_age_addition = 1

	select @three_d_modifier = 1

	if(@score != -1)
	begin
	
		select 	@release_date = release_date 
		from	movie_country 
		where 	movie_id = @movie_id
		and 	country_code = @arg_country_code

		select @movie_age = datediff(wk,@release_date, @arg_screening_date) - @movie_age_offset
	
		if @movie_age <= 4
			select @movie_age_addition = 200
		else if @movie_age <= 8
			select @movie_age_addition = 100
		else 
			select @movie_age_addition = 0

		if charindex('3D', upper(@long_name)) > 0 and @three_d_type_pack > 0
			select @three_d_modifier = 100
		else
			select @three_d_modifier = 1


		if @arg_package_id = 17984
			select @three_d_modifier = 1
			
		/*
		 * DYI 2010-10-12 Package 2D/3D preference vs Movie 2D/3D
		 */
		iF charindex('3D', upper(@long_name)) > 0
			select @three_d_type_movie = 2
		Else
			select @three_d_type_movie = 1
		 
		if @dimension_preference = 2 -- Prefer 2D
			if @three_d_type_movie = 1 -- Movie 2D
				select @dim_pref_vs_movie = 50
			else -- Movie is 3D or Imax
				select @dim_pref_vs_movie = 0
		Else if @dimension_preference = 3 -- Prefer 3D
			if @three_d_type_movie = 2 -- Movie is 3D or Imax
				select @dim_pref_vs_movie = 50
			else -- Movie 2D
				select @dim_pref_vs_movie = 0
		Else -- No Preference
			select @dim_pref_vs_movie = 0
			
		
		select @score = (@score + @movie_age_addition  + @dim_pref_vs_movie	) * @three_d_modifier

	end

	update	#mycampaign_list
	set	score = @score,
		dimension_pref_score = @dim_pref_vs_movie	--DYI 2012-07-26
	where	movie_id = @movie_id

	fetch movie_csr into @movie_id, @classification, @movie_age_offset, @long_name
end

deallocate movie_csr


select	long_name,
		short_name,
		movie_id,
		country_code,
		release_date,
		classification_code,
		movie_category_desc,
		target_audiences_desc,
		score --, dimension_pref_score --DYI 2012-07-26
from	#mycampaign_list

return 0
GO
