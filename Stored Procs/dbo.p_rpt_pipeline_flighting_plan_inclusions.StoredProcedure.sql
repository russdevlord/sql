/****** Object:  StoredProcedure [dbo].[p_rpt_pipeline_flighting_plan_inclusions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_pipeline_flighting_plan_inclusions]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_pipeline_flighting_plan_inclusions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rpt_pipeline_flighting_plan_inclusions]

	@client_prospect_id int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   select client_prospect_id
		   ,cpi.client_prosect_inclusion_type_id
		   ,cpit.client_prosect_inclusion_type_desc	   
		   ,total_value
		   ,total_charge
		   ,commissionable
		   ,takeout
	from client_prospect_inclusion as cpi
	inner join client_prospect_inclusion_type as cpit on cpit.client_prosect_inclusion_type_id = cpi.client_prosect_inclusion_type_id
	where cpi.client_prospect_id = @client_prospect_id
  
END
GO
