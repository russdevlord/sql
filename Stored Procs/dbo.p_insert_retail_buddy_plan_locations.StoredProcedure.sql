/****** Object:  StoredProcedure [dbo].[p_insert_retail_buddy_plan_locations]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_insert_retail_buddy_plan_locations]
GO
/****** Object:  StoredProcedure [dbo].[p_insert_retail_buddy_plan_locations]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_insert_retail_buddy_plan_locations]
	-- Add the parameters for the stored procedure here
	@retail_buddy_plan_id	int,
	@outpost_panel_id		int,
	@player_name			varchar(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	insert into retail_buddy_panel_xref values(@retail_buddy_plan_id, @outpost_panel_id, @player_name)
END
GO
