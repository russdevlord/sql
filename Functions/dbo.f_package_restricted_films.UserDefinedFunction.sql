/****** Object:  UserDefinedFunction [dbo].[f_package_restricted_films]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_restricted_films]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_restricted_films]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_package_restricted_films] (@package_id int)
RETURNS varchar(max)
AS
BEGIN
   DECLARE  @restricted_films    varchar(max),
            @long_name          varchar(50),
            @remove_comma		char(1)


    select  @remove_comma = 'N',
            @restricted_films = ''
            
    declare			restricted_csr cursor for
    select			long_name   
    from			movie 
	inner join		movie_screening_ins_rev on movie.movie_id = movie_screening_ins_rev.movie_id
	where			movie_screening_ins_rev.package_id = @package_id
    and				instruction_type = 3
    group by		long_name
    order by		long_name
    for				read only
            
    open restricted_csr
    fetch restricted_csr into @long_name
    while(@@fetch_status = 0)
    begin
        select @remove_comma = 'Y'
        select  @restricted_films = @restricted_films  + @long_name + ', '
        
        fetch restricted_csr into @long_name
    end
    
    deallocate restricted_csr

    if @remove_comma = 'Y'
        select @restricted_films = left(@restricted_films, len(@restricted_films) - 1)
    
    return(@restricted_films) 

   
END
GO
