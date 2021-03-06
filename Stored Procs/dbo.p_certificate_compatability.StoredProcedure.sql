/****** Object:  StoredProcedure [dbo].[p_certificate_compatability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_compatability]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_compatability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_compatability]		@complex_id		    	int,
													@screening_date	    	datetime,
													@package_id		    	int,
													@country_code			char(1),
													@mode					tinyint	
as

/*
 * Declare Variables
 */

declare		@error									int,
			@errorode									int,
			@score									smallint,
			@band									smallint,
			@allocations							int,
			@count									int,
			@movie_id								int,
			@classification							int,
			@work_score								int,
			@band_score								int,
			@campaign_no							int,
			@first_band								tinyint,
			@movie_bands							char(1),
			@movie_name								varchar(50),
			@follow_film							char(1),
			@follow_film_restricted					char(1),
			@loop									smallint,
			@movie_age_addition						int,
			@release_date							datetime,
			@movie_age_offset						int,
			@movie_age								int,
			@movie_band_variable					int,
			@three_d_type_pack						int,
			@digital_pack							int,
			@three_d_type_movie						int,
			@three_d_modifier						int,
			@dimension_preference					int, 
			@dim_pref_vs_movie						int,
			@allow_3d								char(1),
			@attendance								int,
			@cinetam_reporting_demographics_id		int,
			@package_status							char(1)

/*
 * Create Temporary Table
 */

create table #movie_scores
(
	campaign_no					int				not null,
	package_id					int				not null,
    follow_film					char(1)			not null,
    movie_id					int				not null,
	movie_name					varchar(50)		null,
	allocations					int 			not null,
    band						smallint		not null,
	score						smallint		not null,
	movie_age_multiplier		int				not null,
	three_d_modifier			int				not null,
	dimension_preference		int				null,
	three_d_type_movie			int				null,
	dim_pref_vs_movie			int				null
)

/*
 * Load Movie Band & Follow Film
 */

select 		@movie_bands = movie_bands,
			@follow_film = follow_film,
			@follow_film_restricted = follow_film_restricted,
			@campaign_no = campaign_no,
			@movie_band_variable = movie_band_variable,
			@dimension_preference = dimension_preference,
			@allow_3d = allow_3d,
			@package_status = campaign_package_status
from 		campaign_package
where 		package_id = @package_id

/*
 * Load Package 3D & Digital
 */

select 		@three_d_type_pack 	= count(print_package.print_package_id)
from		print_package,
			print_package_three_d
where		print_package.print_package_id = print_package_three_d.print_package_id
and			print_package.package_id = @package_id
and			three_d_type > 1

select 		@digital_pack = count(print_medium)
from		print_package,
			print_package_medium
where		print_package.print_package_id = print_package_medium.print_package_id
and			print_package.package_id = @package_id
and			print_medium = 'D'

/*
 * Declare Cursors
 */

if @follow_film = 'Y' and @follow_film_restricted = 'Y'
begin

	declare		movie_csr cursor static for
	select 		msi.movie_id,
				1,
				0,
				hist.three_d_type
	from 		movie_screening_instructions msi,
				(select distinct movie_id, three_d_type from movie_history where complex_id = @complex_id and screening_date = @screening_date ) as hist
	where 		hist.movie_id = msi.movie_id and
				msi.package_id = @package_id and 
				msi.instruction_type = 1
	order by	msi.sequence_no desc
	for 		read only

	select @loop = 0

end
else
	begin
		declare 		movie_csr cursor static for
		select 			distinct hist.movie_id,
							mc.classification_id,
							mc.movie_release_offset,
							hist.three_d_type 
		from 			movie_history hist,
							movie,
							movie_country mc
		where 		hist.complex_id = @complex_id and
							hist.screening_date = @screening_date and
	 						hist.movie_id = movie.movie_id and
							movie.movie_id = mc.movie_id and
							mc.country_code = @country_code
		order by		hist.movie_id asc
		for 				read only
	end

/*
 * Open Cursor
 */

open movie_csr
fetch movie_csr into @movie_id, @classification, @movie_age_offset, @three_d_type_movie 
while(@@fetch_status = 0)
begin

	/*
     * Initialise Scores
     */

	select 	@score = 0,
			@band = 0,
			@allocations = 0,
			@movie_name = null,
			@movie_age_addition = 1,
			@three_d_modifier = 1			

	if @follow_film = 'Y' and @follow_film_restricted = 'Y'
	begin
		select @loop = @loop + 1
		select @score = @loop + 1,
					@band = @loop + 1
					
		if @package_status <> 'L'
			select @score = -1,
					@band = -1					
	end
	else
	begin
	
		select 	@three_d_type_movie = three_d_type
		from	movie_history
		where	complex_id = @complex_id
		and		screening_date = @screening_date
		and		movie_id = @movie_id	
		
		if @allow_3d = 'N' and @three_d_type_movie <> 1
			select 	@score = -1,
						@band = -1
						
		if(@score != -1)
		begin
			if @package_status <> 'L'
				select @score = -1,
						@band = -1		
		end						
				
		/*
		 * Check Classification Restrictions
		 */
	
		if(@score != -1)
		begin
			select		@count = count(classification_id)
			from 		campaign_classification
			where 	package_id = @package_id 
			and			classification_id = @classification 
			and			instruction_type = 3
					 
			if(@count > 0)
				select 	@score = -1,
						@band = -1
		end
		
		/*
		 * Check Must Not Screen Movie Instructions
		 */
		
		if(@score != -1)
		begin
			select 		@count = count(movie_id)
			from 		movie_screening_instructions
			where 		package_id = @package_id 
			and			movie_id = @movie_id 
			and			instruction_type = 3
			
			if(@count > 0)
				select 	@score = -1,
						@band = -1
		end
	
		/*
		 * Check Must Not Screen Movie Categories
		 */
	
		if(@score != -1)
		begin
			select 		@count = count(movie_category_code)
			from 		campaign_category
			where 	package_id = @package_id 
			and			instruction_type = 3 
			and			movie_category_code in (	select		movie_category_code
																			from 		target_categories
																			where 	movie_id = @movie_id )
			
			if(@count > 0)
				select 	@score = -1,
						@band = -1

		end
	
		/*
		 * Calculate Audience Profile Score
		 */
	
		if(@score != -1)
		begin
	
			select 		@count = count(package_id)
			from 		campaign_audience
			where 	package_id = @package_id 
			and			instruction_type = 2 
			and			audience_profile_code in (	select 		audience_profile_code
																				from 		target_audience
																				where 	movie_id = @movie_id )
			
			if (@count > 0)
				select @score = @score + (5 * @count)
	
		end
	
		/*
		 * Get Movie Category Score
		 */
	
		if(@score != -1)
		begin
	
			select 	@count = count(package_id)
			from 	campaign_category
			where 	package_id = @package_id 
			and		instruction_type = 2 
			and		movie_category_code in (select 	movie_category_code
											from 	target_categories
											where 	movie_id = @movie_id )
			
			if (@count > 0)
				select @score = @score + 5 --5 Points regardless of the number of matches on category
	
		end

	end

	/*
     * Calculate Allocations
     */

	if(@mode > 1)
	begin

		select 	@count = count(spot_id)
		from 	campaign_spot spot,
				certificate_item ci,
				certificate_group cg,
				movie_history mh
		where 	spot.campaign_no = @campaign_no 
		and		spot.package_id = @package_id 
		and		spot.screening_date = @screening_date 
		and		spot.spot_id = ci.spot_reference 
		and		ci.certificate_group = cg.certificate_group_id 
		and		cg.certificate_group_id = mh.certificate_group 
		and		mh.movie_id = @movie_id

		if(@count > 0)
			select @allocations = @count

	end

	/*
	 * Get Movie Name & Classification
	 */

	if(@mode >= 2)
		select 	@movie_name = mc.movie_name + ' (' + convert(varchar(5),class.classification_code) + ')'
		from 	movie_country mc,
				classification class
		where	mc.movie_id = @movie_id 
		and		mc.country_code = @country_code 
		and		mc.classification_id = class.classification_id

	/*
 	 * Use Movie Age to Group Scores
   	 */

	select @movie_age_addition = 1
	select @three_d_modifier = 1
	
	if(@score != -1)
	begin
		select 	@release_date = release_date 
		from	movie_country 
		where 	movie_id = @movie_id
		and 	country_code = @country_code
	
		select @movie_age = datediff(wk, @release_date, @screening_date) - @movie_age_offset
		

		if  @three_d_type_pack > 0
		begin
			if @three_d_type_movie > 0
				select @three_d_modifier = 100
			else
				select @three_d_modifier = -1
		end
		else
			select @three_d_modifier = 1
				
			if @movie_age <= 4
				select @movie_age_addition = 200
			else if @movie_age <= 8
				select @movie_age_addition = 100
			else 
				select @movie_age_addition = 0
		end
		
		/*
		 * Package 2D/3D preference vs Movie 2D/3D
		 */
		 
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
	
	/*
     * Insert Movie Score into the Temporary Table
     */
     
	select @band = @score
	insert into #movie_scores values (@campaign_no, @package_id, @follow_film, @movie_id, @movie_name, @allocations, @band, @score, @movie_age_addition, 
		@three_d_modifier, @dimension_preference, @three_d_type_movie, @dim_pref_vs_movie ) 
		
	/*
	 * Fetch Next Movie
	 */
	 
	fetch movie_csr into @movie_id, @classification, @movie_age_offset, @three_d_type_movie

end
close movie_csr
deallocate movie_csr

/*
 * Movie Bands
 */
 
if(@movie_bands = 'Y' and @follow_film = 'N')
begin

	select @first_band = 1

	if isnull(@movie_band_variable,0) = 0
		select @movie_band_variable = 10

	declare band_csr cursor static for
	select movie_id, score
	from #movie_scores
	order by score DESC, movie_id ASC
	for read only

	open band_csr
	fetch band_csr into @movie_id, @score
	while(@@fetch_status = 0)
	begin

		/*
       * First Band
       */

		if(@first_band = 1)
			select @first_band = 0,
                @work_score = @score,
                @band_score = @score
                
		/*
        * Calculate Band
        */

		if(@score >= 0)
		begin

			if(@score <= @work_score - @movie_band_variable)
         begin
				while(@score <= @work_score - @movie_band_variable)
				begin
					select @work_score = @work_score - @movie_band_variable
            end
			end

			/*
			 * Update Band
			 */

		update	#movie_scores
		set			band = @work_score
		where		movie_id = @movie_id

		end
		
		/*
        * Fetch Next
        */

		fetch band_csr into @movie_id, @score

	end
	close band_csr
	deallocate band_csr

end

/*
 * Update Age - Has to be done after banding
 */

update 	#movie_scores
set 	band = (band + movie_age_multiplier + dim_pref_vs_movie) * three_d_modifier  ,
		score = (score + movie_age_multiplier + dim_pref_vs_movie) * three_d_modifier
where 	score >= 0


/*
 * Return Dataset
 */

select * 
from #movie_scores 
order by band DESC, score DESC

return 0
GO
