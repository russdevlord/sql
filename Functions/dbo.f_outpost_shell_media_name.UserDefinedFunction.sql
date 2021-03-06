/****** Object:  UserDefinedFunction [dbo].[f_outpost_shell_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_outpost_shell_media_name]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_shell_media_name]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE FUNCTION [dbo].[f_outpost_shell_media_name] (@shell_code char(7), @print_id int)
RETURNS varchar(70)
AS
BEGIN
   DECLARE  @shell_desc         varchar(50),
            @print_name         varchar(50),
            @print_ext          varchar(10),
            @media_name         varchar(70),
			@print_revision		int
            
    select      @shell_desc = outpost_shell.shell_desc
    from        outpost_shell
    where       outpost_shell.shell_code = @shell_code
                
    select      @print_name = print_name,
                @print_ext = filetype,
				@print_revision = print_revision
    from        outpost_print
    where       outpost_print.print_id = @print_id
                         
    select      @media_name = @shell_code + '_R' + convert(varchar(2),@print_revision) + '_' + @print_name + '.' + @print_ext
            
    return(@media_name) 
         
   
   error:
        return('')
   
END

GO
