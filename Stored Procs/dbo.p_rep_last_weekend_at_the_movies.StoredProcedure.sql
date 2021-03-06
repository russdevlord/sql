/****** Object:  StoredProcedure [dbo].[p_rep_last_weekend_at_the_movies]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_last_weekend_at_the_movies]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_last_weekend_at_the_movies]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rep_last_weekend_at_the_movies]

	@country_code		varchar(1)
	,@screening_date datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	create TABLE #attendance_pivot (
	  movie_name VARCHAR(100),
	  [Female 14 - 17] INT,
	  [Female 14 - 24] INT,
	  [Female 18 - 24] INT,
	  [Female 18 - 39] INT,
	  [Female 18 - 54] INT,
	  [Female 25 - 29] INT,
	  [Female 25 - 39] INT,
	  [Female 25 - 54] INT,
	  [Female 30 - 39] INT,
	  [Female 40 - 54] INT,
	  [Female 55 - 64] INT,
	  [Female 65 - 74] INT,
	  [Female 75 +] INT,
	  [Male 14 - 17] INT,
	  [Male 14 - 24] INT,
	  [Male 18 - 24] INT,
	  [Male 18 - 39] INT,
	  [Male 18 - 54] INT,
	  [Male 25 - 29] INT,
	  [Male 25 - 39] INT,
	  [Male 25 - 54] INT,
	  [Male 30 - 39] INT,
	  [Male 40 - 54] INT,
	  [Male 55 - 64] INT,
	  [Male 65 - 74] INT,
	  [Male 75 +] INT
	)
	
	select row_mode
	,replace(long_name, '3D', '') as movie_name
	,country_code
	,cinetam_demographics_desc
	,sum(demo_attendance) as demo_attendance
	into #attendance
	from v_cinetam_movie_demo_weekend_report
	WHERE country_code = @country_code
	AND screening_date = @screening_date
	--AND cinetam_demographics_desc IN(@demographic_desc)
	--and film_market_no in (@film_market)
	and SUBSTRING(cinetam_demographics_desc, 0, 4) <> 'All'
	and cinetam_demographics_desc not in ('Female 14+', 'Male 14+')
	group by row_mode,  long_name, country_code, cinetam_demographics_desc
	order by long_name, cinetam_demographics_desc
	
	DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
	DECLARE @ColumnName AS NVARCHAR(MAX)
	 
	--Get distinct values of the PIVOT Column 
	SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
		   + QUOTENAME(cinetam_demographics_desc)
	FROM (SELECT DISTINCT cinetam_demographics_desc FROM #attendance where SUBSTRING(cinetam_demographics_desc, 0, 4) <> 'All') AS attendance
	order by cinetam_demographics_desc

	--Prepare the PIVOT query using the dynamic 
	SET @DynamicPivotQuery = 
	  N'insert into #attendance_pivot
		SELECT movie_name, ' + @ColumnName + '
		FROM #attendance
		PIVOT(sum(demo_attendance) 
			  FOR cinetam_demographics_desc IN (' + @ColumnName + ')) AS PVTTable
		group by movie_name, ' + @ColumnName + '
		order by movie_name'
	--Execute the Dynamic Pivot Query
	EXEC sp_executesql @DynamicPivotQuery
	
	
	select
	movie_name,
	[14-17] as '14-17',
	[Female 14 - 17] as '14-17 female',
	[Male 14 - 17] as '14-17 male',
	DENSE_RANK() over (order by [14-17] desc)  as '14-17 rank',
	case when [14-17] > 0 then (cast([Female 14 - 17] as float) / CAST([14-17] as float)) * 100 
		 else 0 
		 end as 'Female 14 - 17',
	case when [14-17] > 0 then (cast([Male 14 - 17] as float) / CAST([14-17] as float)) * 100
		 else 0 
		 end as 'Male 14 - 17',
	[14-24] as '14-24',	 
	[Female 14 - 24] as '14-24 female',	 
	[Male 14 - 24] as '14-24 male',	 
	DENSE_RANK() over (order by [14-24] desc)  as '14-24 rank',
	case when [14-24] > 0 then (cast([Female 14 - 24] as float) / CAST([14-24] as float)) * 100
		 else 0 
		 end as 'Female 14 - 24',
	case when [14-24] > 0 then (cast([Male 14 - 24] as float) / CAST([14-24] as float)) * 100 
		 else 0 
		 end as 'Male 14 - 24',
	[18-24] as '18-24',	 
	[Female 18 - 24] as '18-24 female',	 
	[Male 18 - 24] as '18-24 male',
	DENSE_RANK() over (order by [18-24] desc)  as '18-24 rank',
	case when [18-24] > 0 then (cast([Female 18 - 24] as float) / CAST([18-24] as float)) * 100
		 else 0 
		 end as 'Female 18 - 24',
	case when [18-24] > 0 then (cast([Male 18 - 24] as float) / CAST([18-24] as float)) * 100
		 else 0 
		 end as  'Male 18 - 24',
	[18-39] as '18-39',	 
	[Female 18 - 39] as '18-39 female',
	[Male 18 - 39] as '18-39 male',
	DENSE_RANK() over (order by [18-39] desc)  as '18-39 rank',
	case when [18-39] > 0 then (cast([Female 18 - 39] as float) / CAST([18-39] as float)) * 100
		 else 0 
		 end as  'Female 18 - 39',
	case when [18-39] > 0 then (cast([Male 18 - 39] as float) / CAST([18-39] as float)) * 100
		 else 0 
		 end as  'Male 18 - 39',
	[18-54]	 as '18-54',
	[Female 18 - 54] as '18-54 female',	 
	[Male 18 - 54] as '18-54 male',
	DENSE_RANK() over (order by [18-54] desc)  as '18-54 rank',
	case when [18-54] > 0 then (cast([Female 18 - 54] as float) / CAST([18-54] as float)) * 100
		 else 0 
		 end as  'Female 18 - 54',
	case when [18-54] > 0 then (cast([Male 18 - 54] as float) / CAST([18-54] as float)) * 100
		 else 0 
		 end as  'Male 18 - 54',
	[25-29] as '25-29',
	[Female 25 - 29] as '25-29 female', 
	[Male 25 - 29] as '25-29 male',
	DENSE_RANK() over (order by [25-29] desc)  as '25-29 rank',
	case when [25-29] > 0 then (cast([Female 25 - 29] as float) / CAST([25-29] as float)) * 100
		 else 0 
		 end as  'Female 25 - 29',
	case when [25-29] > 0 then (cast([Male 25 - 29] as float) / CAST([25-29] as float)) * 100
		 else 0 
		 end as  'Male 25 - 29',
	[25-39]	 as '25-39',
	[Female 25 - 39] as	'25-39 female', 
	[Male 25 - 39] as '25-39 male',
	DENSE_RANK() over (order by [25-39] desc)  as '25-39 rank',
	case when [25-39] > 0 then (cast([Female 25 - 39] as float) / CAST([25-39] as float)) * 100
		 else 0 
		 end as  'Female 25 - 39',
	case when [25-39] > 0 then (cast([Male 25 - 39] as float) / CAST([25-39] as float)) * 100
		 else 0 
		 end as  'Male 25 - 39',
	[25-54] as '25-54',
	[Female 25 - 54] as '25-54 female',
	[Male 25 - 54] as '25-54 male',
	DENSE_RANK() over (order by [25-54] desc)  as '25-54 rank',
	case when [25-54] > 0 then (cast([Female 25 - 54] as float) / CAST([25-54] as float)) * 100
		 else 0 
		 end as  'Female 25 - 54',
	case when [25-54] > 0 then (cast([Male 25 - 54] as float) / CAST([25-54] as float)) * 100
		 else 0 
		 end as  'Male 25 - 54',
	[30-39]	 as '30-39',
	[Female 30 - 39] as '30-39 female', 	 
	[Male 30 - 39] as '30-39 male',
	DENSE_RANK() over (order by [30-39] desc)  as '30-39 rank',
	case when [30-39] > 0 then (cast([Female 30 - 39] as float) / CAST([30-39] as float)) * 100
		 else 0 
		 end as  'Female 30 - 39',
	case when [30-39] > 0 then (cast([Male 30 - 39] as float) / CAST([30-39] as float)) * 100
		 else 0 
		 end as  'Male 30 - 39',
	[40-54]	 as '40-54',
	[Female 40 - 54] as '40-54 female',	 
	[Male 40 - 54] as '40-54 male',
	DENSE_RANK() over (order by [40-54] desc)  as '40-54 rank',
	case when [40-54] > 0 then (cast([Female 40 - 54] as float) / CAST([40-54] as float)) * 100
		 else 0 
		 end as  'Female 40 - 54',
	case when [40-54] > 0 then (cast([Male 40 - 54] as float) / CAST([40-54] as float)) * 100
		 else 0 
		 end as  'Male 40 - 54',
	[55-64] as '55-64',
	[Female 55 - 64] as '55-64 female',	 
	[Male 55 - 64] as '55-64 male',
	DENSE_RANK() over (order by [55-64] desc)  as '55-64 rank',
	case when [55-64] > 0 then (cast([Female 55 - 64] as float) / CAST([55-64] as float)) * 100
		 else 0 
		 end as  'Female 55 - 64',
	case when [55-64] > 0 then (cast([Male 55 - 64] as float) / CAST([55-64] as float)) * 100
		 else 0 
		 end as  'Male 55 - 64',
	[65-74]	as  '65-74',
	[Female 65 - 74] as '65-74 female', 	 
	[Male 65 - 74] as '65-74 male',
	DENSE_RANK() over (order by [65-74] desc)  as '65-74 rank',
	case when [65-74] > 0 then (cast([Female 65 - 74] as float) / CAST([65-74] as float)) * 100
		 else 0 
		 end as  'Female 65 - 74',
	case when [65-74] > 0 then (cast([Male 65 - 74] as float) / CAST([65-74] as float)) * 100
		 else 0 
		 end as  'Male 65 - 74',
	[75 +] as '75+',	 
	[Female 75 +] as '75+ female',	 
	[Male 75 +] as '75+ male',
	DENSE_RANK() over (order by [75 +] desc)  as '75 + rank',
	case when [75 +] > 0 then (cast([Female 75 +] as float) / CAST([75 +] as float)) * 100
		 else 0 
		 end as  'Female 75 +',
	case when [75 +] > 0 then (cast([Male 75 +] as float) / CAST([75 +] as float)) * 100
		 else 0 
		 end as  'Male 75 +'
	from (select movie_name
			,isnull([Female 14 - 17], 0) + isnull([Male 14 - 17], 0) as [14-17]
			,isnull([Female 14 - 17], 0) as [Female 14 - 17]
			,isnull([Male 14 - 17], 0) as [Male 14 - 17]
			,isnull([Female 14 - 24], 0) + isnull([Male 14 - 24], 0) as [14-24]
			,isnull([Female 14 - 24], 0) as [Female 14 - 24]
			,isnull([Male 14 - 24], 0) as [Male 14 - 24]
			,isnull([Female 18 - 24], 0) + isnull([Male 18 - 24], 0) as [18-24]
			,isnull([Female 18 - 24], 0) as [Female 18 - 24]
			,isnull([Male 18 - 24], 0) as [Male 18 - 24]
			,isnull([Female 18 - 39], 0) + isnull([Male 18 - 39], 0) as [18-39]
			,isnull([Female 18 - 39], 0) as [Female 18 - 39]
			,isnull([Male 18 - 39], 0) as [Male 18 - 39]
			,isnull([Female 18 - 54], 0) + isnull([Male 18 - 54], 0) as [18-54]
			,isnull([Female 18 - 54], 0) as [Female 18 - 54]
			,isnull([Male 18 - 54], 0) as [Male 18 - 54]
			,isnull([Female 25 - 29], 0) + isnull([Male 25 - 29], 0) as [25-29]
			,isnull([Female 25 - 29], 0) as [Female 25 - 29]
			,isnull([Male 25 - 29], 0) as [Male 25 - 29]
			,isnull([Female 25 - 39], 0) + isnull([Male 25 - 39], 0) as [25-39]
			,isnull([Female 25 - 39], 0) as [Female 25 - 39]
			,isnull([Male 25 - 39], 0) as [Male 25 - 39]
			,isnull([Female 25 - 54], 0) + isnull([Male 25 - 54], 0) as [25-54]
			,isnull([Female 25 - 54], 0) as [Female 25 - 54]
			,isnull([Male 25 - 54], 0) as [Male 25 - 54]
			,isnull([Female 30 - 39], 0) + isnull([Male 30 - 39], 0) as [30-39]
			,isnull([Female 30 - 39], 0) as [Female 30 - 39]
			,isnull([Male 30 - 39], 0) as [Male 30 - 39]
			,isnull([Female 40 - 54], 0) + isnull([Male 40 - 54], 0) as [40-54]
			,isnull([Female 40 - 54], 0) as [Female 40 - 54]
			,isnull([Male 40 - 54], 0) as [Male 40 - 54]
			,isnull([Female 55 - 64], 0) + isnull([Male 55 - 64], 0) as [55-64]
			,isnull([Female 55 - 64], 0) as [Female 55 - 64]
			,isnull([Male 55 - 64], 0) as [Male 55 - 64]
			,isnull([Female 65 - 74], 0) + isnull([Male 65 - 74], 0) as [65-74]
			,isnull([Female 65 - 74], 0) as [Female 65 - 74]
			,isnull([Male 65 - 74], 0) as [Male 65 - 74]
			,isnull([Female 75 +], 0) + isnull([Male 75 +], 0) as [75 +]
			,isnull([Female 75 +], 0) as [Female 75 +]
			,isnull([Male 75 +], 0) as  [Male 75 +]		
			from #attendance_pivot) as a
		    
END
GO
