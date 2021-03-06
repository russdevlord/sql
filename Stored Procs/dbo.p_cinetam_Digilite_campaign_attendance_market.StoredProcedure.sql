/****** Object:  StoredProcedure [dbo].[p_cinetam_Digilite_campaign_attendance_market]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_Digilite_campaign_attendance_market]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_Digilite_campaign_attendance_market]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_Digilite_campaign_attendance_market]				@campaign_no				int,
																																						@mode								char(1),
																																						@screening_date				datetime

as

declare		@error																						int,
					@cinetam_reporting_demographics_desc				varchar(30),
					@film_market_desc1															varchar(30),
					@film_market_no1																int,
					@film_market_code1															char(3),
					@attendance1																		numeric(22,12),
					@film_market_desc2															varchar(30),
					@film_market_no2																int,
					@film_market_code2															char(3),
					@attendance2																		numeric(22,12),
					@film_market_desc3															varchar(30),
					@film_market_no3																int,
					@film_market_code3															char(3),
					@attendance3																		numeric(22,12),
					@sort_order																			int,
					@total_attendance																numeric(22,12)


create table #campaign_Digilite_market_attendance
(
campaign_no																		int							null,
cinetam_reporting_demographics_desc					varchar(30)			null,
sort_order																			int							null,
film_market_desc_1															varchar(30)			null,
film_market_no_1																int							null,
film_market_code_1														char(3)					null,
attendance_1																		numeric(22,12)	null,
film_market_desc_2															varchar(30)			null,
film_market_no_2																int							null,
film_market_code_2														char(3)					null,
attendance_2																		numeric(22,12)	null,
film_market_desc_3															varchar(30)			null,
film_market_no_3																int							null,
film_market_code_3														char(3)					null,
attendance_3																		numeric(22,12)	null
)

if @mode = '4'
begin
	
	select		@total_attendance =SUM(a.attendance / a.no_spots) 
	FROM		(Select			movie_history.screening_date, 
												sum(movie_history.attendance) as attendance, 
												movie_history.complex_id,
												count(spot_id) as no_spots
							From			cinelight_spot,
												cinelight,
												complex,
												film_market,
												movie_history
							Where		cinelight_spot.cinelight_id = cinelight.cinelight_id
							and				cinelight.complex_id = complex.complex_id
							and				spot_status = 'X'
							and				cinelight_spot.campaign_no = @campaign_no
							and				movie_history.complex_id = complex.complex_id
							and				complex.film_market_no = film_market.film_market_no
							and				cinelight_spot.screening_date = movie_history.screening_date
							and				cinelight_spot.screening_date <= @screening_date
							group by	movie_history.screening_date, 
												movie_history.complex_id)  a
	
	select		@cinetam_reporting_demographics_desc = 'All People'


	declare		attendance_csr  cursor static for
	select		film_market_desc,
						film_market_no,
						film_market_code,
						SUM(attendance / no_spots) as attendance 
	FROM		(Select			Distinct film_market_desc,
												film_market.film_market_no,
												film_market_code, 
												movie_history.screening_date, 
												sum(movie_history.attendance) as attendance, 
												movie_history.complex_id,
												count(spot_id) as no_spots
							From			cinelight_spot,
												cinelight,
												complex,
												film_market,
												movie_history
							Where		cinelight_spot.cinelight_id = cinelight.cinelight_id
							and				cinelight.complex_id = complex.complex_id
							and				spot_status = 'X'
							and				cinelight_spot.campaign_no = @campaign_no
							and				movie_history.complex_id = complex.complex_id
							and				complex.film_market_no = film_market.film_market_no
							and				cinelight_spot.screening_date = movie_history.screening_date
							and				cinelight_spot.screening_date <= @screening_date
							group by	film_market_desc,
												film_market.film_market_no,
												film_market_code, 
												movie_history.screening_date, 
												movie_history.complex_id)  a
	group by		film_market_desc, 
							film_market_no,	
							film_market_code
	order by		SUM(attendance / no_spots)  desc					
	for					read only
	
end
else
begin

	select		@total_attendance = SUM(attendance / no_spots)
	FROM		(Select			cinetam_movie_history.screening_date, 
												sum(cinetam_movie_history.attendance) as attendance, 
												cinetam_movie_history.complex_id,
												count(spot_id) as no_spots
							From			cinelight_spot,
												cinelight,
												complex,
												film_market,
												cinetam_movie_history,
												cinetam_reporting_demographics_xref,
												cinetam_campaign_settings
							Where		cinelight_spot.cinelight_id = cinelight.cinelight_id
							and				cinelight.complex_id = complex.complex_id
							and				cinetam_campaign_settings.campaign_no = cinelight_spot.campaign_no
							and				cinelight_spot.campaign_no = @campaign_no
							and				cinetam_movie_history.complex_id = complex.complex_id
							and				complex.film_market_no = film_market.film_market_no
							and				cinelight_spot.screening_date = cinetam_movie_history.screening_date
							and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
							and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
							and				cinelight_spot.screening_date <= @screening_date
							group by	cinetam_movie_history.screening_date, 
												cinetam_movie_history.complex_id)a
	
	select		@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_campaign_settings, 
						cinetam_reporting_demographics 
	where		cinetam_campaign_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
	and				cinetam_campaign_settings.campaign_no = @campaign_no

	declare		attendance_csr  cursor static for
	select		film_market_desc,
						film_market_no,
						film_market_code,
						SUM(attendance / no_spots) as attendance 
	FROM		(Select			Distinct film_market_desc,
												film_market.film_market_no,
												film_market_code, 
												cinetam_movie_history.screening_date, 
												sum(cinetam_movie_history.attendance) as attendance, 
												cinetam_movie_history.complex_id,
												count(spot_id) as no_spots
							From			cinelight_spot,
												cinelight,
												complex,
												film_market,
												cinetam_movie_history,
												cinetam_reporting_demographics_xref,
												cinetam_campaign_settings
							Where		cinelight_spot.cinelight_id = cinelight.cinelight_id
							and				cinelight.complex_id = complex.complex_id
							and				cinetam_campaign_settings.campaign_no = cinelight_spot.campaign_no
							and				cinelight_spot.campaign_no = @campaign_no
							and				cinetam_movie_history.complex_id = complex.complex_id
							and				complex.film_market_no = film_market.film_market_no
							and				cinelight_spot.screening_date = cinetam_movie_history.screening_date
							and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
							and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
							and				cinelight_spot.screening_date <= @screening_date
							group by	film_market_desc,
												film_market.film_market_no,
												film_market_code, 
												cinetam_movie_history.screening_date, 
												cinetam_movie_history.complex_id)a
	group by		film_market_desc, 
							film_market_no,	
							film_market_code
	order by		SUM(attendance / no_spots)  desc					
	for					read only
end

select @sort_order = 0

open  attendance_csr
fetch attendance_csr into @film_market_desc1, @film_market_no1, @film_market_code1, @attendance1
while(@@fetch_status = 0)
begin
	
	select	@film_market_desc2 = null,
					@film_market_no2 = null,
					@film_market_code2 = null,
					@attendance2 = null,
					@film_market_desc3 = null,
					@film_market_no3 = null,
					@film_market_code3 = null,
					@attendance3 = null
					
	select @sort_order = @sort_order + 1
	
	fetch attendance_csr into @film_market_desc2, @film_market_no2, @film_market_code2, @attendance2

	if @@fetch_status = 0
		fetch attendance_csr into @film_market_desc3, @film_market_no3, @film_market_code3, @attendance3
		
	if 	round(@attendance1, 3) = 0.000
		select	@film_market_desc1 = null,
						@film_market_code1 = null,
						@film_market_no1 = null,
						@attendance1 = null
	else
		select 	@attendance1	= @attendance1 / @total_attendance		
						
						
	if 	round(@attendance2, 3) = 0.000
		select	@film_market_desc2 = null,
						@film_market_code2 = null,
						@film_market_no2 = null,
						@attendance2 = null
	else
		select 	@attendance2	= @attendance2 / @total_attendance		
	

	if 	round(@attendance3, 3) = 0.000
		select	@film_market_desc3 = null,
						@film_market_code3 = null,
						@film_market_no3 = null,
						@attendance3 = null					
	else
		select 	@attendance3	= @attendance3 / @total_attendance		
					
	if not (@attendance1 is null )
		insert into #campaign_Digilite_market_attendance values (	@campaign_no, 
																											@cinetam_reporting_demographics_desc, 
																											@sort_order,
																											@film_market_desc1, 
																											@film_market_no1,
																											@film_market_code1, 
																											@attendance1, 
																											@film_market_desc2, 
																											@film_market_no2, 
																											@film_market_code2,
																											@attendance2, 
																											@film_market_desc3, 
																											@film_market_no3, 
																											@film_market_code3, 
																											@attendance3 	)

	fetch attendance_csr into @film_market_desc1, @film_market_no1, @film_market_code1, @attendance1
end

close attendance_csr

select * from #campaign_Digilite_market_attendance
return 0
GO
