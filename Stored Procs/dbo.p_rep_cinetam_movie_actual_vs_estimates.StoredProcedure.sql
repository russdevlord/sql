/****** Object:  StoredProcedure [dbo].[p_rep_cinetam_movie_actual_vs_estimates]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_cinetam_movie_actual_vs_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_cinetam_movie_actual_vs_estimates]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rep_cinetam_movie_actual_vs_estimates]
	
	@movie_name varchar(200)
	,@country_code char(4)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	declare @movie varchar(200), @country char(4)
	
	set @movie = @movie_name
	set @country = @country_code
	
	
	SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#a') IS NOT NULL  DROP TABLE #a


	SELECT        type, screening_date, cinetam_reporting_demographics_desc, long_name, avg_att_per_print, no_prints, country_code
	,RANK() over (order  by country_code, screening_date, long_name,cinetam_reporting_demographics_desc) as r
	into #a
	FROM            v_cinetam_movie_est_vs_act
	WHERE        (long_name = @movie)
	AND (country_code = @country)
	ORDER BY screening_date,long_name,cinetam_reporting_demographics_desc


	select distinct a.type, a.screening_date, a.cinetam_reporting_demographics_desc, a.long_name, a.avg_att_per_print, a.no_prints, a.country_code 
	,case when a.type = 'Estimates' then '' else sum(a.no_prints - b.no_prints) end as diff
	from #a as a
	inner join #a as b on a.r = b.r
	group by a.r,a.type,  a.screening_date, a.cinetam_reporting_demographics_desc, a.long_name, a.avg_att_per_print, a.no_prints , a.country_code 
	ORDER BY a.screening_date, a.long_name, a.cinetam_reporting_demographics_desc,a.type
	
	
END
GO
