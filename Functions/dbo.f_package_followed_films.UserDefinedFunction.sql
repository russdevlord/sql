/****** Object:  UserDefinedFunction [dbo].[f_package_followed_films]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_followed_films]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_followed_films]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_package_followed_films] (@package_id int)
RETURNS varchar(800)
AS
BEGIN
   DECLARE  @followed_string    varchar(800),
            @long_name          varchar(50),
            @remove_comma      char(1)


    select  @remove_comma = 'N',
            @followed_string = ''
            
    declare     followed_csr cursor for
    select      long_name   
    from        movie, 
                movie_screening_instructions
    where       movie.movie_id = movie_screening_instructions.movie_id
    and         movie_screening_instructions.package_id = @package_id
    and         instruction_type = 1
    group by    long_name
    order by    long_name
    for         read only
            
    open followed_csr
    fetch followed_csr into @long_name
    while(@@fetch_status = 0)
    begin
        select @remove_comma = 'Y'
        select  @followed_string = @followed_string  + @long_name + ', '
        
        fetch followed_csr into @long_name
    end
    
    deallocate followed_csr

    if @remove_comma = 'Y'
        select @followed_string = left(@followed_string, len(@followed_string) - 1)
    
    return(@followed_string) 

   
END
GO
