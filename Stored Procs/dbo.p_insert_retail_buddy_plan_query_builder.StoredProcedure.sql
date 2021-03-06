/****** Object:  StoredProcedure [dbo].[p_insert_retail_buddy_plan_query_builder]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_insert_retail_buddy_plan_query_builder]
GO
/****** Object:  StoredProcedure [dbo].[p_insert_retail_buddy_plan_query_builder]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_insert_retail_buddy_plan_query_builder]
	-- Add the parameters for the stored procedure here
	@retail_buddy_plan_id int,
	
	@query_level			int,
	@and_or_flag			char(1),
	@filter_value			varchar(500),
	@condition_display		varchar(500),
	@retailer_id			int,
	@grade_id				int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into retail_buddy_query (retail_buddy_plan_id, query_level, and_or_flag, filter_value, condition_display, retailer_id, grade_id)
	values (@retail_buddy_plan_id, @query_level, @and_or_flag, @filter_value, @condition_display, @retailer_id, @grade_id)
END
GO
