/****** Object:  StoredProcedure [dbo].[p_rpt_cinetam_audience_by_genre]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_cinetam_audience_by_genre]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_cinetam_audience_by_genre]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rpt_cinetam_audience_by_genre]
	
	@country_code varchar(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @local_country_code varchar(1),
			@last_year int,
			@month int

	set @local_country_code = @country_code
	set @last_year = (select year(dateadd(Year,-1,getdate())))
	set @month = (month(getdate()))
	
   select cinetam_demographics_desc, SUM(demo_attendance) as demo_attendance ,movie_category_desc 

	from (	select	top 1000			cinetam_demographics_desc,
								sum(attendance) as demo_attendance,
								movie_category.movie_category_desc
			from				cinetam_movie_history,
									movie,
									cinetam_demographics,
									complex,
									film_market,
									movie_category,
									target_categories
			where			cinetam_movie_history.complex_id = complex.complex_id
			and					complex.film_market_no = film_market.film_market_no
			and					cinetam_movie_history.movie_id = movie.movie_id
			and					cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
			and					movie.movie_id = target_categories.movie_id
			and					target_categories.movie_category_code = movie_category.movie_category_code	
			and					cinetam_movie_history.country_code = @local_country_code		
			and					month(screening_date) >= @month
			and 				year(screening_date) >= @last_year
			group by		cinetam_demographics_desc,
							movie_category.movie_category_desc
			union
			select		top 1000			cinetam_reporting_demographics_desc,
									sum(attendance) as demo_attendance,
									movie_category.movie_category_desc
			from				cinetam_movie_history,
									movie,
									cinetam_reporting_demographics,
									cinetam_reporting_demographics_xref,
									complex,
									film_market,
									movie_category,
									target_categories
			where			cinetam_movie_history.complex_id = complex.complex_id
			and					complex.film_market_no = film_market.film_market_no
			and					cinetam_movie_history.movie_id = movie.movie_id
			and					cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id
			and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
			and					movie.movie_id = target_categories.movie_id
			and					target_categories.movie_category_code = movie_category.movie_category_code	
			and					cinetam_movie_history.country_code = @local_country_code
			and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id not in (8,13) 
			and					month(screening_date) >= @month
			and 				year(screening_date) >= @last_year
			group by		cinetam_reporting_demographics_desc,
							movie_category.movie_category_desc
			union
			select	top 1000				'AAll People Attendance' as demo_desc,
									sum(attendance) as demo_attendance,
									movie_category.movie_category_desc
			from				   movie_history,
									movie,
									complex,
									film_market,
									movie_category,
									target_categories
			where			movie_history.complex_id = complex.complex_id
			and					complex.film_market_no = film_market.film_market_no
			and					movie_history.movie_id = movie.movie_id
			and				movie.movie_id = target_categories.movie_id
			and				target_categories.movie_category_code = movie_category.movie_category_code		
			and				country = @local_country_code
			and					month(screening_date) >= @month
			and 				year(screening_date) >= @last_year
			group by		movie_category.movie_category_desc
			having sum(attendance) <> 0

		) as a
		group by cinetam_demographics_desc, movie_category_desc
		order by movie_category_desc,cinetam_demographics_desc
END
GO
