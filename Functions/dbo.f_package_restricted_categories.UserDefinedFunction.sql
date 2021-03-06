/****** Object:  UserDefinedFunction [dbo].[f_package_restricted_categories]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_restricted_categories]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_restricted_categories]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_package_restricted_categories] (@package_id int)
RETURNS varchar(max)
AS
BEGIN
   DECLARE  @restricted_categories    varchar(max),
            @long_name          varchar(50),
            @remove_comma		char(1)


    select  @remove_comma = 'N',
            @restricted_categories = ''
            
    declare			restricted_csr cursor for
    select			movie_category.movie_category_desc
    from			movie_category 
	inner join		campaign_category_rev on movie_category.movie_category_code = campaign_category_rev.movie_category_code
	where			campaign_category_rev.package_id = @package_id
    and				instruction_type = 3
    group by		movie_category_desc
    order by		movie_category_desc
    for				read only
            
    open restricted_csr
    fetch restricted_csr into @long_name
    while(@@fetch_status = 0)
    begin
        select @remove_comma = 'Y'
        select  @restricted_categories = @restricted_categories  + @long_name + ', '
        
        fetch restricted_csr into @long_name
    end
    
    deallocate restricted_csr

    if @remove_comma = 'Y'
        select @restricted_categories = left(@restricted_categories, len(@restricted_categories) - 1)
    
    return(@restricted_categories) 

   
END
GO
