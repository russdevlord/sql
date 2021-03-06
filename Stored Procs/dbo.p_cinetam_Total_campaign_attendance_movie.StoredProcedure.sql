/****** Object:  StoredProcedure [dbo].[p_cinetam_Total_campaign_attendance_movie]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_Total_campaign_attendance_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_Total_campaign_attendance_movie]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_Total_campaign_attendance_movie]				@campaign_no				int

as

declare		@error																						int,
					--@cinetam_reporting_demographics_desc				varchar(30),
					@long_name1																		varchar(30),
					@attendance1																		numeric(22,12),
					@long_name2																		varchar(30),
					@attendance2																		numeric(22,12),
					@long_name3																		varchar(30),
					@attendance3																		numeric(22,12),
					@sort_order																			int,
					@total_attendance																numeric(22,12)

create table #campaign_movie_attendance
(
campaign_no																		int							null,
--cinetam_reporting_demographics_desc					varchar(30)			null,
sort_order																			int							null,
long_name_1																		varchar(30)			null,
attendance_1																		numeric(22,12)	null,
long_name_2																		varchar(30)			null,
attendance_2																		numeric(22,12)	null,
long_name_3																		varchar(30)			null,
attendance_3																		numeric(22,12)	null
)

select		@total_attendance = 
sum(attendance)
FROM(
select	Distinct cinetam_movie_history.*
from			    movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history,
					cinetam_reporting_demographics_xref,
					cinetam_campaign_actuals,
					movie
where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and			v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				movie_history.complex_id = cinetam_movie_history.complex_id
and				movie_history.movie_id = cinetam_movie_history.movie_id
and				movie_history.screening_date = cinetam_movie_history.screening_date
and				movie_history.occurence = cinetam_movie_history.occurence
and				movie_history.print_medium = cinetam_movie_history.print_medium
and				movie_history.three_d_type = cinetam_movie_history.three_d_type
and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_actuals.cinetam_demographics_id
and             cinetam_campaign_actuals.campaign_no = campaign_spot.campaign_no
and				cinetam_campaign_actuals.campaign_no = @campaign_no
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = 1
)a


select @sort_order = 0

declare		attendance_csr  cursor static for
Select long_name, Sum(attendance) as attendance
FROM
(select Distinct	movie.long_name, cinetam_movie_history.*
					--movie.long_name,
					--sum(cinetam_movie_history.attendance) as attendance
from			    movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history,
					cinetam_reporting_demographics_xref,
					cinetam_campaign_actuals,
					movie
where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and			v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				movie_history.complex_id = cinetam_movie_history.complex_id
and				movie_history.movie_id = cinetam_movie_history.movie_id
and				movie_history.screening_date = cinetam_movie_history.screening_date
and				movie_history.occurence = cinetam_movie_history.occurence
and				movie_history.print_medium = cinetam_movie_history.print_medium
and				movie_history.three_d_type = cinetam_movie_history.three_d_type
and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_actuals.cinetam_demographics_id
and             cinetam_campaign_actuals.campaign_no = campaign_spot.campaign_no
and				movie.movie_id = cinetam_movie_history.movie_id
and				cinetam_campaign_actuals.campaign_no = 207334--@campaign_no
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = 1
)a
group by 	long_name
order by	Sum(attendance) desc	
				
for				read only

open  attendance_csr
fetch attendance_csr into @long_name1, @attendance1
while(@@fetch_status = 0)
begin
	
	select	@long_name2 = null,
					@attendance2 = null,
					@long_name3 = null,
					@attendance3 = null
					
	select @sort_order = @sort_order + 1					
	
	fetch attendance_csr into @long_name2, @attendance2

	if @@fetch_status = 0
		fetch attendance_csr into @long_name3, @attendance3
		
	select	@attendance1 = round(@attendance1 / @total_attendance,3),
					@attendance2 = round(@attendance2 / @total_attendance,3),		
					@attendance3 = round(@attendance3 / @total_attendance,3)

	if 	round(@attendance1, 3) = 0.000	
		select	@long_name1 = null,
						@attendance1 = null
						
	if 	round(@attendance2, 3) = 0.000	
		select	@long_name2 = null,
						@attendance2 = null

	if 	round(@attendance3, 3) = 0.000	
		select	@long_name3 = null,
						@attendance3 = null

	if not (@attendance1 is null and 	@attendance1 is null and @attendance1 is null)
		insert into #campaign_movie_attendance values (	@campaign_no, 
																											--@cinetam_reporting_demographics_desc, 
																											@sort_order,
																											@long_name1, 
																											@attendance1, 
																											@long_name2, 
																											@attendance2, 
																											@long_name3, 
																											@attendance3	)

	fetch attendance_csr into @long_name1, @attendance1
end

deallocate attendance_csr

select * from #campaign_movie_attendance
return 0
GO
