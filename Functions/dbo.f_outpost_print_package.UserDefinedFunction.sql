USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_print_package]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[f_outpost_print_package] (@certificate_item_id int, @print_id int)
RETURNS int
AS
BEGIN
   DECLARE  @package_id         int
                
   
    select    @package_id = outpost_print_package.print_package_id
    from        outpost_spot,
                outpost_certificate_xref ,
		outpost_print_package
    where       outpost_certificate_xref.certificate_item_id = @certificate_item_id
	and outpost_print_package.print_id = @print_id
	and outpost_print_package.package_id = outpost_spot.package_id
    and         outpost_spot.spot_id = outpost_certificate_xref.spot_id
    group by    outpost_print_package.print_package_id

         
    return @package_id
         
   
   error:
        return(0)
   
END
GO
