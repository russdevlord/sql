USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_mediums]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_package_mediums] (@package_id int)
RETURNS varchar(10)
AS
BEGIN
   DECLARE  @medium_string  varchar(10),
            @print_medium   char(1)
            
    declare     medium_csr cursor for
    select      print_medium    
    from        print_package_medium,
                print_package
    where       print_package_medium.print_package_id = print_package.print_package_id
    and         print_package.package_id = @package_id
    group by    print_medium
    order by    print_medium
    for         read only
            
    open medium_csr
    fetch medium_csr into @print_medium
    while(@@fetch_status = 0)
    begin
        select  @medium_string = @medium_string + @print_medium
        
        fetch medium_csr into @print_medium
    end
    
    deallocate medium_csr
    
    return(@medium_string) 

   
END
GO
