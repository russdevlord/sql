/****** Object:  StoredProcedure [dbo].[p_insert_new_client_prospect_question_xref]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_insert_new_client_prospect_question_xref]
GO
/****** Object:  StoredProcedure [dbo].[p_insert_new_client_prospect_question_xref]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_insert_new_client_prospect_question_xref]

		@client_prospect_id  int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
    insert into client_prospect_question_xref
    select @client_prospect_id, 
    client_prospect_question_id,
    'N'
    from client_prospect_question
    
END
GO
