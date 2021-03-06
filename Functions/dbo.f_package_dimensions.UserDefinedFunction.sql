/****** Object:  UserDefinedFunction [dbo].[f_package_dimensions]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_dimensions]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_dimensions]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_package_dimensions] (@package_id int)
RETURNS varchar(10)
AS
BEGIN
   DECLARE  @medium_string  varchar(10),
            @three_d_type   int
            
    declare     medium_csr cursor for
    select      three_d_type    
    from        print_package_three_d,
                print_package
    where       print_package_three_d.print_package_id = print_package.print_package_id
    and         print_package.package_id = @package_id
    group by    three_d_type
    order by    three_d_type
    for         read only
            
    open medium_csr
    fetch medium_csr into @three_d_type
    while(@@fetch_status = 0)
    begin
        select  @medium_string = @medium_string + convert(varchar(1),@three_d_type)
        
        fetch medium_csr into @three_d_type
    end
    
    deallocate medium_csr
    
    return(@medium_string) 

   
END
GO
