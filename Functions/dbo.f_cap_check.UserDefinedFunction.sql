USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cap_check]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_cap_check] ( @cinema_agreement_id int, @complex_id int, @revenue_source char(1))
RETURNS CHAR(1)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @return CHAR(1)
	IF (	SELECT	COUNT(*)
			FROM	cinema_agreement_policy
			WHERE	cinema_agreement_id = @cinema_agreement_id
			and		complex_id = @complex_id
			and		revenue_source = 'P' ) > 0
		BEGIN
			SELECT @return = 'P'
		END
	ELSE
		BEGIN
			SELECT @return = @revenue_source
		END
	-- Return the result of the function
	RETURN @return
END

GO
