USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_package_burst_dates]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_outpost_package_burst_dates] (@package_id int)
RETURNS varchar(800)
AS
begin
	DECLARE  @followed_string    varchar(800),
            @start_date		 datetime,
            @end_date		 datetime,
            @remove_comma      char(1),
            @count			 int
            
    set @count = 1    


    select  @remove_comma = 'N',
            @followed_string = ''
            
    declare     followed_csr cursor for
    select      start_date, end_date   
    from        outpost_package_burst
    where       package_id = @package_id
    order by	start_date
    for         read only
            
    open followed_csr
    fetch followed_csr into @start_date, @end_date
    while(@@fetch_status = 0)
    begin
        select @remove_comma = 'Y'
        select  @followed_string = @followed_string  + CONVERT(varchar(3), @count) + ') ' + convert(varchar(11), @start_date, 106) + ' - ' + convert(varchar(11), @end_date, 106)  + '     '
        
        fetch followed_csr into @start_date, @end_date
        
        set @count = @count + 1
    end
    
    deallocate followed_csr

    if @remove_comma = 'Y'
        select @followed_string = left(@followed_string, len(@followed_string) - 1)
  
  return(@followed_string) 

   
END


GO
