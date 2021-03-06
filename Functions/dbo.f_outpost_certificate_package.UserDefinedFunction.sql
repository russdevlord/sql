/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_package]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_outpost_certificate_package]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_package]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_outpost_certificate_package] (@certificate_item_id int)
RETURNS int
AS
BEGIN
   DECLARE  @package_id         int
            
            
    select      @package_id = outpost_spot.package_id
    from        outpost_spot,
                outpost_certificate_xref
    where       outpost_certificate_xref.certificate_item_id = @certificate_item_id
    and         outpost_spot.spot_id = outpost_certificate_xref.spot_id
    group by    outpost_spot.package_id
                
            
    return @package_id
         
   
   error:
        return(0)
   
END
GO
