/****** Object:  StoredProcedure [dbo].[p_confirmation_trends_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirmation_trends_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_confirmation_trends_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_confirmation_trends_rpt] @start_date			datetime,
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
			@age_0_13				    integer,
			@age_14_17				    integer,
			@age_18_24				    integer,
			@age_25_49				    integer,
			@age_50_99				    integer,
			@male_age_0_13			    integer,
			@male_age_14_17		        integer,
			@male_age_18_24		        integer,
			@male_age_25_49		        integer,
			@male_age_50_99		        integer,
			@female_age_0_13		    integer,
			@female_age_14_17		    integer,
			@female_age_18_24		    integer,
			@female_age_25_49		    integer,
			@female_age_50_99		    integer,
            @region_class			    char(1),
            @screens					integer

                           
create table #results
(	
	no_weeks				integer			null,
	film_market_no			integer			null,
	film_market_desc		varchar(30)		null,
	complex_name			varchar(60)		null,
	movie_target			integer			null,
	total_movies			integer			null,
	age_0_13				integer			null,
	age_14_17				integer			null,
	age_18_24				integer			null,
	age_25_49				integer			null,
	age_50_99				integer			null,
	male_age_0_13			integer			null,
	male_age_14_17			integer			null,
	male_age_18_24			integer			null,
	male_age_25_49			integer			null,
	male_age_50_99			integer			null,
	female_age_0_13		    integer		    null,
	female_age_14_17		integer			null,
	female_age_18_24		integer			null,
	female_age_25_49		integer			null,
	female_age_50_99		integer			null,
	screens					integer			null,
    region_class			char(1)			null,
    exhibitor_name          varchar(50)     null
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
			count( movie_history.movie_id )
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
            exhibitor.exhibitor_name
order by film_market.film_market_no,
		 film_market.film_market_desc,
		 complex.complex_name
for read only

open movie_csr
fetch movie_csr into @film_market_no, @film_market_desc, @complex_name, @complex_id, @movie_target, @region_class, @exhibitor_name, @total_movies
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

  select @age_0_13 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F1' or audience_profile_code = 'M1' )

  select @age_14_17 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F2' or audience_profile_code = 'M2' )

  select @age_18_24 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F3' or audience_profile_code = 'M3' )

  select @age_25_49 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F4' or audience_profile_code = 'M4' )

  select @age_50_99	= count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F5' or audience_profile_code = 'M5' )

  select @male_age_0_13 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'M1' )

  select @male_age_14_17 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'M2' )

  select @male_age_18_24 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'M3' )

  select @male_age_25_49 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'M4' )

  select @male_age_50_99	= count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'M5' )

  select @female_age_0_13 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F1' )
  select @female_age_14_17 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F2' )

  select @female_age_18_24 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F3' )

  select @female_age_25_49 = count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F4' )

  select @female_age_50_99	= count( movie_history.movie_id )
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
			movie_history.movie_id in (select movie_id from target_audience where audience_profile_code = 'F5' )

		insert into #results
		(
			no_weeks,
			film_market_no,
			film_market_desc,
			complex_name,
			movie_target,
			total_movies,
			age_0_13,
			age_14_17,
			age_18_24,
			age_25_49,
			age_50_99,
			male_age_0_13,
			male_age_14_17,
			male_age_18_24,
			male_age_25_49,
			male_age_50_99,
			female_age_0_13,
			female_age_14_17,
			female_age_18_24,
			female_age_25_49,
			female_age_50_99,
         screens,
         region_class,
         exhibitor_name ) values
		(
			@no_weeks,
			@film_market_no,
			@film_market_desc,
			@complex_name,
			@movie_target,
			@total_movies,
			@age_0_13,
			@age_14_17,
			@age_18_24,
			@age_25_49,
			@age_50_99,
			@male_age_0_13,
			@male_age_14_17,
			@male_age_18_24,
			@male_age_25_49,
			@male_age_50_99,
			@female_age_0_13,
			@female_age_14_17,
			@female_age_18_24,
			@female_age_25_49,
			@female_age_50_99,
         @screens,
         @region_class,
         @exhibitor_name
		)

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error', 16, 1)
			return -1
		end 

    fetch movie_csr into @film_market_no, @film_market_desc, @complex_name, @complex_id, @movie_target, @region_class, @exhibitor_name, @total_movies

end

close movie_csr
deallocate movie_csr

select * from #results
return 0
GO
