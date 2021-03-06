/****** Object:  StoredProcedure [dbo].[p_appeon_user_login]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_appeon_user_login]
GO
/****** Object:  StoredProcedure [dbo].[p_appeon_user_login]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[p_appeon_user_login]
	@user_name		varchar(50),
	@password		varchar(50),
	@employee_id	int OUTPUT,
	@country_code	varchar(1) OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

	set @employee_id = null
	set @country_code = null

	select @employee_id = e.employee_id, @country_code = s.country_code
	from employee as e
	inner join branch as b on b.branch_code = e.branch_code
	inner join state as s on s.state_code = b.state_code
	where [login_id] = @user_name
	and employee_status = 'A'


/* -- previous version code. kept here while in acceptance
	set @employee_id = (select employee_id 
						from employee 
						where [login_id] = @user_name
						and employee_status = 'A')
					*/	
						
						
	
END
GO
