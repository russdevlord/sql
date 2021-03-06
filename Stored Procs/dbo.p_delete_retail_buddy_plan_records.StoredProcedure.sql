/****** Object:  StoredProcedure [dbo].[p_delete_retail_buddy_plan_records]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_retail_buddy_plan_records]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_retail_buddy_plan_records]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_delete_retail_buddy_plan_records]
	-- Add the parameters for the stored procedure here
	@retail_buddy_plan_id int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	delete from retail_buddy_panel_xref where retail_buddy_plan_id = @retail_buddy_plan_id 
	
	delete from retail_buddy_query where retail_buddy_plan_id = @retail_buddy_plan_id 
	
	delete from retail_buddy_retailer_grade_xref where retail_buddy_plan_id = @retail_buddy_plan_id 
END
GO
