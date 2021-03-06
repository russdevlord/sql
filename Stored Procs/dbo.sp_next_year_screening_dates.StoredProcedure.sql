/****** Object:  StoredProcedure [dbo].[sp_next_year_screening_dates]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sp_next_year_screening_dates]
GO
/****** Object:  StoredProcedure [dbo].[sp_next_year_screening_dates]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_next_year_screening_dates]
	@screening_dates varchar(max)
AS
BEGIN	
	IF OBJECT_ID('tempdb..#screening_dates') IS NOT NULL
				DROP TABLE #screening_dates

	create table #screening_dates                  
	(                  
		screening_date         datetime   not null                  
	)  

	if len(@screening_dates) > 0                  
	 insert into #screening_dates                  
	 select * from dbo.f_multivalue_parameter(@screening_dates,',')      

	select screening_date,dbo.[f_next_attendance_screening_date](screening_date) as next_year_screening_date from #screening_dates

END
GO
