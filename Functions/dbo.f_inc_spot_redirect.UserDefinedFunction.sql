USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_inc_spot_redirect]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_inc_spot_redirect] (@spot_id int)
RETURNS int
AS
BEGIN
   DECLARE  @spot_redirect  int,
            @ultimate_spot  int,
            @loop           char(1)
            
        

    select @loop = 'Y'
            
    while(@loop = 'Y')
    begin
        select  @spot_redirect = spot_redirect
        from    inclusion_spot
        where   spot_id = @spot_id
        
        if @spot_redirect is null
        begin
            select @ultimate_spot = @spot_id
            select @loop = 'N'
        end
        else
        begin
            select @spot_id = @spot_redirect        
        end            
            
   end

   return(@ultimate_spot)   
   
   error:
        return(@spot_id)
   
END

GO
