/****** Object:  StoredProcedure [dbo].[p_appeon_get_business_unit_id]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_appeon_get_business_unit_id]
GO
/****** Object:  StoredProcedure [dbo].[p_appeon_get_business_unit_id]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[p_appeon_get_business_unit_id]

		@user_id int,
		@rep_id	int output,
		@business_unit_id int output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	set @rep_id = null
	set @business_unit_id = null
   
	select @business_unit_id = (case when sr.business_unit_id is null then 2 else sr.business_unit_id end)
	,@rep_id = sr.rep_id
	from employee as e
	left outer join sales_rep as sr on e.rep_id = sr.rep_id and sr.status = 'A'
	where e.employee_status = 'A'
	and e.employee_id = @user_id
	
END
GO
