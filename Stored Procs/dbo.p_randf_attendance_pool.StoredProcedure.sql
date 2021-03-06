/****** Object:  StoredProcedure [dbo].[p_randf_attendance_pool]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_randf_attendance_pool]
GO
/****** Object:  StoredProcedure [dbo].[p_randf_attendance_pool]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create PROCEDURE [dbo].[p_randf_attendance_pool]	@resultId int
AS

declare			@start_date						datetime,
				@end_date						datetime,
				@country_code					char(1),
				@cinetam_reporting_demo_id		int,
				@attendance_estimate_one		int,
				@attendance_estimate_fifty_two	int,
				@result_id						int

set nocount on


set @result_id = @resultId


select			@start_date = min(screening_date) 
from			cinetam_reachfreq_results_fsd_xref
where			result_id = @result_id

select			@end_date = dateadd(wk, 51, @start_date)

select			@country_code= rset.country_code,
				@cinetam_reporting_demo_id = r.cinetam_reporting_demographics_id
from			cinetam_reachfreq_results r join cinetam_reachfreq_resultset rset 
on				r.resultset_id=rset.resultset_id 
where			result_id = @result_id

select			@attendance_estimate_one = 	isnull(sum(isnull(total_attendance,0)),0)
from			v_cinetam_movie_history_rfmkt as vmkt	
join			cinetam_reachfreq_results_mkt_xref mkt on vmkt.film_market_no = mkt.film_market_no 
join			film_screening_date_attendance_prev fsdap on vmkt.screening_date = fsdap.prev_screening_date
where 			fsdap.screening_date = @start_date
and				vmkt.country = @country_code				
and				vmkt.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
and				result_id = @result_id					

select			@attendance_estimate_fifty_two = 	isnull(sum(isnull(total_attendance,0)),0)
from			v_cinetam_movie_history_rfmkt as vmkt
join			cinetam_reachfreq_results_mkt_xref mkt on vmkt.film_market_no = mkt.film_market_no
join			film_screening_date_attendance_prev fsdap on vmkt.screening_date = fsdap.prev_screening_date
where 			fsdap.screening_date between @start_date and @end_date				
and				vmkt.country = @country_code			
and				vmkt.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
and				result_id = @result_id

select			@attendance_estimate_one as 'attendance_estimate_one',
				@attendance_estimate_fifty_two	as 'attendance_estimate_fifty_two'

return 0
GO
