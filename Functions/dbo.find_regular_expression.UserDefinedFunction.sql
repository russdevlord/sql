/****** Object:  UserDefinedFunction [dbo].[find_regular_expression]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[find_regular_expression]
GO
/****** Object:  UserDefinedFunction [dbo].[find_regular_expression]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[find_regular_expression]
    (
        @source varchar(5000),
        @regexp varchar(1000),
        @ignorecase bit = 0
    )
RETURNS bit
AS
    BEGIN
        DECLARE @hr integer
        DECLARE @objRegExp integer
        DECLARE @objMatches integer
        DECLARE @objMatch integer
        DECLARE @count integer
        DECLARE @results bit
        
        EXEC @hr = sp_OACreate 'VBScript.RegExp', @objRegExp OUTPUT
        IF @hr <> 0 BEGIN
            SET @results = 0
            RETURN @results
        END
        EXEC @hr = sp_OASetProperty @objRegExp, 'Pattern', @regexp
        IF @hr <> 0 BEGIN
            SET @results = 0
            RETURN @results
        END
        EXEC @hr = sp_OASetProperty @objRegExp, 'Global', false
        IF @hr <> 0 BEGIN
            SET @results = 0
            RETURN @results
        END
        EXEC @hr = sp_OASetProperty @objRegExp, 'IgnoreCase', @ignorecase
        IF @hr <> 0 BEGIN
            SET @results = 0
            RETURN @results
        END    
        EXEC @hr = sp_OAMethod @objRegExp, 'Test', @results OUTPUT, @source
        IF @hr <> 0 BEGIN
            SET @results = 0
            RETURN @results
        END
        EXEC @hr = sp_OADestroy @objRegExp
        IF @hr <> 0 BEGIN
            SET @results = 0
            RETURN @results
        END
    RETURN @results
    END
    
GO
