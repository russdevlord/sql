/****** Object:  StoredProcedure [dbo].[p_movie_compatability_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_compatability_report]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_compatability_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create  PROC [dbo].[p_movie_compatability_report] 	@movie_id		    		int,
	                                        @screening_date	    		datetime,
	                                        @country_code				char(1)
as

/*
 * Declare Variables
 */

declare @error					    int,
        @errorode					    int,
        @score					    smallint,
        @band					    smallint,
        @allocations			    int,
        @count					    int,
        @classification		        int,
        @work_score			        int,
        @band_score			        int,
        @campaign_no			    int,
        @first_band			        tinyint,
        @movie_bands			    char(1),
        @movie_name			        varchar(50),
        @follow_film			    char(1),
        @follow_film_restricted     char(1),
        @loop					    smallint,
		@movie_age_multiplier		int,
		@release_date				datetime,
		@movie_age_offset			int,
		@movie_age					int,
		@movie_band_variable		int,
		@package_id					int,
	@product_desc			varchar(100),
	@package_code			varchar(2),
	@package_desc			varchar(100)

set nocount on

/*
 * Create Temporary Table
 */

create table #movie_scores
(
	campaign_no				int				not null,
	product_desc			varchar(100)	null,
	package_id				int				not null,
	package_code			varchar(2)		null,
	package_desc			varchar(100)	null,
    follow_film				char(1)			not null,
    movie_id				int				not null,
	movie_name				varchar(50)		null,
	allocations				int 			not null,
    band					smallint		not null,
	score					smallint		not null,
	movie_age_multiplier	int				not null
)

declare		pack_csr cursor forward_only for
select 		package_id 
from 		campaign_spot
where		spot_status in ('A','X')
and			screening_date = @screening_date
and			campaign_no in (select campaign_no from film_campaign, branch where film_campaign.branch_code = branch.branch_code and country_code = @country_code)
group by	package_id
order by	package_id

open pack_csr
fetch pack_csr into @package_id
while(@@fetch_status = 0)
begin

	/*
	 * Load Movie Band & Follow Film
	 */
	
	select @movie_bands = movie_bands,
	       @follow_film = follow_film,
	       @follow_film_restricted = follow_film_restricted,
	       @campaign_no = campaign_package.campaign_no,
		   @movie_band_variable = movie_band_variable,
			@product_desc = product_desc,
			@package_code	= package_code,
			@package_desc = package_desc	
	  from campaign_package,
			film_campaign
	 where package_id = @package_id
	and	campaign_package.campaign_no = film_campaign.campaign_no
	
	
		/*
	    * Initialise Scores
	    */
	
		select @score = 0,
	           @band = 0,
	           @allocations = 0,
	           @movie_name = null,
	           @movie_age_multiplier = 1
	
		if @follow_film = 'Y' and @follow_film_restricted = 'Y'
		begin
	
			select @score = 0
	
		end
		else
		begin
	
			/*
		 * Check Classification Restrictions
		 */
	
		select @count = count(classification_id)
		  from campaign_classification
		 where package_id = @package_id and
				 classification_id = @classification and
				 instruction_type = 3
				 
		if(@count > 0)
			select @score = -1,
					 @band = -1
		
		/*
		 * Check Must Not Screen Movie Instructions
		 */
		
		if(@score != -1)
		begin
	
			select @count = count(movie_id)
			  from movie_screening_instructions
			 where package_id = @package_id and
					 movie_id = @movie_id and
					 instruction_type = 3
		
			if(@count > 0)
				select @score = -1,
						 @band = -1
	
		end
	
		/*
		 * Check Must Not Screen Movie Categories
		 */
	
		if(@score != -1)
		begin
	
			select @count = count(movie_category_code)
			  from campaign_category
			 where package_id = @package_id and
					 instruction_type = 3 and
					 movie_category_code in ( select movie_category_code
														 from target_categories
														where movie_id = @movie_id )
	
			if(@count > 0)
				select @score = -1,
						 @band = -1
	
		end
	
		/*
		 * Calculate Audience Profile Score
		 */
	
		if(@score != -1)
		begin
	
			select @count = count(package_id)
			  from campaign_audience
			 where package_id = @package_id and
					 instruction_type = 2 and
					 audience_profile_code in ( select audience_profile_code
															from target_audience
														  where movie_id = @movie_id )
	
			if (@count > 0)
				select @score = @score + (5 * @count)
	
		end
	
		/*
		 * Get Movie Category Score
		 */
	
		if(@score != -1)
		begin
	
			select @count = count(package_id)
			  from campaign_category
			 where package_id = @package_id and
					 instruction_type = 2 and
					 movie_category_code in ( select movie_category_code
														 from target_categories
														where movie_id = @movie_id )
	
			if (@count > 0)
				select @score = @score + 5 --5 Points regardless of the number of matches on category
	
		end

	end

	/*
    * Calculate Allocations
    */

	select @allocations = 0

	/*
	 * Get Movie Name & Classification
	 */

	select @movie_name = mc.movie_name + ' (' + convert(varchar(5),class.classification_code) + ')'
	  from movie_country mc,
			 classification class
	 where mc.movie_id = @movie_id and
			 mc.country_code = @country_code and
			 mc.classification_id = class.classification_id

	/*
 	 * Use Movie Age to Group Scores
   	 */

	select @movie_age_multiplier = 1

	if(@score != -1)
	begin
		select 	@release_date = release_date 
		from	movie_country 
		where 	movie_id = @movie_id
		and 	country_code = @country_code
	
		select @movie_age = datediff(wk,@release_date, @screening_date) - @movie_age_offset
	
		if @movie_age <= 4
			select @movie_age_multiplier = 100
		else if @movie_age <= 8
			select @movie_age_multiplier = 10
		else 
			select @movie_age_multiplier = 1
	end

	/*
    * Insert Movie Score into the Temporary Table
    */
	
	select @band = @score

	insert into #movie_scores values (@campaign_no, @product_desc, @package_id, @package_code, @package_desc, @follow_film, @movie_id, @movie_name, @allocations, @band, @score, @movie_age_multiplier)

	
	fetch pack_csr into @package_id
end
	       
/*
 * Return Dataset
 */

select * from #movie_scores order by follow_film DESC, score DESC

/*
 * Return Success
 */

return 0
GO
