/****** Object:  UserDefinedFunction [dbo].[f_movie_categories]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_movie_categories]
GO
/****** Object:  UserDefinedFunction [dbo].[f_movie_categories]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_movie_categories] (@movie_id int)
RETURNS varchar(255)
AS
BEGIN
   DECLARE  @target_categories				varchar(255),
						@target_category_desc		varchar(255),
						@row										int,
						@total_rows							int
            
    select			@total_rows = count(*)
    from			movie_category,
						target_categories
    where			movie_category.movie_category_code = target_categories.movie_category_code
    and				target_categories.movie_id = @movie_id
   
    declare		movie_csr cursor for
    select			movie_category_desc  
    from			movie_category,
						target_categories
    where			movie_category.movie_category_code = target_categories.movie_category_code
    and				target_categories.movie_id = @movie_id
    group by    movie_category_desc
    order by		movie_category_desc
    for				read only

	select @target_categories = ''
	select @row = 0
	            
    open movie_csr
    fetch movie_csr into @target_category_desc
    while(@@fetch_status = 0)
    begin
    
        select @target_categories = @target_categories + @target_category_desc
   
		select	@row = @row + 1
		
		if @row <  @total_rows
			select @target_categories = @target_categories + ', '
			
        fetch movie_csr into @target_category_desc
    end
    
    deallocate movie_csr
    
	return(@target_categories) 
   

END
GO
