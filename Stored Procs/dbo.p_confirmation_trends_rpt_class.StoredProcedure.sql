/****** Object:  StoredProcedure [dbo].[p_confirmation_trends_rpt_class]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirmation_trends_rpt_class]
GO
/****** Object:  StoredProcedure [dbo].[p_confirmation_trends_rpt_class]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_confirmation_trends_rpt_class] @start_date			datetime,
									  @end_date				datetime

as

declare		@error					    integer,
			@no_weeks				    integer,
			@film_market_no		        integer,
			@film_market_desc		    varchar(30),
			@complex_name			    varchar(60),
			@exhibitor_name			    varchar(50),
			@complex_id				    integer,
			@movie_target			    integer,
			@total_movies			    integer,
			@general				    integer,
			@parental_guidance			integer,
			@mature				    	integer,
			@mature_15				    integer,
			@restricted				    integer,
            @region_class			    char(1),
            @screens					integer,
			@clash_limit				integer,
			@campaign_limit				integer

                           
create table #results
(	
	no_weeks				integer			null,
	film_market_no			integer			null,
	film_market_desc		varchar(30)		null,
	complex_name			varchar(60)		null,
	movie_target			integer			null,
	total_movies			integer			null,
	general					integer			null,
	parental_guidance		integer			null,
	mature					integer			null,
	mature_15				integer			null,
	restricted				integer			null,
	screens					integer			null,
    region_class			char(1)			null,
    exhibitor_name          varchar(50)     null,
	clash_limit				integer			null,
	campaign_limit			integer			null
)

/*
 * Declare Cursor
 */                          

 declare movie_csr cursor static for
  select film_market.film_market_no,
			film_market.film_market_desc,
			complex.complex_name ,
			complex.complex_id,
			complex.movie_target , 
            complex.complex_region_class,
            exhibitor.exhibitor_name,
			count( movie_history.movie_id ),
			complex.clash_safety_limit,
			complex.campaign_safety_limit
    from film_market,
			complex,
            exhibitor,
			complex_date,
			movie_history     
   where complex.film_market_no = film_market.film_market_no and
			complex.exhibitor_id = exhibitor.exhibitor_id and
			complex.complex_id = complex_date.complex_id and
			complex_date.complex_id = movie_history.complex_id and
			complex_date.screening_date = movie_history.screening_date and
			complex_date.screening_date between @start_date and @end_date
group by  film_market.film_market_no,
			film_market.film_market_desc,
			complex.complex_name ,
			complex.complex_id,
			complex.movie_target , 
            complex.complex_region_class,
            exhibitor.exhibitor_name,
			complex.clash_safety_limit,
			complex.campaign_safety_limit
order by film_market.film_market_no,
		 film_market.film_market_desc,
		 complex.complex_name
for read only

open movie_csr
fetch movie_csr into @film_market_no, @film_market_desc, @complex_name, @complex_id, @movie_target, @region_class, @exhibitor_name, @total_movies, @clash_limit, @campaign_limit

while(@@fetch_status=0)
begin

	
select @screens = count(complex_id)
  from cinema
 where complex_id = @complex_id and
       film_rate_list = 'Y' 

select @no_weeks = count(distinct mh.screening_date)
  from movie_history mh
 where mh.screening_date between @start_date and @end_date and
		 mh.complex_id = @complex_id 

  select @general = count( movie_history.movie_id )
    from film_market,
			complex,           
			complex_date,
			movie_history     
   where complex.film_market_no = film_market.film_market_no and
			complex.complex_id = complex_date.complex_id and
			complex_date.complex_id = movie_history.complex_id and
			complex_date.screening_date = movie_history.screening_date and
			complex_date.screening_date between @start_date and @end_date and
			complex.film_market_no = @film_market_no and
			complex.complex_id = @complex_id and
			movie_history.movie_id in (select movie_id from movie_country where classification_id = '1' or classification_id = '101' )

  select @parental_guidance = count( movie_history.movie_id )
    from film_market,
			complex,           
			complex_date,
			movie_history     
   where complex.film_market_no = film_market.film_market_no and
			complex.complex_id = complex_date.complex_id and
			complex_date.complex_id = movie_history.complex_id and
			complex_date.screening_date = movie_history.screening_date and
			complex_date.screening_date between @start_date and @end_date and
			complex.film_market_no = @film_market_no and
			complex.complex_id = @complex_id and
			movie_history.movie_id in (select movie_id from movie_country where classification_id = '2' or classification_id = '102' )

  select @mature = count( movie_history.movie_id )
    from film_market,
			complex,           
			complex_date,
			movie_history     
   where complex.film_market_no = film_market.film_market_no and
			complex.complex_id = complex_date.complex_id and
			complex_date.complex_id = movie_history.complex_id and
			complex_date.screening_date = movie_history.screening_date and
			complex_date.screening_date between @start_date and @end_date and
			complex.film_market_no = @film_market_no and
			complex.complex_id = @complex_id and
			movie_history.movie_id in (select movie_id from movie_country where classification_id = '3' or classification_id = '103' )

  select @mature_15 = count( movie_history.movie_id )
    from film_market,
			complex,           
			complex_date,
			movie_history     
   where complex.film_market_no = film_market.film_market_no and
			complex.complex_id = complex_date.complex_id and
			complex_date.complex_id = movie_history.complex_id and
			complex_date.screening_date = movie_history.screening_date and
			complex_date.screening_date between @start_date and @end_date and
			complex.film_market_no = @film_market_no and
			complex.complex_id = @complex_id and
			movie_history.movie_id in (select movie_id from movie_country where classification_id = '4' or classification_id = '104' )

  select @restricted	= count( movie_history.movie_id )
    from film_market,
			complex,           
			complex_date,
			movie_history     
   where complex.film_market_no = film_market.film_market_no and
			complex.complex_id = complex_date.complex_id and
			complex_date.complex_id = movie_history.complex_id and
			complex_date.screening_date = movie_history.screening_date and
			complex_date.screening_date between @start_date and @end_date and
			complex.film_market_no = @film_market_no and
			complex.complex_id = @complex_id and
			movie_history.movie_id in (select movie_id from movie_country where classification_id = '5' or classification_id = '105' )

		insert into #results
		(
			no_weeks,
			film_market_no,
			film_market_desc,
			complex_name,
			movie_target,
			total_movies,
			general,
			parental_guidance,
			mature,
			mature_15,
			restricted,
         screens,
         region_class,
         exhibitor_name,
			clash_limit,
			campaign_limit ) values
		(
			@no_weeks,
			@film_market_no,
			@film_market_desc,
			@complex_name,
			@movie_target,
			@total_movies,
			@general,
			@parental_guidance,
			@mature,
			@mature_15,
			@restricted,
	        @screens,
    	    @region_class,
        	@exhibitor_name,
			@clash_limit,
			@campaign_limit
		)

		select @error = @@error
		if @error <> 0
		begin
			raiserror ( 'Error', 16, 1)
			return -1
		end 

	fetch movie_csr into @film_market_no, @film_market_desc, @complex_name, @complex_id, @movie_target, @region_class, @exhibitor_name, @total_movies, @clash_limit, @campaign_limit

end

close movie_csr
deallocate movie_csr

select * from #results
return 0
GO
