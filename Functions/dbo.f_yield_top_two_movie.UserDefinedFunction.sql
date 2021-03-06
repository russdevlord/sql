/****** Object:  UserDefinedFunction [dbo].[f_yield_top_two_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_yield_top_two_movie]
GO
/****** Object:  UserDefinedFunction [dbo].[f_yield_top_two_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_yield_top_two_movie] (@exhibitor_id int, @screening_date datetime, @rank_preference char(1))
RETURNS varchar(255)
AS
BEGIN
   DECLARE		@movie_name			varchar(50),
				@movie_return		varchar(110),
				@row				int
            
    declare		movie_csr cursor for
	select		movie_name
	from		v_complex_yield_ffmm 
	where		exhibitor_id = @exhibitor_id 
	and			screening_date = @screening_date
	and			(
				(complex_movie_rank <= 2 and @rank_preference = 'C') 
	or			(exhibitor_movie_rank <= 2 and @rank_preference = 'E')
	or			(country_movie_rank <= 2 and @rank_preference = 'Y')
				)
	group by	movie_name,
				case 
					when @rank_preference = 'C' then complex_movie_rank
					when @rank_preference = 'E' then exhibitor_movie_rank
					when @rank_preference = 'Y' then country_movie_rank
					else country_movie_rank
				end
	order by	case 
					when @rank_preference = 'C' then complex_movie_rank
					when @rank_preference = 'E' then exhibitor_movie_rank
					when @rank_preference = 'Y' then country_movie_rank
					else country_movie_rank
				end
    for				read only

	select @movie_return = ''
	select @row = 0
	            
    open movie_csr
    fetch movie_csr into @movie_name
    while(@@fetch_status = 0)
    begin
    
        select @movie_return = @movie_return + @movie_name
   
		select	@row = @row + 1
		
		if @row = 1
			select @movie_return = @movie_return + ', '
			
        fetch movie_csr into @movie_name
    end
    
    deallocate movie_csr
    
	return(@movie_return) 
   

END


GO
