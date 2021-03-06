/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_actual_vs_estimates_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_movie_actual_vs_estimates_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_actual_vs_estimates_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_cinetam_movie_actual_vs_estimates_rpt]		@movie_id							int,
																																							@country_code					char(4),
																																							@start_date						datetime,
																																							@end_date							datetime
	
AS


-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

declare		@movie						int, 
					@country						char(4)

set @movie = @movie_id
set @country = @country_code

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#a') IS NOT NULL  DROP TABLE #a

SELECT			type as rowtype, 
				screening_date, 
				cinetam_reporting_demographics_desc, 
				long_name, 
				convert(numeric(30,20), attendance) as avg_att_per_print, 
				no_prints, 
				country_code,
				RANK() over (order  by country_code, screening_date, movie_id, long_name, cinetam_reporting_demographics_desc) as r
into			#a
FROM			v_cinetam_movie_est_vs_act_whole
WHERE			movie_id = @movie
AND				country_code = @country
and				screening_date between @start_date and @end_date
ORDER BY		screening_date,
							long_name,
							cinetam_reporting_demographics_desc


select			a.rowtype, 
				a.screening_date, 
				a.cinetam_reporting_demographics_desc, 
				a.long_name, 
				a.avg_att_per_print, 
				a.no_prints, 
				a.country_code,
				(a.avg_att_per_print / b.avg_att_per_print) - 1  as diff
from			#a as a
inner join		#a as b 
				on a.r = b.r
where			a.rowtype = 'Actuals'
and				b.rowtype = 'Estimates'		
and				b.avg_att_per_print	<> 0		
union 
select				a.rowtype, 
							a.screening_date, 
							a.cinetam_reporting_demographics_desc, 
							a.long_name, 
							a.avg_att_per_print, 
							a.no_prints, 
							a.country_code,
							null as diff
from					#a as a
where				a.rowtype = 'Estimates'
union 
select				a.rowtype, 
							a.screening_date, 
							a.cinetam_reporting_demographics_desc, 
							a.long_name, 
							a.avg_att_per_print, 
							a.no_prints, 
							a.country_code,
							null as diff
from					#a as a
where				a.rowtype = 'Actuals'
and						a.r not in (select r from #a where rowtype = 'Estimates' and avg_att_per_print <> 0)
ORDER BY		a.screening_date, 
							a.long_name, 
							a.cinetam_reporting_demographics_desc,
							a.rowtype							

return 0
GO
