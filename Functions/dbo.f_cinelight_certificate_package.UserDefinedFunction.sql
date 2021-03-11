USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cinelight_certificate_package]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_cinelight_certificate_package] (@certificate_item_id int)
RETURNS int
AS
BEGIN
   DECLARE  @package_id         int,
            @pack_rows          int
            
            
    select      @package_id = cinelight_spot.package_id
    from        cinelight_spot,
                cinelight_certificate_xref
    where       cinelight_certificate_xref.certificate_item_id = @certificate_item_id
    and         cinelight_spot.spot_id = cinelight_certificate_xref.spot_id
    group by    cinelight_spot.package_id
                
    select @pack_rows = @@rowcount

    if @pack_rows = 0 
        return 0
    else
        return @package_id
         
   
   error:
        return(0)
   
END
GO
