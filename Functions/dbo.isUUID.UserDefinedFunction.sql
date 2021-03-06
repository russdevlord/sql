/****** Object:  UserDefinedFunction [dbo].[isUUID]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[isUUID]
GO
/****** Object:  UserDefinedFunction [dbo].[isUUID]    Script Date: 12/03/2021 10:03:48 AM ******/
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
