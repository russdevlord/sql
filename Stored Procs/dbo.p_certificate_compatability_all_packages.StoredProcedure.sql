/****** Object:  StoredProcedure [dbo].[p_certificate_compatability_all_packages]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_compatability_all_packages]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_compatability_all_packages]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_compatability_all_packages]		@complex_id		    	int,
																											@screening_date	    	datetime,
																											@country_code			char(1),
																											@mode							tinyint	
as

/*
 * Declare Variables
 */

declare		@error															int,
				@errorode															int,
				@score															smallint,
				@band															smallint,
				@allocations													int,
				@count															int,
				@movie_id													int,
				@classification												int,
				@work_score												int,
				@band_score												int,
				@campaign_no												int,
				@first_band												tinyint,
				@movie_bands												char(1),
				@movie_name												varchar(50),
				@follow_film												char(1),
				@follow_film_restricted								char(1),
				@package_id											  	int,
				@loop															smallint,
				@movie_age_addition									int,
				@release_date												datetime,
				@movie_age_offset										int,
				@movie_age													int,
				@movie_band_variable									int,
				@three_d_type_pack									int,
				@digital_pack												int,
				@three_d_type_movie									int,
				@three_d_modifier										int,
				@dimension_preference								int, 
				@dim_pref_vs_movie									int,
				@allow_3d													char(1),
				@attendance												int,
				@cinetam_reporting_demographics_id		int,
				@package_status											char(1)

set nocount on

/*
 * Create Temporary Table
 */

create table #movie_scores
(
	campaign_no							int					not null,
	package_id							int					not null,
    follow_film							char(1)				not null,
    movie_id								int					not null,
	movie_name							varchar(50)		null,
	allocations							int 					not null,
    band										smallint			not null,
	score									smallint			not null,
	movie_age_multiplier			int					not null,
	three_d_modifier				int					not null,
	dimension_preference			int					null,
	three_d_type_movie			int					null,
	dim_pref_vs_movie				int					null
)

create table #packages
(
	campaign_no							int					null,
	package_id							int					null,
	movie_bands							char(1)				null,
	follow_film							char(1)				null,
	follow_film_restricted			char(1)				null,
	movie_band_variable			int					null,
	dimension_preference			int					null,
	allow_3d								char(1)				null,
	campaign_package_status	char(1)				null,
	three_d_type_pack				int					null,
	digital_pack							int					null,
	movie_id								int					null,
	movie_name							varchar(50)		null,
	classification_id					int					null,
	movie_release_offset			int					null,
	release_date						datetime			null,
	allocations							int 					null,
    band										smallint			null,
	score									smallint			null,
	movie_age_multiplier			int					null,
	three_d_modifier				int					null,
	three_d_type_movie			int					null,
	dim_pref_vs_movie				int					null,
	max_score							int					null				
)

insert into	#packages
select			campaign_package.campaign_no,
					campaign_package.package_id,
					campaign_package.movie_bands,
					campaign_package.follow_film,
					campaign_package.follow_film_restricted,
					campaign_package.movie_band_variable,
					campaign_package.dimension_preference,
					campaign_package.allow_3d,
					campaign_package.campaign_package_status,
					(select 		count(print_package.print_package_id)
					from			print_package,
									print_package_three_d
					where		print_package.print_package_id = print_package_three_d.print_package_id
					and			print_package.package_id = campaign_package.package_id
					and			three_d_type > 1) as three_d_type_pack,
					(select 		count(print_medium)
					from			print_package,
									print_package_medium
					where		print_package.print_package_id = print_package_medium.print_package_id
					and			print_package.package_id = campaign_package.package_id
					and			print_medium = 'D') as digitial_pack,
					movie_id, 
					long_name,
					classification_id, 
					movie_release_offset,
					release_date,
					(select			count(spot_id)
					from 			campaign_spot spot
					inner join		v_certificate_item_distinct ci on spot.spot_id = ci.spot_reference
					inner join 		movie_history mh on ci.certificate_group = mh.certificate_group
					where 			spot.campaign_no = campaign_package.campaign_no
					and				spot.package_id = campaign_package.package_id
					and				spot.screening_date = campaign_spot.screening_date 
					and				mh.movie_id = tmp_movies_table.movie_id) as allocations,
					(0) as band,
					(0) as score,
					(0) as movie_age_multiplier ,
					(1) as three_d_modifier,
					tmp_movies_table.three_d_type as three_d_type_movie,
					(0) as  dim_pref_vs_movie,
					(0) as  max_score
from				campaign_spot
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
cross join		(select			hist.movie_id,
										mc.classification_id,
										mc.movie_release_offset,
										mc.release_date,
										hist.three_d_type,
										long_name
					from 			movie_history hist,
										movie,
										movie_country mc
					where 			hist.complex_id =@complex_id and
										hist.screening_date = @screening_date and
	 									hist.movie_id = movie.movie_id and
										movie.movie_id = mc.movie_id and
										mc.country_code = @country_code
					group by		hist.movie_id,
										mc.classification_id,
										mc.movie_release_offset,
										mc.release_date,
										hist.three_d_type,
										long_name) as tmp_movies_table
where			complex_id =@complex_id
and				screening_date = @screening_date
and				spot_status in ('A', 'U', 'X','N')
and				follow_film <> 'Y'
and				follow_film_restricted <> 'Y'
group by		campaign_package.package_id,
					campaign_package.movie_bands,
					campaign_package.follow_film,
					campaign_package.follow_film_restricted,
					campaign_package.campaign_no,
					campaign_package.movie_band_variable,
					campaign_package.dimension_preference,
					campaign_package.allow_3d,
					campaign_package.campaign_package_status,
					movie_id, 
					long_name,
					classification_id, 
					movie_release_offset,
					release_date,
					campaign_spot.complex_id,
					campaign_spot.screening_date,
					tmp_movies_table.three_d_type
union all
select			campaign_package.campaign_no,
					campaign_package.package_id,
					campaign_package.movie_bands,
					campaign_package.follow_film,
					campaign_package.follow_film_restricted,
					campaign_package.movie_band_variable,
					campaign_package.dimension_preference,
					campaign_package.allow_3d,
					campaign_package.campaign_package_status,
					(select 		count(print_package.print_package_id)
					from			print_package,
									print_package_three_d
					where		print_package.print_package_id = print_package_three_d.print_package_id
					and			print_package.package_id = campaign_package.package_id
					and			three_d_type > 1) as three_d_type_pack,
					(select 		count(print_medium)
					from			print_package,
									print_package_medium
					where		print_package.print_package_id = print_package_medium.print_package_id
					and			print_package.package_id = campaign_package.package_id
					and			print_medium = 'D') as digitial_pack,
					movie_id, 
					long_name,
					classification_id, 
					movie_release_offset,
					release_date,
					(select			count(spot_id)
					from 			campaign_spot spot
					inner join		v_certificate_item_distinct ci on spot.spot_id = ci.spot_reference
					inner join 		movie_history mh on ci.certificate_group = mh.certificate_group
					where 			spot.campaign_no = campaign_package.campaign_no
					and				spot.package_id = campaign_package.package_id
					and				spot.screening_date = campaign_spot.screening_date 
					and				mh.movie_id = tmp_movies_table.movie_id) as allocations,
					(0) as band,
					(0) as score,
					(0) as movie_age_multiplier ,
					(1) as three_d_modifier,
					tmp_movies_table.three_d_type as three_d_type_movie ,
					(0) as  dim_pref_vs_movie,
					(0) as  max_score
from				campaign_spot
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
inner join		(select 		msi.movie_id,
									classification_id,
									movie_release_offset,
									release_date,
									hist.three_d_type,
									package_id,
									long_name
					from 		movie_screening_instructions msi
					inner join	(select			hist.movie_id,
														mc.classification_id,
														mc.movie_release_offset,
														mc.release_date,
														hist.three_d_type,
														long_name
									from 			movie_history hist,
														movie,
														movie_country mc
									where 			hist.complex_id =@complex_id and
														hist.screening_date = @screening_date and
	 													hist.movie_id = movie.movie_id and
														movie.movie_id = mc.movie_id and
														mc.country_code = @country_code
									group by		hist.movie_id,
														mc.classification_id,
														mc.release_date,
														mc.movie_release_offset,
														hist.three_d_type,
														long_name) as hist on msi.movie_id = hist.movie_id
					where 		 msi.instruction_type = 1) as tmp_movies_table on campaign_package.package_id = tmp_movies_table.package_id
where			complex_id =@complex_id
and				screening_date = @screening_date
and				spot_status in ('A', 'U', 'X','N')
and				follow_film = 'Y'
and				follow_film_restricted = 'Y'
group by		campaign_package.package_id,
					campaign_package.movie_bands,
					campaign_package.follow_film,
					campaign_package.follow_film_restricted,
					campaign_package.campaign_no,
					campaign_package.movie_band_variable,
					campaign_package.dimension_preference,
					campaign_package.allow_3d,
					campaign_package.campaign_package_status,
					movie_id, 
					long_name,
					classification_id, 
					movie_release_offset,
					release_date,
					campaign_spot.complex_id,
					campaign_spot.screening_date,
					tmp_movies_table.three_d_type

--closed packages
update			#packages
set				score = -1,
					band = -1
where			score <> -1
and				campaign_package_status <> 'L'

--follow film
update			#packages
set				score = 1,
					band = 1
where			score <> -1
and				follow_film = 'Y'
and				follow_film_restricted = 'Y'

--allow 3d no
update			#packages
set				score = -1,
					band = -1
where			score <> -1
and				allow_3d = 'N'
and				three_d_type_movie <> 1

--classification restrictions
update			#packages
set				score = -1,
					band = -1
from				(select			package_id,
										classification_id
					from 			campaign_classification
					where 			instruction_type = 3) as classification_restrictions
where			score <> -1
and				#packages.package_id = classification_restrictions.package_id 
and				#packages.classification_id = classification_restrictions.classification_id 

--movie instruction restrictions
update			#packages
set				score = -1,
					band = -1
from				(select			package_id,
										movie_id
					from 			movie_screening_instructions
					where 			instruction_type = 3) as movie_restrictions
where			score <> -1
and				#packages.package_id = movie_restrictions.package_id 
and				#packages.movie_id = movie_restrictions.movie_id 

--movie category restrictions
update			#packages
set				score = -1,
					band = -1
from				(select			package_id, 
										target_categories.movie_id 
					from				campaign_category 
					inner join		target_categories on campaign_category.movie_category_code = target_categories.movie_category_code
					where			instruction_type = 3
					group by		package_id, 
										target_categories.movie_id) as category_restrictions
where			score <> -1
and				#packages.package_id = category_restrictions.package_id 
and				#packages.movie_id = category_restrictions.movie_id 

--audience profile scores
update			#packages
set				score = score + (5 * no_prefs),
					band = score +( 5 * no_prefs)
from				(select			package_id, 
										target_audience.movie_id,
										count(package_id) as no_prefs
					from				campaign_audience 
					inner join		target_audience on campaign_audience.audience_profile_code = target_audience.audience_profile_code
					where			instruction_type = 2
					group by		package_id, 
										target_audience.movie_id) as audience_preferences
where			score <> -1
and				#packages.package_id = audience_preferences.package_id 
and				#packages.movie_id = audience_preferences.movie_id 


--movie category scores
update			#packages
set				score = score + 5,
					band = score + 5
from				(select			package_id, 
										target_categories.movie_id 
					from				campaign_category 
					inner join		target_categories on campaign_category.movie_category_code = target_categories.movie_category_code
					where			instruction_type = 2
					group by		package_id, 
										target_categories.movie_id) as category_preferences
where			score <> -1
and				#packages.package_id = category_preferences.package_id 
and				#packages.movie_id = category_preferences.movie_id 


--movie age
update			#packages
set				movie_age_multiplier = datediff(wk, release_date, @screening_date) - movie_age_multiplier
where			score <> -1

update			#packages
set				movie_age_multiplier = case when movie_age_multiplier >= 9 then 0 when movie_age_multiplier < 9 and movie_age_multiplier > 4 then 100 else 200 end
where			score <> -1

--three d modifier
update			#packages
set				three_d_modifier = case when three_d_type_movie > 0 then 100 else -1 end
where			score <> -1
and				three_d_type_pack > 1


--dim_pref_vs_movie modifier
update			#packages
set				dim_pref_vs_movie = case when three_d_type_movie = 1 then 50 else 0 end
where			score <> -1
and				dimension_preference = 2

update			#packages
set				dim_pref_vs_movie = case when three_d_type_movie = 2 then 50 else 0 end
where			score <> -1
and				dimension_preference = 3

--banding
update			#packages
set				max_score = max_scores.max_package_score 
from				(select			package_id,
										max(score) as max_package_score
					from				#packages
					group by		package_id) as max_scores
where			score <> -1
and				#packages.package_id = max_scores.package_id

update			#packages
set				band = case when (score % 10 + max_score % 10) = 5 then score + 5 else score end

--insert into score summary
insert into	#movie_scores 
select			campaign_no,
					package_id,
					follow_film,
					movie_id,
					movie_name,
					allocations,
					band,
					score,
					movie_age_multiplier,
					three_d_modifier,
					dimension_preference,
					three_d_type_movie,
					dim_pref_vs_movie	
from				#packages



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
