/****** Object:  StoredProcedure [dbo].[p_follow_film_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_follow_film_report]
GO
/****** Object:  StoredProcedure [dbo].[p_follow_film_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc [dbo].[p_follow_film_report]		@country_code           char(1),
											@rpt_start_date         datetime,
											@rpt_end_date           datetime,
											@arg_movie_id			int,
											@client_id              int,
											@mode                   int,
											@campaign_no            int,
											@client_product_id		int,
											@client_group_id		int

/******************************************
*
*
*  Modes:
*  1 	: Date Range & Country
*  2	: Client & Country
*  3	: Movie & Country
*  4    : Campaign & Country
*  5    : Client Product & Country
*  6    : Client Group & Country
*
*
******************************************/

as

declare     @error                          int,
            @product_desc                   varchar(100),
            @package_id                     int,
            @package_code                   char(1),
            @package_desc                   varchar(100),
            @release_date                   datetime,
            @movie_id                       int,
            @long_name                      varchar(50),
            @client_name                    varchar(50),    
            @product_category_desc          varchar(50),
            @business_unit_desc             varchar(50),
            @campaign_status_desc           varchar(50),
            @start_date                     datetime,
            @end_date                       datetime,
            @duration                       integer,
            @first_name                     varchar(50),
            @last_name                      varchar(50),
            @rate                           money,
            @campaign_cost                  money,
            @markets                        varchar(400),
            @market_code                    varchar(3),
            @market_no                      int,
            @classification_code            varchar(5)

set nocount on

/*
 * Create Temp Table
 */
create table #follow_films (
		campaign_no                     int             null,
		product_desc                    varchar(100)    null,
		package_id                      int             null,
		package_code                    char(1)         null,
		package_desc                    varchar(100)    null,
		release_date                    datetime        null,
		movie_id                        int             null,
		long_name                       varchar(50)     null,
		client_name                     varchar(50)     null,
		product_category_desc           varchar(50)     null,
		business_unit_desc              varchar(50)     null,
		campaign_status_desc            varchar(50)     null,
		start_date                      datetime        null,
		end_date                        datetime        null,
		duration                        integer         null,
		first_name                      varchar(50)     null,
		last_name                       varchar(50)     null,
		rate                            money           null,
		campaign_cost                   money           null,
		country_code                    char(1)         null,
		markets                         varchar(400)    null,
		classification_code             varchar(5)      null
)


/*
 * Declare Cursor
 */
declare     campaign_csr cursor forward_only static for
select      film_campaign.campaign_no,
            product_desc,
            package_id,
            package_code,
            package_desc,
            client_name, 
            product_category_desc,
            business_unit_desc,
            campaign_status_desc,
            film_campaign.start_date,
            film_campaign.end_date,
            duration,
            first_name,
            last_name,
            rate,
            campaign_cost,
            branch.country_code
from        film_campaign,
            campaign_package,
            client,
            product_category,
            business_unit,
            campaign_status,
            sales_rep,
            branch
where       film_campaign.campaign_no = campaign_package.campaign_no
and         film_campaign.client_id = client.client_id
and         campaign_package.product_category = product_category.product_category_id
and         film_campaign.business_unit_id = business_unit.business_unit_id
and         film_campaign.rep_id = sales_rep.rep_id
and         film_campaign.branch_code = branch.branch_code
and         film_campaign.campaign_status = campaign_status.campaign_status_code
and         film_campaign.campaign_status != 'P'
and         campaign_package.follow_film = 'Y'
and         branch.country_code = @country_code
and         ((@mode = 1
and         film_campaign.start_date >= @rpt_start_date
and         film_campaign.end_date <= @rpt_end_date)
or          (@mode = 2
and         film_campaign.client_id = @client_id)
or          (@mode = 5
and         film_campaign.client_product_id = @client_product_id)
or          (@mode = 6
and         client.client_group_id = @client_group_id)
or          (@mode = 3
and         campaign_package.package_id in (select	package_id 
											from	movie_screening_instructions 
											where	movie_screening_instructions.instruction_type = 1 
											and		movie_screening_instructions.movie_id = @arg_movie_id))
or          (@mode = 4
and         film_campaign.campaign_no = @campaign_no))
order by    film_campaign.campaign_no                    


open campaign_csr
fetch campaign_csr into     @campaign_no,
                            @product_desc,
                            @package_id,
                            @package_code,
                            @package_desc,
                            @client_name, 
                            @product_category_desc,
                            @business_unit_desc,
                            @campaign_status_desc,
                            @start_date,
                            @end_date,
                            @duration,
                            @first_name,
                            @last_name,
                            @rate,
                            @campaign_cost,
                            @country_code
while(@@fetch_status=0)
begin
    
    select @markets = ''    

    declare     market_csr cursor forward_only static for
    select      distinct film_market_code,
                film_market.film_market_no
    from        film_market,
                complex,
                (select distinct complex_id from campaign_spot where package_id = @package_id and campaign_no = @campaign_no group by complex_id) as sub_spot
    where       film_market.film_market_no = complex.film_market_no
    and         complex.complex_id = sub_spot.complex_id
    group by    film_market_code,
                film_market.film_market_no
    order by    film_market.film_market_no
    for         read only
    
    open market_csr
    fetch market_csr into @market_code, @market_no
    while(@@fetch_status=0)
    begin
    
        select @markets = isnull(@markets, '') + @market_code + ', '
        
        fetch market_csr into @market_code, @market_no
    end
    
    if len(@markets) > 0
        select @markets = substring(@markets, 1, len(@markets) - 1)

    deallocate  market_csr
    
    declare     movie_csr cursor forward_only static for
		select      movie.movie_id,
					long_name,
					release_date,
					classification_code
		from        movie,
					movie_country,
					movie_screening_instructions,
					classification
		where       movie.movie_id = movie_country.movie_id
		and         movie_screening_instructions.movie_id = movie.movie_id
		and         movie_country.country_code = @country_code
		and         movie_screening_instructions.package_id = @package_id
		and         movie_screening_instructions.instruction_type = 1
		and         ((@mode = 1
		and         movie_country.release_date between @rpt_start_date and @rpt_end_date)
		or			(@mode = 3
		and         movie.movie_id = @arg_movie_id)
		or          @mode = 2
		or          @mode = 4)
		and         movie_country.classification_id = classification.classification_id
		union
		select	0 as movie_id,
				'Unknown' as long_name,
				NULL,
				''
		FROM	movie LEFT OUTER JOIN
				movie_country ON movie.movie_id = movie_country.movie_id INNER JOIN
				movie_screening_instructions ON movie.movie_id = movie_screening_instructions.movie_id
		WHERE	(movie_country.country_code = @country_code) AND (movie_screening_instructions.package_id = @package_id) AND 
				(movie_screening_instructions.instruction_type = 1) AND (@mode = 1) AND (movie_country.release_date BETWEEN @rpt_start_date AND @rpt_end_date) OR
				(movie_country.country_code = @country_code) AND (movie_screening_instructions.package_id = @package_id) AND 
				(movie_screening_instructions.instruction_type = 1) AND (@mode = 3) AND (movie.movie_id = @arg_movie_id) OR
				(movie_country.country_code = @country_code) AND (movie_screening_instructions.package_id = @package_id) AND 
				(movie_screening_instructions.instruction_type = 1) AND (@mode = 2) OR
				(movie_country.country_code = @country_code) AND (movie_screening_instructions.package_id = @package_id) AND 
				(movie_screening_instructions.instruction_type = 1) AND (@mode = 4)
		HAVING	(COUNT(movie.movie_id) = 0)
		ORDER BY movie.long_name    
	for read only
      
    open movie_csr
    
    
    fetch movie_csr into @movie_id, @long_name, @release_date, @classification_code
    while(@@fetch_status=0)
    begin
    
	insert into #follow_films
        (campaign_no,
        product_desc,
        package_id,
        package_code,
        package_desc,
        release_date,
        movie_id,
        long_name,
        client_name,
        product_category_desc,
        business_unit_desc,
        campaign_status_desc,
        start_date,
        end_date,
        duration,
        first_name,
        last_name,
        rate,
        campaign_cost,
        country_code,
        markets,
        classification_code) 
	values
        (@campaign_no,
        @product_desc,
        @package_id,
        @package_code,
        @package_desc,
        @release_date,
        @movie_id,
        @long_name,
        @client_name,
        @product_category_desc,
        @business_unit_desc,
        @campaign_status_desc,
        @start_date,
        @end_date,
        @duration,
        @first_name,
        @last_name,
        @rate,
        @campaign_cost,
        @country_code,
        @markets,
        @classification_code)

        fetch movie_csr into @movie_id, @long_name, @release_date, @classification_code
    end        
    deallocate movie_csr

	fetch campaign_csr into     @campaign_no,
	                            @product_desc,
	                            @package_id,
	                            @package_code,
	                            @package_desc,
	                            @client_name, 
	                            @product_category_desc,
	                            @business_unit_desc,
	                            @campaign_status_desc,
	                            @start_date,
	                            @end_date,
	                            @duration,
	                            @first_name,
	                            @last_name,
	                            @rate,
	                            @campaign_cost,
	                            @country_code

end

deallocate campaign_csr

select      campaign_no,
            product_desc,
            package_id,
            package_code,
            package_desc,
            release_date,
            long_name,
            client_name,
            product_category_desc,
            business_unit_desc,
            campaign_status_desc,
            start_date,
            end_date,
            duration,
            first_name,
            last_name,
            rate,
            campaign_cost,
            country_code,
            markets,
            classification_code,
            movie_id
from        #follow_films
order by    release_date,
            long_name,
            campaign_no

return 0
GO
