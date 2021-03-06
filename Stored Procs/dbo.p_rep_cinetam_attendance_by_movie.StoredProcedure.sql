/****** Object:  StoredProcedure [dbo].[p_rep_cinetam_attendance_by_movie]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_cinetam_attendance_by_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_cinetam_attendance_by_movie]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Moura
-- Create date: 12/03/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rep_cinetam_attendance_by_movie] 
	@country_code char(4)
	,@demographic_desc varchar(1000)
	,@from_date datetime
	,@to_date datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @country char(4) , @demo varchar(1000), @f_date datetime, @s_date datetime 
	
	set @country = @country_code
	set @demo = @demographic_desc
	set @f_date = @from_date
	set @s_date = @to_date
	

	 IF OBJECT_ID('tempdb..#movie_attendance') IS NOT NULL  DROP TABLE #movie_attendance

	  SELECT
		   row_mode
		  ,[movie_id]
		  ,[long_name]
		  ,[country_code]
		  ,case when [cinetam_demographics_desc] = 'All People Attendance' 	then '_All People Attendance' else [cinetam_demographics_desc] 	
				end  as cinetam_demographics_desc
		  ,sum([demo_attendance]) as sum_demo_attendance
	   --   ,[no_prints_this_week]
		 -- ,[movie_classification_code]
		  ,--[movie_classification_desc]
		  --,[movie_category_code]
		  --,[movie_category_desc] 
	 (case when [cinetam_demographics_desc] = 'All People Attendance' then sum([demo_attendance]) else 0 
			end) as All_People_Attendance
	into #movie_attendance
	  FROM [production].[dbo].[v_cinetam_movie_demo_report]
	WHERE country_code = @country
	AND screening_date between @f_date and @s_date
	AND cinetam_demographics_desc IN(@demo)
	group by movie_id,long_name, country_code, row_mode,[cinetam_demographics_desc]

	select a.row_mode, a.movie_id,long_name,country_code,cinetam_demographics_desc, sum_demo_attendance,All_People_Attendance
    ,b.total
    from #movie_attendance as a
    inner join (select movie_id, row_mode,sum(sum_demo_attendance) as total 
				from #movie_attendance as c 
				group by movie_id, row_mode)  as b on b.movie_id = a.movie_id and b.row_mode = a.row_mode
				
    group by a.row_mode, a.movie_id,long_name,country_code,cinetam_demographics_desc, sum_demo_attendance,All_People_Attendance,b.total
    order by b.total desc-- long_name, [cinetam_demographics_desc]

END
GO
