/****** Object:  StoredProcedure [dbo].[p_attendance_forcast_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_forcast_report]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_forcast_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [p_attendance_forcast_report] 'A','2018-11-01 00:00:00.000,2018-11-08 00:00:00.000','1',2


CREATE PROCEDURE [dbo].[p_attendance_forcast_report]
	 @country_code           char(1),     
	 @screening_dates          varchar(max),                  
     @film_markets           varchar(max),                  
     @cinetam_reporting_demographics_id  int       
AS
BEGIN
		declare @national_count int
		declare @metro_count  int
		declare @regional_count int   
		declare @total_attendance_movie_complex numeric(20,8) 
		declare @total_actual_attendance numeric(20,8) 

		create table #attendance_forcast_data
		(
			total_attendance_movie_complex   numeric(20,8) not null,    
			total_actual_attendance   numeric(20,8) not null,    
		)
		                  
		create table #screening_dates                  
		(                  
		 screening_date         datetime   not null                  
		) 

		if len(@screening_dates) > 0                  
		insert into #screening_dates                  
		select * from dbo.f_multivalue_parameter(@screening_dates,',')    
                  
		create table #film_markets                  
		(                  
		 film_market_no         int     not null                  
		)      

		if len(@film_markets) > 0                  
		 insert into #film_markets                  
		 select * from dbo.f_multivalue_parameter(@film_markets,',')    
                  
		select    @national_count = count(*)                  
		from     #film_markets                  
		where    film_market_no = -100                  
                  
		select    @metro_count = count(*)                  
		from     #film_markets                  
		where    film_market_no = -50                  
          
		select    @regional_count = count(*)                  
		from     #film_markets                  
		where    film_market_no = -25          
                 
		if @metro_count >= 1                  
		begin                  
		 delete    #film_markets                  
		 from     film_market                  
		 where    #film_markets.film_market_no = film_market.film_market_no                  
		 and     country_code = @country_code                  
		 and     regional = 'N'                  
                  
		 insert into  #film_markets                  
		 select    film_market_no                  
		 from     film_market                  
		 where    country_code = @country_code                  
		 and     regional = 'N'                  
		end                  
                  
		if @regional_count >= 1                  
		begin                  
		 delete    #film_markets                  
		 from     film_market                  
		 where    #film_markets.film_market_no = film_market.film_market_no                  
		 and     country_code = @country_code                  
		 and     regional = 'Y'                  
                  
		 insert into  #film_markets                  
		 select    film_market_no                  
		 from     film_market                  
		 where    country_code = @country_code                  
		 and     regional = 'Y'                  
		end                              
                  
		if @national_count >= 1                  
		begin                  
		 delete    #film_markets                  
		 from     film_market                  
		 where    #film_markets.film_market_no = film_market.film_market_no                  
		 and     country_code = @country_code                  
                  
		 insert into  #film_markets                  
		 select    film_market_no                  
		 from     film_market                  
		 where    country_code = @country_code                  
		end            
			
		--Total attendance from cinetam_movie_complex_estimates (totalled  from the weekly movie matching process) 
		select			@total_attendance_movie_complex = isnull(sum(isnull(ce.attendance,0)),0) 
		from			cinetam_movie_complex_estimates ce 
		inner join		(select movie_id, screening_date, complex_id, country from movie_history group by movie_id, screening_date, complex_id, country ) as mh 
		on				ce.movie_id	= mh.movie_id 
		and				ce.complex_id = mh.complex_id 
		and				ce.screening_date = mh.screening_date
		inner join		complex c on c.complex_id = ce.complex_id
		inner join		#film_markets fm on c.film_market_no = fm.film_market_no
		inner join		#screening_dates sd on mh.screening_date = sd.screening_date
		where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		and				mh.country = @country_code

		--Get total actual attendance
		if(@cinetam_reporting_demographics_id = 0)
		begin
			select @total_actual_attendance = isnull(sum(isnull(attendance,0)),0) from 
			movie_history mh join complex c on mh.complex_id=c.complex_id
			join #film_markets fm on c.film_market_no=fm.film_market_no
			join #screening_dates sd on mh.screening_date=sd.screening_date
			where mh.advertising_open='Y'
			and mh.country=@country_code
		end 
		else
		begin
			select @total_actual_attendance = isnull(sum(isnull(attendance,0)),0) from cinetam_movie_history cmh join complex c 
			on cmh.complex_id=c.complex_id
			join cinetam_reporting_demographics_xref as repoxref on cmh.cinetam_demographics_id=repoxref.cinetam_demographics_id
			join #film_markets fm on c.film_market_no=fm.film_market_no
			join #screening_dates sd on cmh.screening_date=sd.screening_date
			where repoxref.cinetam_reporting_demographics_id <> 0
			and repoxref.cinetam_reporting_demographics_id=@cinetam_reporting_demographics_id			
			and cmh.country_code =@country_code
		end

		insert into #attendance_forcast_data(total_attendance_movie_complex,total_actual_attendance)
		values (@total_attendance_movie_complex,@total_actual_attendance)

		select total_attendance_movie_complex,total_actual_attendance from #attendance_forcast_data		
END
GO
