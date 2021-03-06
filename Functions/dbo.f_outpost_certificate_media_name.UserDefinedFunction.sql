/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_outpost_certificate_media_name]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_outpost_certificate_media_name] (@certificate_item_id int)
RETURNS varchar(70)
AS
BEGIN
   DECLARE  @package_id         int,
            @print_id           int,
            @shell_code         char(7)
            
    select      @print_id = print_id
    from        outpost_certificate_item
    where       outpost_certificate_item.certificate_item_id = @certificate_item_id
    group by    outpost_certificate_item.print_id

    select      @package_id = outpost_spot.package_id
    from        outpost_spot,
                outpost_certificate_xref
    where       outpost_certificate_xref.certificate_item_id = @certificate_item_id
    and         outpost_spot.spot_id = outpost_certificate_xref.spot_id
    group by    outpost_spot.package_id
                
    select      @shell_code = outpost_shell_certificate_xref.shell_code
    from        outpost_shell_certificate_xref
    where       outpost_shell_certificate_xref.certificate_item_id = @certificate_item_id

    if isnull(@package_id, 0) = 0
        return dbo.f_outpost_shell_media_name(@shell_code, @print_id)
    else
        return dbo.f_outpost_media_name(@package_id, @print_id)
        
         
   
   error:
        return('')
   
END
GO
