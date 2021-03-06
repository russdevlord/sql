/****** Object:  StoredProcedure [dbo].[p_campaign_attendance_market]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_attendance_market]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_attendance_market]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_campaign_attendance_market]				@campaign_no				int

as

declare		@error																						int,
					@reporting_demographics_desc				varchar(30),
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

create table #campaign_market_attendance
(
campaign_no																		int							null,
reporting_demographics_desc					varchar(30)			null,
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

select		@reporting_demographics_desc = 'All attendance'--cinetam_reporting_demographics_desc
--from			cinetam_campaign_settings, 
					--cinetam_reporting_demographics 
--where		cinetam_campaign_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
--and				cinetam_campaign_settings.campaign_no = @campaign_no

select		@total_attendance = sum(movie_history.attendance)
from			movie_history,
					v_certificate_item_distinct,
					campaign_spot--,
--					cinetam_movie_history,
--					cinetam_reporting_demographics_xref,
--					cinetam_campaign_settings
where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
--and				movie_history.complex_id = cinetam_movie_history.complex_id
--and				movie_history.movie_id = cinetam_movie_history.movie_id
--and				movie_history.screening_date = cinetam_movie_history.screening_date
--and				movie_history.occurence = cinetam_movie_history.occurence
--and				movie_history.print_medium = cinetam_movie_history.print_medium
--and				movie_history.three_d_type = cinetam_movie_history.three_d_type
--and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
--and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
--and               cinetam_campaign_settings.campaign_no = campaign_spot.campaign_no
and				campaign_spot.campaign_no = @campaign_no

declare		attendance_csr  cursor static for
select 		film_market_desc,
					film_market.film_market_no,
					film_market_code,
					sum(movie_history.attendance) as attendance
from			movie_history,
					v_certificate_item_distinct,
					campaign_spot,
--					cinetam_movie_history,
					complex,
					film_market--,
--					cinetam_reporting_demographics_xref,
--					cinetam_campaign_settings
where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				campaign_spot.complex_id = complex.complex_id
and				complex.film_market_no = film_market.film_market_no
--and				movie_history.complex_id = cinetam_movie_history.complex_id
--and				movie_history.movie_id = cinetam_movie_history.movie_id
--and				movie_history.screening_date = cinetam_movie_history.screening_date
--and				movie_history.occurence = cinetam_movie_history.occurence
--and				movie_history.print_medium = cinetam_movie_history.print_medium
--and				movie_history.three_d_type = cinetam_movie_history.three_d_type
--and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
--and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
--and             cinetam_campaign_settings.campaign_no = campaign_spot.campaign_no
and				campaign_spot.campaign_no = @campaign_no
group by 	film_market_desc,
					film_market.film_market_no,
					film_market_code
order by	sum(movie_history.attendance) desc					
for				read only

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
		
	select	@attendance1 = @attendance1 / @total_attendance,		
					@attendance2 = @attendance2 / @total_attendance,		
					@attendance3 = @attendance3 / @total_attendance

	if 	round(@attendance1, 3) = 0.000
		select	@film_market_desc1 = null,
						@film_market_code1 = null,
						@film_market_no1 = null,
						@attendance1 = null
						
	if 	round(@attendance2, 3) = 0.000
		select	@film_market_desc2 = null,
						@film_market_code2 = null,
						@film_market_no2 = null,
						@attendance2 = null

	if 	round(@attendance3, 3) = 0.000
		select	@film_market_desc3 = null,
						@film_market_code3 = null,
						@film_market_no3 = null,
						@attendance3 = null					
					
	if not (@attendance1 is null and 	@attendance1 is null and @attendance1 is null)
		insert into #campaign_market_attendance values (	@campaign_no, 
																											@reporting_demographics_desc, 
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

deallocate attendance_csr

select * from #campaign_market_attendance
return 0
GO
