/****** Object:  StoredProcedure [dbo].[p_insert_movie_history_complex_by_screen]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_insert_movie_history_complex_by_screen]
GO
/****** Object:  StoredProcedure [dbo].[p_insert_movie_history_complex_by_screen]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_insert_movie_history_complex_by_screen]
	
		@screening_date datetime 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	
	declare			@error			int,
					@rowcount		int
					
	select @rowcount = count(*)					
	from movie_history
	where screening_date = @screening_date
	and movie_id = 102
	
	if @rowcount > 0 
		return 0

    -- Insert statements for procedure here
	
	insert into movie_history(movie_id,complex_id,screening_date,occurence,altered,advertising_open
								,source,start_date,premium_cinema,show_category,certificate_group
								,print_medium,three_d_type,movie_print_medium,confirmed,sessions_scheduled
								,sessions_held,attendance,attendance_type,country,status)
	select 102
	,cssx.complex_id
	,@screening_date
	,c.cinema_no
	,'N'
	,'S'
	,'M'
	,null
	,'N'
	,'U'
	,null
	,'D'
	,1
	,'D'
	,null
	,0
	,null
	,null
	,null
	,s.country_code
	,'C'
	from complex_screen_scheduling_xref as cssx
	inner join cinema as c on c.complex_id = cssx.complex_id and c.active_flag = 'Y'
	inner join complex as com on com.complex_id = cssx.complex_id
	inner join state as s on s.state_code = com.state_code
	order by cssx.complex_id,c.cinema_no
	
END
GO
