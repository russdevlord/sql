/****** Object:  UserDefinedFunction [dbo].[f_outpost_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_outpost_media_name]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[f_outpost_media_name] (@package_id int, @print_id int)
RETURNS varchar(70)
AS
BEGIN
   DECLARE  @package_code       char(1),
            @campaign_no        int,
            @print_name         varchar(50),
            @print_ext          varchar(10),
            @media_name         varchar(70),
			@print_revision		int
            
    select      @campaign_no = outpost_package.campaign_no,
                @package_code = outpost_package.package_code
    from        outpost_package
    where       outpost_package.package_id = @package_id
                
    select      @print_name = print_name,
                @print_ext = filetype,
				@print_revision = print_revision
    from        outpost_print
    where       outpost_print.print_id = @print_id
                         
    select      @media_name = convert(char(6), @campaign_no) + '_' + @package_code + '_R' + convert(varchar(2),@print_revision) + '_' + @print_name + '.' + @print_ext
            
    return(@media_name) 
         
   
   error:
        return('')
   
END

GO
