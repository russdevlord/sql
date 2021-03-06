/****** Object:  StoredProcedure [dbo].[p_cinetam_process_data_validation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_process_data_validation]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_process_data_validation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_cinetam_process_data_validation]
	
		@country_code		char,
		@screening_date		datetime,
		@exhibitor_id		int
		
as		
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @prev_screening_date	datetime
	
	select @prev_screening_date = dbo.f_prev_attendance_screening_date(@screening_date)


    --*************** YOY **********************
    
    -- attendance
	select 'Hoyts Attendance YoY Variance' as 'type'
		   ,((Select convert(numeric(20,4), sum(attendance)) as attendance 
			 from movie_history 
			 where @screening_date = screening_date
			 and country = @country_code 
			 and complex_id in (select complex_id 
								from complex 
								where exhibitor_id = @exhibitor_id)) / (Select convert(numeric(20,4), sum(attendance)) as attendance 
	from movie_history 
	where @prev_screening_date = screening_date
	and country = @country_code 
	and complex_id in (select complex_id 
					   from complex where exhibitor_id = @exhibitor_id))) as 'value'
	union
	
	-- loyalty
	select 'Hoyts Loyalty YoY Variance' as 'type'
			,((Select convert(numeric(20,4), sum(isnull(child_tickets,0) + isnull(adult_tickets,0))) as tickets 
			 from movio_data 
			 where @screening_date = screening_date
			 and country_code = @country_code ) / (Select convert(numeric(20,4), sum(isnull(child_tickets,0) + isnull(adult_tickets,0))) as tickets 
	from movio_data 
	where @prev_screening_date = screening_date
	and country_code = @country_code )) as 'value'

	
	union
	
	--***************WOW **********************
	
	-- attendance
	select 'Hoyts Attendance WoW Variance' as 'type'
			,((Select convert(numeric(20,4), sum(attendance)) as attendance 
			 from movie_history 
			 where @screening_date = screening_date
			 and country = @country_code 
			 and complex_id in (select complex_id 
								from complex where exhibitor_id = @exhibitor_id)) / (Select convert(numeric(20,4), sum(attendance)) as attendance 
	from movie_history 
	where dateadd(wk, -1, @screening_date) = screening_date
	and country = @country_code 
	and complex_id in (select complex_id 
					   from complex where exhibitor_id = @exhibitor_id))) as 'value'
					   	
	union
	
	-- loyalty
	select 'Hoyts Loyalty WoW Variance' as 'type'
			,((Select convert(numeric(20,4), sum(isnull(child_tickets,0) + isnull(adult_tickets,0))) as tickets 
			 from movio_data 
			 where @screening_date = screening_date
			 and country_code = @country_code ) / (Select convert(numeric(20,4), sum(isnull(child_tickets,0) + isnull(adult_tickets,0))) as tickets 
	from movio_data 
	where dateadd(wk, -1, @screening_date) = screening_date
	and country_code = @country_code )) as 'value'


END
GO
