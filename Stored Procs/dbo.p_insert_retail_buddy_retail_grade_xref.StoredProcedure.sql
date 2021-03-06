/****** Object:  StoredProcedure [dbo].[p_insert_retail_buddy_retail_grade_xref]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_insert_retail_buddy_retail_grade_xref]
GO
/****** Object:  StoredProcedure [dbo].[p_insert_retail_buddy_retail_grade_xref]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_insert_retail_buddy_retail_grade_xref]
	
	@retail_buddy_plan_id				int
	,@outpost_retailer_group_id			int
	,@outpost_retailer_category_id		int
	,@outpost_retailer_id				int
	,@outpost_retailer_grade_id			int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	insert into retail_buddy_retailer_grade_xref(retail_buddy_plan_id, outpost_retailer_group_id, outpost_retailer_category_id, outpost_retailer_id, outpost_retailer_grade_id)
	values(@retail_buddy_plan_id, @outpost_retailer_group_id, @outpost_retailer_category_id, @outpost_retailer_id, @outpost_retailer_grade_id)
END
GO
