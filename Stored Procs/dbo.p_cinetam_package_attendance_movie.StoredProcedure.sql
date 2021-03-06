/****** Object:  StoredProcedure [dbo].[p_cinetam_package_attendance_movie]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_package_attendance_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_package_attendance_movie]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop procedure [p_cinetam_package_attendance_movie]		
create proc [dbo].[p_cinetam_package_attendance_movie]				@Package_code				int

as

declare		@error																						int,
					@cinetam_reporting_demographics_desc				varchar(30),
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
Package_code																		int							null,
cinetam_reporting_demographics_desc					varchar(30)			null,
sort_order																			int							null,
long_name_1																		varchar(30)			null,
attendance_1																		numeric(22,12)	null,
long_name_2																		varchar(30)			null,
attendance_2																		numeric(22,12)	null,
long_name_3																		varchar(30)			null,
attendance_3																		numeric(22,12)	null
)

select		@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
from			cinetam_campaign_package_settings, 
					cinetam_reporting_demographics 
where		cinetam_campaign_package_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and				cinetam_campaign_package_settings.package_id = @Package_code

select		@total_attendance = sum(v_cinetam_movie_history_Details.attendance)
from			movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					v_cinetam_movie_history_Details,
					cinetam_campaign_package_settings
where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				movie_history.complex_id = v_cinetam_movie_history_Details.complex_id
and				movie_history.movie_id = v_cinetam_movie_history_Details.movie_id
and				movie_history.screening_date = v_cinetam_movie_history_Details.screening_date
and				movie_history.occurence = v_cinetam_movie_history_Details.occurence
and				movie_history.print_medium = v_cinetam_movie_history_Details.print_medium
and				movie_history.three_d_type = v_cinetam_movie_history_Details.three_d_type
and				v_cinetam_movie_history_Details.cinetam_reporting_demographics_id = cinetam_campaign_package_settings.cinetam_reporting_demographics_id
and             cinetam_campaign_package_settings.package_id = campaign_spot.package_id
and				campaign_spot.package_id = @Package_code

select @sort_order = 0
declare		attendance_csr  cursor static for
select 		movie.long_name,
					sum(v_cinetam_movie_history_Details.attendance) as attendance
from			    movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					v_cinetam_movie_history_Details,
					movie,
					cinetam_campaign_package_settings
where		    campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				v_certificate_item_distinct.certificate_group = v_cinetam_movie_history_Details.certificate_group
and				movie.movie_id = movie_history.movie_id
and				movie_history.complex_id = v_cinetam_movie_history_Details.complex_id
and				movie_history.movie_id = v_cinetam_movie_history_Details.movie_id
and				movie_history.screening_date = v_cinetam_movie_history_Details.screening_date
and				movie_history.occurence = v_cinetam_movie_history_Details.occurence
and				movie_history.print_medium = v_cinetam_movie_history_Details.print_medium
and				movie_history.three_d_type = v_cinetam_movie_history_Details.three_d_type
and				v_cinetam_movie_history_Details.cinetam_reporting_demographics_id = cinetam_campaign_package_settings.cinetam_reporting_demographics_id
and             cinetam_campaign_package_settings.package_ID = campaign_spot.package_ID
and				campaign_spot.package_ID = @Package_code
group by 	movie.long_name
order by	sum(v_cinetam_movie_history_Details.attendance) desc					
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
		insert into #campaign_movie_attendance values (	@Package_code, 
																											@cinetam_reporting_demographics_desc, 
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
