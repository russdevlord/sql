USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_spot_redirect_backwards]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_spot_redirect_backwards] (@spot_redirect int)
RETURNS int
AS
BEGIN
   DECLARE  @spot_id        int,
            @ultimate_spot  int,
            @loop           char(1)
            
        

    select @loop = 'Y'
            
    while(@loop = 'Y')
    begin
        select  @spot_id = spot_id
        from    campaign_spot
        where   spot_redirect = @spot_redirect
        
        if @spot_id is null
        begin
            select @ultimate_spot = @spot_redirect
            select @loop = 'N'
        end
        else
        begin
            select @spot_redirect = @spot_id
            select @spot_id = null
        end            
            
   end

   return(@ultimate_spot)   
   
   error:
        return(@spot_redirect)
   
END

GO
