/****** Object:  StoredProcedure [dbo].[p_attendance_digital]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_digital]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_digital]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_attendance_digital]		@country_code				char(1),
																@regional_indicator		char(1),
																@start_date						datetime,
																@end_date						datetime
																
as

declare			@screening_date				datetime,
						@full_attendance				int,
						@non_digital_attendance	int,										
						@digital_attendance			int
						
create table #attendance
(
screeening_date				datetime			null,
full_attendance				int						null,
non_digital_attendance	int						null,										
digital_attendance			int						null,
country_code					char(1)				null,
regional_indicator			char(1)				null,
start_date							datetime			null,
end_date							datetime			null
)

declare		attendance_csr cursor for
select			screening_date,
					avg(attendance)
from			movie_history,
					complex,
					complex_region_class
where			movie_history.country = @country_code
and				movie_history.screening_date between @start_date and @end_date
and				movie_history.complex_id = complex.complex_id
and				complex.complex_region_class = complex_region_class.complex_region_class
and				(regional_indicator = @regional_indicator or @regional_indicator = 'A')
group by		screening_date
order by		screening_date
for				read only


open attendance_csr
fetch attendance_csr into @screening_date, @full_attendance
while(@@fetch_status = 0)
begin

	select		@digital_attendance = avg(attendance)
	from		movie_history,
					complex,
					complex_region_class
	where		movie_history.country = @country_code
	and			movie_history.screening_date =@screening_date
	and			movie_history.complex_id = complex.complex_id
	and			complex.complex_region_class = complex_region_class.complex_region_class
	and			(regional_indicator = @regional_indicator or @regional_indicator = 'A')
	and			movie_history.advertising_open = 'Y'
	and			print_medium = 'D'
	
	select		@non_digital_attendance = avg(attendance)
	from		movie_history,
					complex,
					complex_region_class
	where		movie_history.country = @country_code
	and			movie_history.screening_date =@screening_date
	and			movie_history.complex_id = complex.complex_id
	and			complex.complex_region_class = complex_region_class.complex_region_class
	and			(regional_indicator = @regional_indicator or @regional_indicator = 'A')
	and			movie_history.advertising_open = 'Y'
	and			print_medium <> 'D'	

	insert into #attendance values(@screening_date,@full_attendance,@non_digital_attendance,@digital_attendance,@country_code,@regional_indicator,@start_date,@end_date)

	fetch attendance_csr into @screening_date, @full_attendance
end



select * from #attendance

return 0
GO
