/****** Object:  UserDefinedFunction [dbo].[f_op_spot_redirect]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_op_spot_redirect]
GO
/****** Object:  UserDefinedFunction [dbo].[f_op_spot_redirect]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_op_spot_redirect] (@spot_id int)
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
        from    outpost_spot
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
