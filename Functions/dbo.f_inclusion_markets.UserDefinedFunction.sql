/****** Object:  UserDefinedFunction [dbo].[f_inclusion_markets]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_inclusion_markets]
GO
/****** Object:  UserDefinedFunction [dbo].[f_inclusion_markets]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_inclusion_markets] (@inclusion_id int)
RETURNS varchar(max)
AS
BEGIN
   DECLARE  @film_markets				varchar(max),
			@film_market_name			varchar(max),
			@row						int,
			@total_rows					int
            
    select			@total_rows = count(distinct film_market_no)
    from			inclusion_cinetam_settings
	inner join		complex on inclusion_cinetam_settings.complex_id = complex.complex_id
    where			inclusion_cinetam_settings.inclusion_id = @inclusion_id
   
    declare			market_csr cursor for
    select			film_market_desc
    from			inclusion_cinetam_settings
	inner join		complex on inclusion_cinetam_settings.complex_id = complex.complex_id
	inner join		film_market on complex.film_market_no = film_market.film_market_no
    where			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	group by		film_market_desc,
					film_market.film_market_no
	order by		film_market.film_market_no
    for				read only

	select @film_markets = ''
	select @row = 0
	            
    open market_csr
    fetch market_csr into @film_market_name
    while(@@fetch_status = 0)
    begin
    
        select @film_markets = @film_markets + @film_market_name
   
		select	@row = @row + 1
		
		if @row <  @total_rows
			select @film_markets = @film_markets + ', '
			
        fetch market_csr into @film_market_name
    end
    
    deallocate market_csr
    
	return(@film_markets) 
   

END
GO
