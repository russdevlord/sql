/****** Object:  UserDefinedFunction [dbo].[f_cinelight_certificate_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cinelight_certificate_media_name]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cinelight_certificate_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_cinelight_certificate_media_name] (@certificate_item_id int)
RETURNS varchar(70)
AS
BEGIN
   DECLARE  @package_id         int,
            @print_id           int,
            @shell_code         char(7),
            @pack_rowcount      int
            
    select      @print_id = print_id
    from        cinelight_certificate_item
    where       cinelight_certificate_item.certificate_item_id = @certificate_item_id
    group by    cinelight_certificate_item.print_id

    select      @package_id = isnull(cinelight_spot.package_id,-1)
    from        cinelight_spot,
                cinelight_certificate_xref
    where       cinelight_certificate_xref.certificate_item_id = @certificate_item_id
    and         cinelight_spot.spot_id = cinelight_certificate_xref.spot_id
    group by    cinelight_spot.package_id
                
    select @pack_rowcount = @@rowcount                
                
    select      @shell_code = cinelight_shell_certificate_xref.shell_code
    from        cinelight_shell_certificate_xref
    where       cinelight_shell_certificate_xref.certificate_item_id = @certificate_item_id

    if @pack_rowcount = 0
        return dbo.f_cinelight_shell_media_name(@shell_code, @print_id)
    else
        return dbo.f_cinelight_media_name(@package_id, @print_id)
        
         
   
   error:
        return('')
   
END
GO
