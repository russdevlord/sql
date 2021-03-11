USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[isUUID]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[isUUID] (@uuid varchar(35))  
RETURNS bit AS  
BEGIN 

DECLARE @uuidRegex varchar(50)
SET @uuidRegex = '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{16}$'

RETURN dbo.find_regular_expression(@uuid,@uuidRegex ,0)

END

GO
