USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_spot_redirect_cplx]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_spot_redirect_cplx] (@spot_id int)
RETURNS int
AS
BEGIN
   DECLARE  @spot_redirect  int,
            @ultimate_spot  int,
            @loop           char(1),
            @complex_id     int
            
        

    select @loop = 'Y'
            
    while(@loop = 'Y')
    begin
        select  @spot_redirect = spot_redirect
        from    campaign_spot
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
   
   select @complex_id = complex_id from campaign_spot where spot_id = @ultimate_spot

   return(@complex_id)   
   
   error:
        return(null)
   
END

GO
